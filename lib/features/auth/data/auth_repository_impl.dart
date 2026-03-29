import 'dart:async';
import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SecureStorageService secureStorage,
    required Dio tokenDio,
  })  : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  final _statusController = StreamController<AuthState>.broadcast();
  AuthState _currentStatus = AuthState.initial;

  @override
  Stream<AuthState> get statusStream => _statusController.stream;

  @override
  AuthState get currentStatus => _currentStatus;

  void _updateStatus(AuthState state) {
    if (_currentStatus != state) {
      _currentStatus = state;
      _statusController.add(state);
    }
  }

  @override
  Future<void> init() async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // In a real app we would decode JWT payload or fetch profile here.
      // E.g., final userStr = await _secureStorage.read('cached_user');
      // For now, let's mock the profile fetch:
      
      final savedUserStr = await _secureStorage.getRefreshToken(); // abusing refresh token slot to remember user mock 
      User user = _getUserByEmail('user@test.com'); // generic fallback
      
      if (savedUserStr == 'mock_admin_refresh') {
        user = _getUserByEmail('admin@test.com');
      }

      _updateStatus(AuthState(status: AuthStatus.authenticated, user: user));
    } else {
      _updateStatus(AuthState.unauthenticated);
    }
  }

  User _getUserByEmail(String email) {
    if (email == 'admin@test.com') {
      return const User(
        id: '1',
        email: 'admin@test.com',
        role: AppRole.admin,
      );
    }
    return const User(
      id: '2',
      email: 'user@test.com',
      role: AppRole.user,
      permissions: ['view_dashboard', 'buy_items'],
    );
  }

  @override
  Future<void> login(String username, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if ((username == 'test@test.com' || username == 'admin@test.com' || username == 'user@test.com') && password == 'password') {
        // Mock successful login
        final mockAccessToken = 'mock_jwt_access_token_${DateTime.now().millisecondsSinceEpoch}';
        
        final user = _getUserByEmail(username);
        final mockRefreshToken = user.isAdmin ? 'mock_admin_refresh' : 'mock_user_refresh';
        
        await _secureStorage.saveAccessToken(mockAccessToken);
        await _secureStorage.saveRefreshToken(mockRefreshToken);
        
        _updateStatus(AuthState(status: AuthStatus.authenticated, user: user));
        return;
      }
      
      throw Exception('Invalid credentials');
    } catch (e) {
      AppLogger.error('Login failed', error: e, tag: 'AUTH');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAll();
    _updateStatus(AuthState.unauthenticated);
  }

  @override
  void markUnauthenticated() {
    _updateStatus(AuthState.unauthenticated);
  }
}
