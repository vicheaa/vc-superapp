import 'package:dio/dio.dart';

import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';
import '../domain/models/profile.dart';

class ProfileApiService extends BaseApiService {
  ProfileApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ApiResult<List<Profile>>> getItems({
    required int page,
    int? limit,
  }) {
    return request<List<Profile>>(
      call: _dio.get(
        '/me',
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      ),
      mapper: (data) {
        final list = data as List<dynamic>;
        return list.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
      },
    );
  }
}
