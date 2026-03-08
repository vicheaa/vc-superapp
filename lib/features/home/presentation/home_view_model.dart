import '../../../domain/base/base_view_model.dart';
import '../../../domain/base/pagination_mixin.dart';
import '../domain/home_repository.dart';
import '../domain/models/post.dart';

/// ViewModel for the Home screen.
///
/// Demonstrates:
/// - Extending [BaseViewModel] for loading/error state
/// - Using [PaginationMixin] for paginated data loading
class HomeViewModel extends BaseViewModel with PaginationMixin<Post> {
  HomeViewModel({required HomeRepository repository})
      : _repository = repository;

  final HomeRepository _repository;

  @override
  Future<void> init() async {
    await loadInitialPage();
  }

  @override
  Future<List<Post>> fetchPage(int page) async {
    return _repository.getPosts(page: page, limit: pageSize);
  }
}
