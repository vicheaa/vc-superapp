import 'auth_state.dart';

abstract class AuthRepository {
  /// Stream of authentication status changes
  Stream<AuthState> get statusStream;

  /// Get current status synchronously
  AuthState get currentStatus;

  /// Initialize the repository (e.g., check for existing tokens)
  Future<void> init();

  /// Attempt to log in with provided credentials
  Future<void> login(String username, String password);

  /// Log out the user and clear tokens
  Future<void> logout();

  /// Forcefully mark the user as unauthenticated (e.g., used by interceptors on 401)
  void markUnauthenticated();

  /// Release resources (e.g., close stream controllers)
  void dispose();
}
