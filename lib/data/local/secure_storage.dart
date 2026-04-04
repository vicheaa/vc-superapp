import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      if (kDebugMode) {
        print('Error reading access token: $e');
      }
      return null;
    }
  }

  Future<bool> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving access token: $e');
      }
      return false;
    }
  }

  // ──── User Data ────

  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userDataKey, value: jsonEncode(userData));
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonStr = await _storage.read(key: _userDataKey);
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading user data: $e');
      }
      return null;
    }
  }

  Future<bool> deleteUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
      return false;
    }
  }

  Future<bool> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting access token: $e');
      }
      return false;
    }
  }

  // ──── Refresh Token ────

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading refresh token: $e');
      }
      return null;
    }
  }

  Future<bool> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving refresh token: $e');
      }
      return false;
    }
  }

  Future<bool> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting refresh token: $e');
      }
      return false;
    }
  }

  // ──── Clear All ────

  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all: $e');
      }
      return false;
    }
  }


  // ──── FCM Token ────

  Future<bool> saveFcmToken(String token) async {
    try {
      await _storage.write(key: _fcmtoken, value: token);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
      return false;
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await _storage.read(key: _fcmtoken);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading FCM token: $e');
      }
      return null;
    }
  }

  Future<bool> deleteFcmToken() async {
    try {
      await _storage.delete(key: _fcmtoken);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
      return false;
    }
  }

  // ──── Username ────

  Future<bool> saveUsername(String username) async {
    try {
      await _storage.write(key: _usernameKey, value: username);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving username: $e');
      }
      return false;
    }
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _usernameKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading username: $e');
      }
      return null;
    }
  }

  Future<bool> savePassword(String password) async {
    try {
      await _storage.write(key: _passwordKey, value: password);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving password: $e');
      }
      return false;
    }
  }

  Future<String?> getPassword() async {
    try {
      return await _storage.read(key: _passwordKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading password: $e');
      }
      return null;
    }
  }

  Future<bool> deleteToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting token: $e');
      }
      return false;
    }
  }

    Future<String?> getToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading token: $e');
      }
      return null;
    }
  }
}
