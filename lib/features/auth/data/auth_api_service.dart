import 'package:dio/dio.dart';

import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';
import 'models/auth_response.dart';

class AuthApiService extends BaseApiService {
  AuthApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ApiResult<AuthResponse>> login(String username, String password) {
    return request<AuthResponse>(
      call: _dio.post(
        '/v1/auth/login',
        data: {
          'email': username,
          'password': password,
        },
      ),
      mapper: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
