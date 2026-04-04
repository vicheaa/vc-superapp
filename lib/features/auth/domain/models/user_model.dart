enum AppRole { admin, manager, user }

class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.avatarUrl,
    this.permissions = const [],
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final AppRole role;
  final List<String> permissions;

  bool get isAdmin => role == AppRole.admin;
  bool get isManager => role == AppRole.manager;
  
  bool hasPermission(String permission) {
    if (isAdmin) return true; // Admins override all specific permissions
    return permissions.contains(permission);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role.name,
      'permissions': permissions,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      role: AppRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'user'),
        orElse: () => AppRole.user,
      ),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
}
