import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/logger.dart';

/// Wrapper around [FlutterSecureStorage] for managing auth tokens.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey      = 'access_token';
  static const _refreshTokenKey     = 'refresh_token';
  static const String _usernameKey  = 'username';
  static const String _passwordKey  = 'password';
  static const String _fcmtoken     = 'fcm_token';
  static const String _userDataKey  = 'user_data';

  // ──── Access Token ────

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      AppLogger.error('Error reading access token', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      return true;
    } catch (e) {
      AppLogger.error('Error saving access token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  // ──── User Data ────

  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userDataKey, value: jsonEncode(userData));
      return true;
    } catch (e) {
      AppLogger.error('Error saving user data', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonStr = await _storage.read(key: _userDataKey);
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error reading user data', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> deleteUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting user data', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<bool> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting access token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  // ──── Refresh Token ────

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      AppLogger.error('Error reading refresh token', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      return true;
    } catch (e) {
      AppLogger.error('Error saving refresh token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<bool> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting refresh token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  // ──── Clear All ────

  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e) {
      AppLogger.error('Error clearing all storage', error: e, tag: 'STORAGE');
      return false;
    }
  }

  // ──── FCM Token ────

  Future<bool> saveFcmToken(String token) async {
    try {
      await _storage.write(key: _fcmtoken, value: token);
      return true;
    } catch (e) {
      AppLogger.error('Error saving FCM token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await _storage.read(key: _fcmtoken);
    } catch (e) {
      AppLogger.error('Error reading FCM token', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> deleteFcmToken() async {
    try {
      await _storage.delete(key: _fcmtoken);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting FCM token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  // ──── Username ────

  Future<bool> saveUsername(String username) async {
    try {
      await _storage.write(key: _usernameKey, value: username);
      return true;
    } catch (e) {
      AppLogger.error('Error saving username', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _usernameKey);
    } catch (e) {
      AppLogger.error('Error reading username', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> savePassword(String password) async {
    try {
      await _storage.write(key: _passwordKey, value: password);
      return true;
    } catch (e) {
      AppLogger.error('Error saving password', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<String?> getPassword() async {
    try {
      return await _storage.read(key: _passwordKey);
    } catch (e) {
      AppLogger.error('Error reading password', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<bool> deleteToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting token', error: e, tag: 'STORAGE');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      AppLogger.error('Error reading token', error: e, tag: 'STORAGE');
      return null;
    }
  }

  // ──── Generic Storage ────

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('Error writing key $key', error: e, tag: 'STORAGE');
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('Error reading key $key', error: e, tag: 'STORAGE');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.error('Error deleting key $key', error: e, tag: 'STORAGE');
    }
  }
}
