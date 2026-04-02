import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/logger.dart';
import '../domain/miniapp_repository.dart';
import '../domain/models/miniapp_manifest.dart';

class MiniAppRepositoryImpl implements MiniAppRepository {
  MiniAppRepositoryImpl({required this.dio});

  final Dio dio;



  @override
  Future<List<MiniAppManifest>> getAvailableMiniApps() async {
    try {
      final response = await dio.get('http://10.0.3.165:8000/api/v1/miniapps');
      final data = response.data['data']['miniApps'] as List;
      return data
          .map((e) => MiniAppManifest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch miniapps', error: e, tag: 'OTA');
      rethrow;
    }
  }

  /// Returns the permanent directory for a given mini-app on this device.
  Future<Directory> _getMiniAppDirectory(String appId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final miniAppDir = Directory('${appDocDir.path}/miniapps/$appId');
    if (!await miniAppDir.exists()) {
      await miniAppDir.create(recursive: true);
    }
    return miniAppDir;
  }

  @override
  Future<bool> isAppDownloaded(MiniAppManifest app) async {
    final dir = await _getMiniAppDirectory(app.id);
    final versionFile = File('${dir.path}/version.txt');

    if (!await versionFile.exists()) return false;

    final installedVersion = await versionFile.readAsString();
    if (installedVersion.trim() != app.version) return false;

    final indexPath = await _findIndexHtml(dir);
    return indexPath != null;
  }

  @override
  Future<String> downloadAndInstallApp(
    MiniAppManifest app, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await _getMiniAppDirectory(app.id);
      final versionPath = '${dir.path}/version.txt';

      AppLogger.info(
        'Starting OTA download for ${app.id} v${app.version}',
        tag: 'OTA',
      );

      // ── Step 1: Download the .zip to a temporary path ──
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/${app.id}_bundle.zip';

      AppLogger.info('Downloading from: ${app.downloadUrl}', tag: 'OTA');
      AppLogger.info('Saving ZIP to: $zipPath', tag: 'OTA');

      // Download with retry logic.
      // Laravel's `php artisan serve` (PHP's built-in server) is
      // single-threaded and intermittently drops connections.
      List<int>? downloadedBytes;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          AppLogger.info('Download attempt $attempt/3...', tag: 'OTA');

          final freshDio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(minutes: 5),
          ));

          final response = await freshDio.get<List<int>>(
            app.downloadUrl,
            options: Options(
              responseType: ResponseType.bytes,
              headers: {
                'Connection': 'close',
                'Accept': '*/*',
              },
            ),
          );

          downloadedBytes = response.data;
          AppLogger.info(
            'Download complete. Received ${downloadedBytes?.length ?? 0} bytes',
            tag: 'OTA',
          );
          break; // Success — exit retry loop
        } catch (e) {
          AppLogger.error('Attempt $attempt failed: $e', tag: 'OTA');
          if (attempt == 3) rethrow;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      await File(zipPath).writeAsBytes(downloadedBytes!);
      if (onProgress != null) onProgress(0.8);

      // Verify the downloaded file exists and has content
      final zipFile = File(zipPath);
      final zipSize = await zipFile.length();
      AppLogger.info('Downloaded ZIP size: $zipSize bytes', tag: 'OTA');

      if (zipSize == 0) {
        throw Exception('Downloaded ZIP file is empty');
      }

      // ── Step 2: Clear old installation ──
      if (await dir.exists()) {
        final existingFiles = dir.listSync();
        for (final entity in existingFiles) {
          await entity.delete(recursive: true);
        }
      }
      await dir.create(recursive: true);

      // ── Step 3: Extract .zip into the mini-app directory ──
      AppLogger.info('Extracting ZIP to: ${dir.path}', tag: 'OTA');
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      AppLogger.info('Archive contains ${archive.length} entries', tag: 'OTA');

      for (final file in archive) {
        final filePath = '${dir.path}/${file.name}';
        if (file.isFile) {
          AppLogger.info('  Extracting file: ${file.name}', tag: 'OTA');
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      if (onProgress != null) onProgress(0.95);

      // ── Step 4: Write version marker for caching ──
      final versionFile = File(versionPath);
      await versionFile.writeAsString(app.version);

      // ── Step 5: Cleanup the temp zip file ──
      await zipFile.delete();

      if (onProgress != null) onProgress(1.0);

      // Find the index.html path
      final indexPath = await _findIndexHtml(dir);
      if (indexPath == null) {
        // List all extracted files for debugging
        final allFiles = dir.listSync(recursive: true);
        for (final f in allFiles) {
          AppLogger.info('  Found: ${f.path}', tag: 'OTA');
        }
        throw Exception('index.html not found in extracted bundle');
      }

      AppLogger.info(
        'Successfully installed ${app.id} at $indexPath',
        tag: 'OTA',
      );

      return indexPath;
    } catch (e, st) {
      AppLogger.error(
        'Failed to download miniapp ${app.id}: $e',
        error: e,
        tag: 'OTA',
      );
      debugPrint(st.toString());
      rethrow;
    }
  }

  @override
  Future<String?> getInstalledAppPath(String appId) async {
    final dir = await _getMiniAppDirectory(appId);
    return _findIndexHtml(dir);
  }

  /// Recursively searches for index.html inside the extracted directory.
  Future<String?> _findIndexHtml(Directory dir) async {
    // Check root level first
    final rootIndex = File('${dir.path}/index.html');
    if (await rootIndex.exists()) return rootIndex.path;

    // Search deeper (e.g. dist/, build/)
    if (!await dir.exists()) return null;

    final children = dir.listSync(recursive: true);
    for (final entity in children) {
      if (entity is File && entity.path.endsWith('index.html')) {
        return entity.path;
      }
    }

    return null;
  }
}

void debugPrint(String message) {
  AppLogger.info(message, tag: 'OTA_DEBUG');
}
