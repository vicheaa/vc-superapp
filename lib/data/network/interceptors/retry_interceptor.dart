import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/logger.dart';

/// Automatically retries failed requests with exponential backoff.
///
/// Retries on:
/// - 5xx server errors
/// - Connection timeouts
/// - Send/receive timeouts
/// - Connection errors
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    int? maxRetries,
    Duration? retryDelay,
  })  : _dio = dio,
        _maxRetries = maxRetries ?? ApiConstants.maxRetries,
        _retryDelay = retryDelay ?? ApiConstants.retryDelay;

  final Dio _dio;
  final int _maxRetries;
  final Duration _retryDelay;

  static const _retryCountKey = 'retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= _maxRetries) {
      AppLogger.warning(
        'Max retries ($retryCount/$_maxRetries) reached for ${err.requestOptions.path}',
        tag: 'RETRY',
      );
      return handler.next(err);
    }

    final nextRetry = retryCount + 1;
    final delay = _calculateDelay(nextRetry);

    AppLogger.info(
      'Retrying ($nextRetry/$_maxRetries) ${err.requestOptions.path} '
      'in ${delay.inMilliseconds}ms',
      tag: 'RETRY',
    );

    await Future<void>.delayed(delay);

    err.requestOptions.extra[_retryCountKey] = nextRetry;

    try {
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final retryableTypes = {
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    };

    if (retryableTypes.contains(err.type)) return true;

    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) return true;

    return false;
  }

  /// Exponential backoff with jitter.
  Duration _calculateDelay(int retryCount) {
    final exponentialDelay = _retryDelay.inMilliseconds * pow(2, retryCount - 1);
    final jitter = Random().nextInt(500);
    return Duration(milliseconds: exponentialDelay.toInt() + jitter);
  }
}
