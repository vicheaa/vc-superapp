import 'package:dio/dio.dart';
import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';

class LocalizationApiService extends BaseApiService {
  LocalizationApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Downloads translations for a specific language.
  Future<ApiResult<Map<String, dynamic>>> downloadTranslations({
    required String lang,
    required String currentVersion,
  }) {
    return request<Map<String, dynamic>>(
      call: _dio.get(
        '/v1/languages-data',
        options: Options(
          headers: {
            'x-lang': lang,
            'x-lang-version': currentVersion,
          },
        ),
      ),
      mapper: (data) {
        final json = data as Map<String, dynamic>;
        // If the server wraps the response in 'data', use that, otherwise use the root
        return (
          json['data'] is Map<String, dynamic>
        ) ? json['data'] as Map<String, dynamic> : json;
      },
    );
  }
}
