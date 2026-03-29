import 'models/user_model.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  final AuthStatus status;
  final User? user;

  static const initial = AuthState(status: AuthStatus.initial);
  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);
}
