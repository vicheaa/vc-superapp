/// Represents a failure that can be displayed to the user.
/// Used as the Left side of Either-style result patterns.
sealed class Failure {
  const Failure({required this.message});

  final String message;

  @override
  String toString() => 'Failure($runtimeType): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred.'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication error.'});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred.'});
}
