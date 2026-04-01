import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageUtils {
  late SharedPreferences _sharedPreferences;
  static final LocalStorageUtils _instance = LocalStorageUtils._internal();

  LocalStorageUtils._internal();

  factory LocalStorageUtils() {
    return _instance;
  }

  Future<void> init() async {
    try {
      _sharedPreferences = await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SharedPreferences: $e');
      }
      rethrow;
    }
  }

  Future<bool> clear() async {
    try {
      return await _sharedPreferences.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing SharedPreferences: $e');
      }
      return false;
    }
  }

  Future<bool> setKeyString(String key, String value) async {
    try {
      return await _sharedPreferences.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting string key $key: $e');
      }
      return false;
    }
  }

  Future<bool> setBoolKey(String key, bool value) async {
    try {
      return await _sharedPreferences.setBool(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting bool key $key: $e');
      }
      return false;
    }
  }

  Future<bool> setDoubleKey(String key, double value) async {
    try {
      return await _sharedPreferences.setDouble(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting double key $key: $e');
      }
      return false;
    }
  }

  String? getStringKey(String key) {
    try {
      return _sharedPreferences.getString(key);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting string key $key: $e');
      }
      return null;
    }
  }

  bool? getBoolKey(String key) {
    try {
      return _sharedPreferences.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bool key $key: $e');
      }
      return null;
    }
  }

  double? getDoubleKey(String key) {
    try {
      return _sharedPreferences.getDouble(key);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting double key $key: $e');
      }
      return null;
    }
  }

  Future<bool> removeKey(String key) async {
    try {
      return await _sharedPreferences.remove(key);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing key $key: $e');
      }
      return false;
    }
  }
}
