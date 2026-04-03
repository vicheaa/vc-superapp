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
  })  : _secureStorage = secureStorage,
        _dio = tokenDio;

  final SecureStorageService _secureStorage;
  final Dio _dio;

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
        name: 'Super Admin',
        avatarUrl: 'https://img.freepik.com/free-vector/gradient-anime-character-illustration_23-2149451996.jpg',
        role: AppRole.admin,
      );
    }
    return const User(
      id: '2',
      email: 'user@test.com',
      name: 'Vichea Saro',
      avatarUrl: 'https://img.freepik.com/free-vector/shogun-samurai-warrior-traditional-illustration-culture_23-2148783472.jpg',
      role: AppRole.user,
      permissions: ['view_dashboard', 'buy_items'],
    );
  }

  @override
  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'http://10.0.3.165:8000/api/v1/auth/login',
        data: {
          'email': username,
          'password': password,
        },
      );

      final data = response.data['data'];
      final userJson = data['user'];
      final tokensJson = data['tokens'];

      final accessToken = tokensJson['accessToken'];
      final refreshToken = tokensJson['refreshToken'];

      // Basic extraction of roles for AppRole enum
      final roles = List<String>.from(userJson['roles'] ?? []);
      final roleStr = roles.isNotEmpty ? roles.first : 'user';
      final appRole = roleStr == 'admin' ? AppRole.admin : AppRole.user;

      final user = User(
        id: userJson['id'].toString(),
        email: userJson['email'],
        name: userJson['name'] ?? userJson['email'].split('@').first,
        avatarUrl: userJson['avatar_url'],
        role: appRole,
        permissions: List<String>.from(userJson['permissions'] ?? []),
      );

      await _secureStorage.saveAccessToken(accessToken);
      await _secureStorage.saveRefreshToken(refreshToken);

      _updateStatus(AuthState(status: AuthStatus.authenticated, user: user));
    } on DioException catch (e) {
      AppLogger.error('Login failed', error: e, tag: 'AUTH');
      
      if (e.response?.data != null) {
        final resData = e.response!.data;
        if (resData['message'] != null) {
          throw Exception(resData['message']);
        }
      }
      throw Exception('Network or server error occurred');
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
