import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';

/// A widget that only renders its child if the current authenticated user
/// has the required [permission].
///
/// If the user is unauthenticated or lacks the permission, it renders the 
/// [fallback] widget (which defaults to `SizedBox.shrink()`).
class RequirePermission extends ConsumerWidget {
  const RequirePermission({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  /// The specific permission string to check for.
  final String permission;

  /// The widget to display if authorized.
  final Widget child;

  /// The widget to display if unauthorized.
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);

    if (authStateAsync.isLoading || !authStateAsync.hasValue) {
      return fallback;
    }

    final authState = authStateAsync.value!;
    
    if (authState.status != AuthStatus.authenticated || authState.user == null) {
      return fallback;
    }

    final user = authState.user!;
    if (user.hasPermission(permission)) {
      return child;
    }

    return fallback;
  }
}

/// A simpler variant that checks if the user is an admin.
class RequireAdmin extends ConsumerWidget {
  const RequireAdmin({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);

    if (authStateAsync.isLoading || !authStateAsync.hasValue) {
      return fallback;
    }

    final authState = authStateAsync.value!;
    
    if (authState.status == AuthStatus.authenticated && authState.user?.isAdmin == true) {
      return child;
    }

    return fallback;
  }
}
