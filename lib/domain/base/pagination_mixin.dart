import '../../core/constants/api_constants.dart';
import 'base_view_model.dart';

/// Mixin that adds pagination support to a [BaseViewModel].
///
/// Subclasses must implement [fetchPage] to load data for a given page.
///
/// Usage:
/// ```dart
/// class PostsViewModel extends BaseViewModel with PaginationMixin<Post> {
///   @override
///   Future<List<Post>> fetchPage(int page) async {
///     return await repository.getPosts(page: page);
///   }
/// }
/// ```
mixin PaginationMixin<T> on BaseViewModel {
  final List<T> _items = [];
  List<T> get items => List.unmodifiable(_items);

  int _currentPage = 1;
  int get currentPage => _currentPage;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int get pageSize => ApiConstants.defaultPageSize;

  /// Subclasses must implement this to fetch data for a specific page.
  Future<List<T>> fetchPage(int page);

  /// Load the initial page of data. Resets all pagination state.
  Future<void> loadInitialPage() async {
    _currentPage = 1;
    _hasMore = true;
    _items.clear();

    await safeCall(() async {
      final newItems = await fetchPage(_currentPage);
      _items.addAll(newItems);
      _hasMore = newItems.length >= pageSize;
      notifyListeners();
    });
  }

  /// Load the next page of data. No-op if already loading or no more data.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newItems = await fetchPage(nextPage);

      _items.addAll(newItems);
      _currentPage = nextPage;
      _hasMore = newItems.length >= pageSize;
    } catch (e) {
      // Error is handled by safeCall in subclass if needed
      setError('Failed to load more items.');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh: reload from page 1.
  Future<void> refresh() async {
    await loadInitialPage();
  }
}
