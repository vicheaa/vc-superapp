import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../miniapps/domain/miniapp_repository.dart';
import '../../miniapps/domain/models/miniapp_manifest.dart';

/// Provider for available mini-apps.
final miniAppsProvider = FutureProvider.autoDispose<List<MiniAppManifest>>((ref) {
  final repo = getIt<MiniAppRepository>();
  return repo.getAvailableMiniApps();
});
