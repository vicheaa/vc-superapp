/// Generic wrapper for API call results.
///
/// Usage:
/// ```dart
/// final result = await apiCall();
/// result.when(
///   success: (data) => print(data),
///   failure: (error, statusCode) => print(error),
/// );
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data) = ApiSuccess<T>;
  factory ApiResult.failure(String message, {int? statusCode}) =
      ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  });
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return success(data);
  }
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return failure(message, statusCode);
  }
}
