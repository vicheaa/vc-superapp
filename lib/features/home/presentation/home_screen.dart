import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vc_super_app/core/widgets/button.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/require_permission.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/home_repository.dart';
import '../domain/models/post.dart';
import 'home_view_model.dart';
import '../../miniapps/domain/miniapp_repository.dart';
import '../../miniapps/domain/models/miniapp_manifest.dart';

final miniAppsProvider = FutureProvider.autoDispose<List<MiniAppManifest>>((ref) {
  final repo = getIt<MiniAppRepository>();
  return repo.getAvailableMiniApps();
});

/// Riverpod provider for [HomeViewModel] state.
///
/// Uses [AsyncNotifierProvider] for Riverpod v3 compatibility.
final homeViewModelProvider =
    AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

/// State class for the home screen.
class HomeState {
  const HomeState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.errorMessage,
  });

  final List<Post> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  HomeState copyWith({
    List<Post>? items,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod AsyncNotifier for the home screen.
class HomeNotifier extends AsyncNotifier<HomeState> {
  late final HomeRepository _repository;

  static const _pageSize = 20;

  @override
  Future<HomeState> build() async {
    _repository = getIt<HomeRepository>();
    return _loadPage(1);
  }

  Future<HomeState> _loadPage(int page) async {
    final posts = await _repository.getPosts(page: page, limit: _pageSize);
    return HomeState(
      items: posts,
      currentPage: page,
      hasMore: posts.length >= _pageSize,
    );
  }

  /// Load next page of posts (infinite scroll).
  Future<void> loadMore() async {
    final currentState = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final newPosts = await _repository.getPosts(
        page: nextPage,
        limit: _pageSize,
      );

      state = AsyncData(currentState.copyWith(
        items: [...currentState.items, ...newPosts],
        currentPage: nextPage,
        hasMore: newPosts.length >= _pageSize,
        isLoadingMore: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncData(currentState.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more items.',
      ));
    }
  }

  /// Pull-to-refresh: reload from page 1.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }
}

/// Home screen demonstrating the full architecture:
/// - AsyncNotifier with loading/error states
/// - Paginated list with load-more
/// - Pull-to-refresh
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pyro Tyson'),
        actions: [
          RequireAdmin(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.language),
                  tooltip: 'Flutter.dev',
                  onPressed: () => context.push('/webview', extra: 'https://flutter.dev'),
                ),
                IconButton(
                   icon: const Icon(Icons.apps),
                   tooltip: 'Super App Test',
                   onPressed: () => context.push('/webview'), // no url loads local asset
                ),

                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: ref.watch(miniAppsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: miniapps.length,
              itemBuilder: (context, index) {
                final app = miniapps[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        app.iconUrl, 
                        width: 54, 
                        height: 54, 
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 54),
                      ),
                    ),
                    title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Version ${app.version}', style: const TextStyle(fontSize: 13)),
                    ),
                    trailing: AppButton.filled(
                      text: 'Open',
                      width: 80,
                      height: 36,
                      borderRadius: 12,
                      onPressed: () => _openMiniApp(context, ref, app),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMiniApp(
    BuildContext context,
    WidgetRef ref,
    MiniAppManifest app,
  ) async {
    final repo = getIt<MiniAppRepository>();

    // Check if already downloaded and cached
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

    // Show a loading dialog while downloading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text('Installing ${app.name}...')),
          ],
        ),
      ),
    );

    try {
      final localPath = await repo.downloadAndInstallApp(app);

      // Close the loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Navigate to the WebView with the local file path
      if (context.mounted) {
        context.push('/webview', extra: {
          'localHtmlFilePath': localPath,
          'title': app.name,
        });
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to install ${app.name}: $e')),
        );
      }
    }
  }
}