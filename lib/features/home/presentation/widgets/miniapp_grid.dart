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
      loading: () => const _MiniAppSkeletonGrid(),
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

class _MiniAppSkeletonGrid extends StatefulWidget {
  const _MiniAppSkeletonGrid();

  @override
  State<_MiniAppSkeletonGrid> createState() => _MiniAppSkeletonGridState();
}

class _MiniAppSkeletonGridState extends State<_MiniAppSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4, // Show 4 skeletons for horizontal view
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: const _MiniAppSkeletonItem(),
          );
        },
      ),
    );
  }
}

class _MiniAppSkeletonItem extends StatelessWidget {
  const _MiniAppSkeletonItem();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
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
