import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/miniapps/domain/models/miniapp_manifest.dart';
import '../../../../features/miniapps/domain/miniapp_repository.dart';

final miniappsListProvider = FutureProvider<List<MiniAppManifest>>((ref) async {
  final repo = getIt<MiniAppRepository>();
  return repo.getAvailableMiniApps();
});

class MiniAppGrid extends ConsumerWidget {
  const MiniAppGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(miniappsListProvider);

    return appsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Error loading mini apps: $e')),
      data: (apps) {
        if (apps.isEmpty) {
           return const SizedBox.shrink();
        }
        return Container(
          height: 120, // fixed height for horizontal list or grid
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: apps.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _MiniAppItem(app: apps[index]);
            },
          ),
        );
      },
    );
  }
}

class _MiniAppItem extends StatefulWidget {
  const _MiniAppItem({required this.app});

  final MiniAppManifest app;

  @override
  State<_MiniAppItem> createState() => _MiniAppItemState();
}

class _MiniAppItemState extends State<_MiniAppItem> {
  late final MiniAppRepository _repository;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _repository = getIt<MiniAppRepository>();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await _repository.isAppDownloaded(widget.app);
    String? path;
    if (downloaded) {
      path = await _repository.getInstalledAppPath(widget.app.id);
    }
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _localPath = path;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isDownloading) return;

    if (_isDownloaded && _localPath != null) {
      context.push('/webview', extra: {'localHtmlFilePath': _localPath});
      return;
    }

    // Start download
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final path = await _repository.downloadAndInstallApp(
        widget.app,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
          _localPath = path;
        });
        context.push('/webview', extra: {'localHtmlFilePath': path});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.app.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps),
                    ),
                  ),
                ),
                if (_isDownloading)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: _downloadProgress,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_isDownloaded && !_isDownloading)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
