import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/logger.dart';
import '../domain/miniapp_repository.dart';
import '../domain/models/miniapp_manifest.dart';
import 'miniapp_api_service.dart';

class MiniAppRepositoryImpl implements MiniAppRepository {
  MiniAppRepositoryImpl({
    required MiniAppApiService apiService,
    required Dio dio,
  })  : _apiService = apiService,
        _dio = dio;

  final MiniAppApiService _apiService;
  final Dio _dio;

  @override
  Future<List<MiniAppManifest>> getAvailableMiniApps() async {
    final result = await _apiService.getAvailableMiniApps();

    return result.when(
      success: (data) => data.miniApps,
      failure: (message, statusCode) {
        AppLogger.error('Failed to fetch miniapps: $message', tag: 'OTA');
        throw Exception(message);
      },
    );
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
      final zipFile = File(zipPath);

      AppLogger.info('Downloading from: ${app.downloadUrl}', tag: 'OTA');
      AppLogger.info('Saving ZIP to: $zipPath', tag: 'OTA');

      // Download with retry logic.
      bool downloadSuccess = false;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          AppLogger.info('Download attempt $attempt/3...', tag: 'OTA');

          if (await zipFile.exists()) {
            await zipFile.delete();
          }

          if (onProgress != null) onProgress(0.1);

          // 1-second "Breathing Room" for single-threaded artisan server
          await Future.delayed(const Duration(seconds: 1));

          // Create a clean Dio instance specifically for downloads.
          final cleanDio = Dio(BaseOptions(
            connectTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 20),
          ));

          try {
            AppLogger.info('Requesting stream for ${app.id}...', tag: 'OTA');
            
            int lastLoggedMb = 0;
            final response = await cleanDio.download(
              app.downloadUrl,
              zipPath,
              onReceiveProgress: (received, total) {
                if (total != -1 && onProgress != null) {
                  onProgress((received / total) * 0.8);
                  
                  final currentMb = received ~/ (1024 * 1024);
                  if (currentMb > lastLoggedMb) {
                    lastLoggedMb = currentMb;
                    AppLogger.info('[OTA] Download progress: $currentMb / ${total ~/ (1024 * 1024)} MB', tag: 'OTA');
                  }
                }
              },
              options: Options(
                headers: {
                  'Accept': '*/*',
                  'Accept-Encoding': 'identity',
                  if (_dio.options.headers['Authorization'] != null)
                    'Authorization': _dio.options.headers['Authorization'],
                },
                followRedirects: true,
                validateStatus: (status) => status != null && status < 500,
              ),
            );

            final zipSize = await zipFile.length();
            AppLogger.info('Downloaded ZIP size: ${(zipSize / 1024 / 1024).toStringAsFixed(2)} MB', tag: 'OTA');

            if (zipSize == 0) {
              throw Exception('Server returned 0 bytes (Empty file or Access Denied)');
            }

            if (response.statusCode != 200) {
              throw Exception('Server Error: ${response.statusCode} ${response.statusMessage}');
            }
          } catch (e) {
            if (e is DioException) {
              final status = e.response?.statusCode;
              final msg = e.response?.statusMessage;
              AppLogger.error('Download Failed [$status]: $msg', tag: 'OTA');
            }
            rethrow;
          } finally {
            cleanDio.close();
          }

          AppLogger.info('Download complete.', tag: 'OTA');
          downloadSuccess = true;
          break;
        } catch (e) {
          AppLogger.error('Attempt $attempt failed: $e', tag: 'OTA');
          if (attempt == 3) rethrow;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }

      if (!downloadSuccess) {
        throw Exception('Failed to download miniapp after 3 attempts');
      }

      if (onProgress != null) onProgress(0.85);

      // ── Step 2: Clear old installation ──
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      if (onProgress != null) onProgress(0.9);

      // ── Step 3: Extract .zip into the mini-app directory (BACKGROUND THREAD) ──
      final zipFileForIsolate = File(zipPath);
      final dirPath = dir.path;

      AppLogger.info('Starting TOTAL background process (Read + Extract)...', tag: 'OTA');
      
      final result = await Isolate.run(() async {
        try {
          final bytes = zipFileForIsolate.readAsBytesSync();
          final archive = ZipDecoder().decodeBytes(bytes);
          
          String prefix = '';
          String? commonRoot;
          
          for (final file in archive) {
            final name = file.name;
            if (name.trim().isEmpty || name.startsWith('__MACOSX')) continue;
            final parts = name.split('/');
            if (parts.length == 1 && file.isFile) {
              commonRoot = null;
              break;
            }
            final currentRoot = '${parts[0]}/';
            if (commonRoot == null) {
              commonRoot = currentRoot;
            } else if (commonRoot != currentRoot) {
              commonRoot = null;
              break;
            }
          }
          prefix = commonRoot ?? '';

          for (final file in archive) {
            String relativeName = file.name;
            if (prefix.isNotEmpty && relativeName.startsWith(prefix)) {
              relativeName = relativeName.substring(prefix.length);
            }
            if (relativeName.isEmpty) continue;

            final filePath = '$dirPath/$relativeName';
            if (file.isFile) {
              final outFile = File(filePath);
              outFile.createSync(recursive: true);
              outFile.writeAsBytesSync(file.content as List<int>);
            } else {
              Directory(filePath).createSync(recursive: true);
            }
          }
          return true;
        } catch (e) {
          return false;
        }
      });

      if (!result) {
        throw Exception('Extraction failed in background thread');
      }

      if (onProgress != null) onProgress(0.95);

      // ── Step 4: Write version marker for caching ──
      final versionFile = File(versionPath);
      await versionFile.writeAsString(app.version);

      // ── Step 5: Cleanup the temp zip file ──
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      if (onProgress != null) onProgress(1.0);

      // Find the index.html path
      final indexPath = await _findIndexHtml(dir);
      if (indexPath == null) {
        throw Exception('index.html not found in extracted bundle (checked recursively)');
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
    final rootIndex = File('${dir.path}/index.html');
    if (await rootIndex.exists()) {
       AppLogger.info('Found entry point at root: ${rootIndex.path}', tag: 'OTA');
       return rootIndex.path;
    }

    if (!await dir.exists()) return null;

    final children = dir.listSync(recursive: true);
    for (final entity in children) {
      if (entity is File && entity.path.endsWith('index.html')) {
        AppLogger.info('Found entry point at: ${entity.path}', tag: 'OTA');
        return entity.path;
      }
    }

    return null;
  }
}

