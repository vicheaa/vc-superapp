import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/logger.dart';
import '../../local/secure_storage.dart';

/// Intercepts requests to attach the access token and handles 401 responses
/// by refreshing the token and replaying the failed request.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio tokenDio,
    this.onLogout,
  })  : _secureStorage = secureStorage,
        _tokenDio = tokenDio;

  final SecureStorageService _secureStorage;
  final VoidCallback? onLogout;

  /// A separate Dio instance used exclusively for the token refresh request
  /// to avoid interceptor recursion.
  final Dio _tokenDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      AppLogger.warning('401 received — attempting token refresh', tag: 'AUTH');

      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null) {
          AppLogger.error('No refresh token available', tag: 'AUTH');
          return handler.reject(err);
        }

        // Attempt to refresh the token
        final response = await _tokenDio.post(
          ApiConstants.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = response.data['access_token'] as String;
        final newRefreshToken = response.data['refresh_token'] as String?;

        // Persist new tokens
        await _secureStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }

        AppLogger.info('Token refreshed successfully', tag: 'AUTH');

        // Replay the original request with the new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _tokenDio.fetch(opts);
        return handler.resolve(retryResponse);
      } on DioException catch (e) {
        AppLogger.error(
          'Token refresh failed',
          tag: 'AUTH',
          error: e,
        );

        // Clear tokens — user must log in again
        await _secureStorage.clearAll();
        onLogout?.call();
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}
