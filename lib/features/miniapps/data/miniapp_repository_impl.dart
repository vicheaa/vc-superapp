import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/logger.dart';
import '../domain/miniapp_repository.dart';
import '../domain/models/miniapp_manifest.dart';

class MiniAppRepositoryImpl implements MiniAppRepository {
  MiniAppRepositoryImpl({required this.dio});

  final Dio dio;

  // Mocking the backend registry response
  final List<MiniAppManifest> _mockRegistry = [
    const MiniAppManifest(
      id: 'todo',
      name: 'Todo App',
      version: '1.2.0',
      description: 'A dynamic OTA Todo application.',
      // Using a mock asset scheme to simulate downloading a remote file without dealing with 404s
      downloadUrl: 'asset://assets/test_webapp/index.html',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3208/3208726.png',
    ),
  ];

  @override
  Future<List<MiniAppManifest>> getAvailableMiniApps() async {
    // Simulate network delay fetching from backend
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockRegistry;
  }

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
    final file = File('${dir.path}/index.html');
    final versionFile = File('${dir.path}/version.txt');

    if (!await file.exists() || !await versionFile.exists()) {
      return false;
    }

    final installedVersion = await versionFile.readAsString();
    return installedVersion == app.version;
  }

  @override
  Future<String> downloadAndInstallApp(
    MiniAppManifest app, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await _getMiniAppDirectory(app.id);
      final filePath = '${dir.path}/index.html';
      final versionPath = '${dir.path}/version.txt';

      AppLogger.info('Starting OTA download for ${app.id} v${app.version}', tag: 'OTA');

      if (app.downloadUrl.startsWith('asset://')) {
        // Simulate network download from a bundled asset
        await Future.delayed(const Duration(milliseconds: 500));
        if (onProgress != null) onProgress(0.3);
        
        final assetPath = app.downloadUrl.replaceFirst('asset://', '');
        final byteData = await rootBundle.load(assetPath);
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (onProgress != null) onProgress(0.7);

        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        
        await Future.delayed(const Duration(milliseconds: 200));
        if (onProgress != null) onProgress(1.0);
      } else {
        // Real HTTP Download
        await dio.download(
          app.downloadUrl,
          filePath,
          onReceiveProgress: (bytesReceived, totalBytes) {
            if (onProgress != null && totalBytes != -1) {
              onProgress(bytesReceived / totalBytes);
            }
          },
        );
      }

      // Write the version marker to verify future cache hits
      final versionFile = File(versionPath);
      await versionFile.writeAsString(app.version);

      AppLogger.info('Successfully installed ${app.id} at $filePath', tag: 'OTA');

      return filePath;
    } catch (e) {
      AppLogger.error('Failed to download miniapp ${app.id}', error: e, tag: 'OTA');
      rethrow;
    }
  }

  @override
  Future<String?> getInstalledAppPath(String appId) async {
    final dir = await _getMiniAppDirectory(appId);
    final file = File('${dir.path}/index.html');
    
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }
}
