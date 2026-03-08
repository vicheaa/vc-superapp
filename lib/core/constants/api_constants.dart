class ApiConstants {
  ApiConstants._();

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Pagination
  static const int defaultPageSize = 20;

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';

  // Endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String posts = '/posts';
}
