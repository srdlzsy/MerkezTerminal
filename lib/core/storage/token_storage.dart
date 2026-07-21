import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({
    SharedPreferencesAsync? preferences,
    FlutterSecureStorage? secureStorage,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferencesAsync _preferences;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'session.accessToken';
  static const String _refreshTokenKey = 'session.refreshToken';
  static const String _cachedSessionKey = 'session.cachedAuthSession';

  Future<String?> readToken() async {
    return _readSecret(_tokenKey);
  }

  Future<void> writeToken(String token) async {
    await _writeSecret(_tokenKey, token);
  }

  Future<String?> readRefreshToken() async {
    return _readSecret(_refreshTokenKey);
  }

  Future<void> writeRefreshToken(String? refreshToken) async {
    final normalized = refreshToken?.trim() ?? '';
    if (normalized.isEmpty) {
      await _deleteSecret(_refreshTokenKey);
      return;
    }

    await _writeSecret(_refreshTokenKey, normalized);
  }

  Future<String?> readCachedSessionJson() {
    return _preferences.getString(_cachedSessionKey);
  }

  Future<void> writeCachedSessionJson(String rawJson) async {
    await _preferences.setString(_cachedSessionKey, rawJson);
  }

  Future<void> clear() async {
    await _deleteSecret(_tokenKey);
    await _deleteSecret(_refreshTokenKey);
    await _preferences.remove(_cachedSessionKey);
  }

  Future<String?> _readSecret(String key) async {
    final secureValue = await _readSecureValue(key);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    final legacyValue = await _preferences.getString(key);
    if (legacyValue == null || legacyValue.isEmpty) {
      return null;
    }

    await _writeSecret(key, legacyValue);
    await _preferences.remove(key);
    return legacyValue;
  }

  Future<void> _writeSecret(String key, String value) async {
    if (!await _writeSecureValue(key, value)) {
      await _preferences.setString(key, value);
      return;
    }

    await _preferences.remove(key);
  }

  Future<void> _deleteSecret(String key) async {
    await _deleteSecureValue(key);
    await _preferences.remove(key);
  }

  Future<String?> _readSecureValue(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _writeSecureValue(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _deleteSecureValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
