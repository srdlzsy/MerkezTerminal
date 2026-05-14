import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const String _tokenKey = 'session.accessToken';
  static const String _refreshTokenKey = 'session.refreshToken';
  static const String _cachedSessionKey = 'session.cachedAuthSession';

  Future<String?> readToken() {
    return _preferences.getString(_tokenKey);
  }

  Future<void> writeToken(String token) async {
    await _preferences.setString(_tokenKey, token);
  }

  Future<String?> readRefreshToken() {
    return _preferences.getString(_refreshTokenKey);
  }

  Future<void> writeRefreshToken(String? refreshToken) async {
    final normalized = refreshToken?.trim() ?? '';
    if (normalized.isEmpty) {
      await _preferences.remove(_refreshTokenKey);
      return;
    }

    await _preferences.setString(_refreshTokenKey, normalized);
  }

  Future<String?> readCachedSessionJson() {
    return _preferences.getString(_cachedSessionKey);
  }

  Future<void> writeCachedSessionJson(String rawJson) async {
    await _preferences.setString(_cachedSessionKey, rawJson);
  }

  Future<void> clear() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_refreshTokenKey);
    await _preferences.remove(_cachedSessionKey);
  }
}
