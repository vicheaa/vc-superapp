import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

/// API service for Home feature network calls.
class HomeApiService {
  HomeApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch paginated posts from the API.
  Future<Response> getPosts({
    required int page,
    int limit = ApiConstants.defaultPageSize,
  }) {
    return _dio.get(
      ApiConstants.posts,
      queryParameters: {
        '_page': page,
        '_limit': limit,
      },
    );
  }
}
