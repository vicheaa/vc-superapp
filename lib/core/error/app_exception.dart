/// Base exception class for the application.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppException($runtimeType): $message';
}

/// Thrown when a network request fails.
class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});
}

/// Thrown when there is no internet connectivity.
class NoInternetException extends AppException {
  const NoInternetException()
      : super(message: 'No internet connection. Please check your network.');
}

/// Thrown when authentication fails or token is invalid.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Session expired. Please log in again.',
    super.statusCode = 401,
  });
}

/// Thrown when the server returns a 5xx error.
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error. Please try again later.',
    super.statusCode,
  });
}

/// Thrown when the request times out.
class TimeoutException extends AppException {
  const TimeoutException()
      : super(message: 'Request timed out. Please try again.');
}

/// Thrown when local cache lookup fails.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Failed to load cached data.',
  });
}

/// Generic unknown exception.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
  });
}
