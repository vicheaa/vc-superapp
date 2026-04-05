import 'dart:async';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/models/user_model.dart';
import 'auth_api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SecureStorageService secureStorage,
    required AuthApiService apiService,
  })  : _secureStorage = secureStorage,
        _apiService = apiService;

  final SecureStorageService _secureStorage;
  final AuthApiService _apiService;

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
    final userData = await _secureStorage.getUserData();

    if (token != null && token.isNotEmpty && userData != null) {
      try {
        final user = User.fromJson(userData);
        _updateStatus(AuthState(status: AuthStatus.authenticated, user: user));
      } catch (e) {
        AppLogger.error('Failed to restore user from storage', error: e, tag: 'AUTH');
        _updateStatus(AuthState.unauthenticated);
      }
    } else {
      _updateStatus(AuthState.unauthenticated);
    }
  }

  @override
  Future<void> login(String username, String password) async {
    final result = await _apiService.login(username, password);

    return result.when(
      success: (data) async {
        await _secureStorage.saveAccessToken(data.tokens.accessToken);
        await _secureStorage.saveRefreshToken(data.tokens.refreshToken);
        await _secureStorage.saveUserData(data.user.toJson());

        _updateStatus(AuthState(status: AuthStatus.authenticated, user: data.user));
      },
      failure: (message, statusCode) {
        AppLogger.error('Login failed', error: message, tag: 'AUTH');
        throw Exception(message);
      },
    );
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

  @override
  void dispose() {
    _statusController.close();
  }
}
