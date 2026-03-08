import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/config/env_config.dart';
import '../../core/constants/api_constants.dart';
import '../local/hive_storage.dart';
import '../local/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Factory that creates and configures the [Dio] HTTP client
/// with all production interceptors attached.
class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    required HiveStorageService cacheStorage,
  }) {
    _dio = _createDio();
    _tokenDio = _createTokenDio();

    // Order matters: Auth → Cache → Retry → Logging
    _dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        tokenDio: _tokenDio,
      ),
      CacheInterceptor(cacheStorage: cacheStorage),
      RetryInterceptor(dio: _dio),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }

  late final Dio _dio;
  late final Dio _tokenDio;

  /// The primary Dio instance to use for all API calls.
  Dio get dio => _dio;

  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
      ),
    );
  }

  /// Separate Dio instance for token refresh to avoid interceptor recursion.
  Dio _createTokenDio() {
    return Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
      ),
    );
  }
}
