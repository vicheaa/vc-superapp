import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>();
});

final authProvider = AsyncNotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;
  StreamSubscription<AuthState>? _statusSubscription;

  @override
  FutureOr<AuthState> build() async {
    _repository = ref.read(authRepositoryProvider);

    // Listen to repository status changes and update state accordingly
    _statusSubscription = _repository.statusStream.listen((stateData) {
      state = AsyncData(stateData);
    });

    ref.onDispose(() {
      _statusSubscription?.cancel();
    });

    // Initialize auth status (e.g., read existing tokens)
    await _repository.init();
    return _repository.currentStatus;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    try {
      await _repository.login(username, password);
      // state will be automatically updated via the stream listener
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.logout();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
