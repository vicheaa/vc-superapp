import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_handler.dart';
import '../../core/utils/logger.dart';

/// Base class for all ViewModels in the app.
///
/// Provides:
/// - Loading state management
/// - Error state management
/// - `safeCall()` — a guarded wrapper for async operations
/// - Automatic DioException → AppException mapping
abstract class BaseViewModel extends ChangeNotifier {
  // ──── Loading State ────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // ──── Error State ────

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() => setError(null);

  // ──── Safe Async Call ────

  /// Wraps an async operation with loading state management
  /// and automatic error handling.
  ///
  /// Usage:
  /// ```dart
  /// await safeCall(() async {
  ///   final data = await repository.fetchItems();
  ///   _items = data;
  /// });
  /// ```
  Future<T?> safeCall<T>(
    Future<T> Function() action, {
    bool showLoading = true,
    String? errorPrefix,
    VoidCallback? onError,
  }) async {
    try {
      clearError();
      if (showLoading) setLoading(true);

      final result = await action();
      return result;
    } on AppException catch (e) {
      final message = errorPrefix != null ? '$errorPrefix: ${e.message}' : e.message;
      AppLogger.error(message, tag: runtimeType.toString(), error: e);
      setError(message);
      onError?.call();
      return null;
    } on DioException catch (e) {
      final appException = GlobalErrorHandler.handleDioException(e);
      final message = errorPrefix != null
          ? '$errorPrefix: ${appException.message}'
          : appException.message;
      AppLogger.error(message, tag: runtimeType.toString(), error: e);
      setError(message);
      onError?.call();
      return null;
    } catch (e, stackTrace) {
      final message = errorPrefix != null
          ? '$errorPrefix: ${e.toString()}'
          : e.toString();
      AppLogger.error(
        message,
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      setError(message);
      onError?.call();
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  // ──── Lifecycle ────

  /// Override in subclasses to perform initialization work.
  Future<void> init() async {}
}
