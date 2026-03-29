enum AppRole { admin, manager, user }

class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.permissions = const [],
  });

  final String id;
  final String email;
  final AppRole role;
  final List<String> permissions;

  bool get isAdmin => role == AppRole.admin;
  bool get isManager => role == AppRole.manager;
  
  bool hasPermission(String permission) {
    if (isAdmin) return true; // Admins override all specific permissions
    return permissions.contains(permission);
  }
}
