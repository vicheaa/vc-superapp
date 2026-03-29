import 'models/miniapp_manifest.dart';

abstract class MiniAppRepository {
  /// Fetches the list of available mini-apps from the backend registry.
  Future<List<MiniAppManifest>> getAvailableMiniApps();

  /// Checks if a non-expired installed version exists for the [app.id] and [app.version].
  Future<bool> isAppDownloaded(MiniAppManifest app);

  /// Downloads the bundle for [app] and saves it locally.
  /// Returns the absolute path to the local `index.html` file.
  Future<String> downloadAndInstallApp(
      MiniAppManifest app, {
      Function(double progress)? onProgress,
  });

  /// Returns the path to the installed `index.html` file for [app.id].
  /// Returns null if not installed.
  Future<String?> getInstalledAppPath(String appId);
}
