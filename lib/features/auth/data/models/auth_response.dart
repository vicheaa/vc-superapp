import '../../domain/models/user_model.dart';

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final userJson = data['user'];
    final tokensJson = data['tokens'];

    // Map roles to AppRole
    final roles = List<String>.from(userJson['roles'] ?? []);
    final roleStr = roles.isNotEmpty ? roles.first : 'user';
    final appRole = roleStr == 'admin' ? AppRole.admin : AppRole.user;

    return AuthResponse(
      user: User(
        id: userJson['id'].toString(),
        email: userJson['email'],
        name: userJson['name'] ?? userJson['email'].split('@').first,
        avatarUrl: userJson['avatar_url'],
        role: appRole,
        permissions: List<String>.from(userJson['permissions'] ?? []),
      ),
      tokens: AuthTokens.fromJson(tokensJson),
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
