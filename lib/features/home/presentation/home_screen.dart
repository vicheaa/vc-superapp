import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../domain/home_repository.dart';
import '../domain/models/post.dart';
import 'home_view_model.dart';

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
    final asyncState = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pyro Tyson'),
        actions: [
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
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Native Shop',
            onPressed: () => context.push('/shop'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(homeViewModelProvider.notifier).refresh(),
        ),
        data: (homeState) => _buildData(context, ref, homeState),
      ),
    );
  }

  Widget _buildData(BuildContext context, WidgetRef ref, HomeState homeState) {
    if (homeState.items.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
      child: _PostList(
        items: homeState.items,
        isLoadingMore: homeState.isLoadingMore,
        hasMore: homeState.hasMore,
        onLoadMore: () => ref.read(homeViewModelProvider.notifier).loadMore(),
      ),
    );
  }
}

// ──── Post List ────

class _PostList extends StatelessWidget {
  const _PostList({
    required this.items,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<Post> items;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            !isLoadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PostCard(post: items[index]);
        },
      ),
    );
  }
}

// ──── Post Card ────

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──── Empty View ────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

// ──── Error View ────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
