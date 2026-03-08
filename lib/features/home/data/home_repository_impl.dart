import '../domain/home_repository.dart';
import '../domain/models/post.dart';
import 'home_api_service.dart';

/// Concrete implementation of [HomeRepository].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeApiService apiService})
      : _apiService = apiService;

  final HomeApiService _apiService;

  @override
  Future<List<Post>> getPosts({required int page, int? limit}) async {
    final response = await _apiService.getPosts(page: page, limit: limit ?? 20);

    final data = response.data as List<dynamic>;
    return data
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
