import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/custom_progress_indicator.dart';
import '../../../miniapps/domain/models/miniapp_manifest.dart';
import '../../../miniapps/domain/miniapp_repository.dart';
import '../home_provider.dart';
import 'miniapp_grid_card.dart';

class MiniAppGrid extends ConsumerWidget {
  const MiniAppGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniAppsAsync = ref.watch(miniAppsProvider);

    return miniAppsAsync.when(
      loading: () => const Center(child: AppCircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load apps: $error'),
            TextButton(
              onPressed: () => ref.refresh(miniAppsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (miniapps) {
        if (miniapps.isEmpty) {
          return const Center(child: Text('No Mini Apps available.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(miniAppsProvider.future),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: miniapps.length,
            itemBuilder: (context, index) {
              return MiniAppGridCard(
                app: miniapps[index],
                onTap: () => _openMiniApp(context, ref, miniapps[index]),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openMiniApp(
    BuildContext context,
    WidgetRef ref,
    MiniAppManifest app,
  ) async {
    final repo = getIt<MiniAppRepository>();

    final isInstalled = await repo.isAppDownloaded(app);
    if (isInstalled) {
      final path = await repo.getInstalledAppPath(app.id);
      if (path != null && context.mounted) {
        context.push('/webview', extra: {
          'localHtmlFilePath': path,
          'title': app.name,
        });
        return;
      }
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const AppCircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text('Installing ${app.name}...')),
          ],
        ),
      ),
    );

    try {
      final localPath = await repo.downloadAndInstallApp(app);

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (context.mounted) {
        context.push('/webview', extra: {
          'localHtmlFilePath': localPath,
          'title': app.name,
        });
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (context.mounted) {
        String errorMessage = e.toString();
        
        if (errorMessage.contains('Connection closed while receiving data')) {
          errorMessage = 'Download interrupted. Try again or check your server connection.';
        } else if (errorMessage.contains('Connection timeout')) {
          errorMessage = 'Download timed out. Ensure the server is reachable.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${app.name}: $errorMessage'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _openMiniApp(context, ref, app),
            ),
          ),
        );
      }
    }
  }
}
