import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';
import '../domain/models/post.dart';

/// API service for Home feature network calls.
class HomeApiService extends BaseApiService {
  HomeApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch paginated posts from the API.
  Future<ApiResult<List<Post>>> getPosts({
    required int page,
    int limit = ApiConstants.defaultPageSize,
  }) {
    return request<List<Post>>(
      call: _dio.get(
        ApiConstants.posts,
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      ),
      mapper: (data) {
        final list = data as List<dynamic>;
        return list.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
      },
    );
  }
}
