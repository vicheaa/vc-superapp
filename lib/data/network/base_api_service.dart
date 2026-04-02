import 'package:dio/dio.dart';

import '../../core/error/error_handler.dart';
import '../../core/utils/logger.dart';
import 'api_result.dart';

/// Abstract central API service to wrap Dio requests and map them cleanly to `ApiResult`.
/// 
/// Note: Token refresh and retry logic are already handled natively by
/// `AuthInterceptor` and `RetryInterceptor`.
abstract class BaseApiService {
  Future<ApiResult<T>> request<T>({
    required Future<Response> call,
    required T Function(dynamic data) mapper,
  }) async {
    try {
      final response = await call;
      return ApiResult.success(mapper(response.data));
    } on DioException catch (e) {
      final appException = GlobalErrorHandler.handleDioException(e);
      
      AppLogger.error(
        'API Request Failed', 
        error: appException.message, 
        tag: 'BaseApiService'
      );
      
      return ApiResult.failure(
        appException.message, 
        statusCode: appException.statusCode ?? e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected Exception', 
        error: e, 
        tag: 'BaseApiService'
      );
      
      return ApiResult.failure('An unexpected error occurred: $e');
    }
  }
}
