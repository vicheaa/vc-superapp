import '../../../core/error/failure.dart';
import '../domain/home_repository.dart';
import '../domain/models/post.dart';
import 'home_api_service.dart';

/// Concrete implementation of [HomeRepository].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeApiService apiService}) : _apiService = apiService;

  final HomeApiService _apiService;

  @override
  Future<List<Post>> getPosts({required int page, int? limit}) async {
    final result = await _apiService.getPosts(page: page, limit: limit ?? 20);

    return result.when(
      success: (data) => data,
      failure: (message, statusCode) => throw NetworkFailure(message: message),
    );
  }
}
