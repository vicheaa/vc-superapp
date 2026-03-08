import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import 'app_exception.dart';

/// Global error handler that catches all unhandled errors
/// in the Flutter framework and Dart zones.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// Initializes the global error handler.
  /// Call this in `main()` before `runApp()`.
  static void init() {
    // Handle Flutter framework errors (e.g. rendering, layout)
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter framework error',
        tag: 'FLUTTER',
        error: details.exception,
        stackTrace: details.stack,
      );

      // In debug mode, also dump to console for developer visibility
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }

      // Send to Firebase Crashlytics in production
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
  }

  /// Wraps `runApp()` in a guarded zone that catches uncaught async errors.
  static void runGuarded(VoidCallback appRunner) {
    runZonedGuarded(
      appRunner,
      (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Uncaught async error',
          tag: 'ZONE',
          error: error,
          stackTrace: stackTrace,
        );

        // Send to Firebase Crashlytics in production
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: true,
          );
        }
      },
    );
  }

  /// Maps a [DioException] to a typed [AppException].
  static AppException handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const UnauthorizedException();
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: 'Server error ($statusCode)',
            statusCode: statusCode,
          );
        }
        return NetworkException(
          message: e.response?.statusMessage ?? 'Request failed',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');

      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Invalid SSL certificate');

      case DioExceptionType.unknown:
        return UnknownException(
          message: e.message ?? 'An unknown error occurred',
        );
    }
  }

  /// Maps any [Exception] to an [AppException].
  static AppException handleException(Object error) {
    if (error is AppException) return error;
    if (error is DioException) return handleDioException(error);
    return UnknownException(message: error.toString());
  }
}
