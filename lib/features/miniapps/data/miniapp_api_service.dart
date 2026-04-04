import 'package:dio/dio.dart';

import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';
import 'models/miniapp_response.dart';

class MiniAppApiService extends BaseApiService {
  MiniAppApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ApiResult<MiniAppResponse>> getAvailableMiniApps() {
    return request<MiniAppResponse>(
      call: _dio.get('/v1/miniapps'),
      mapper: (data) => MiniAppResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
