import 'dart:convert';

import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';

class AuthRepository {
  const AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    final loginResponse = LoginResponse.fromJson(
      await _apiClient.postJsonMap(
        '/api/auth/login',
        body: LoginRequest(
          usernameOrEmail: usernameOrEmail,
          password: password,
        ).toJson(),
      ),
    );

    final currentUser = await fetchCurrentUser(loginResponse.accessToken);
    final session = AuthSession(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
      user: currentUser,
      expiresAtUtc: loginResponse.expiresAtUtc,
    );

    await _persistSession(session);
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final storedTokens = await _readStoredTokens();
    final accessToken = storedTokens.accessToken;
    final cachedSession = await _readCachedSession(
      accessToken,
      storedTokens.refreshToken,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      return await _fetchAndPersistSession(
        accessToken: accessToken,
        refreshToken: storedTokens.refreshToken,
        expiresAtUtc: cachedSession?.expiresAtUtc,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final refreshedSession = await _tryRefreshSession(
          refreshToken: storedTokens.refreshToken,
          fallbackExpiresAtUtc: cachedSession?.expiresAtUtc,
          cachedSession: cachedSession,
        );
        if (refreshedSession != null) {
          return refreshedSession;
        }
      }

      if (error.statusCode == 0 && cachedSession != null) {
        return cachedSession;
      }

      rethrow;
    }
  }

  Future<AuthSession?> refreshSession() async {
    final storedTokens = await _readStoredTokens();
    final accessToken = storedTokens.accessToken;
    final cachedSession = await _readCachedSession(
      accessToken,
      storedTokens.refreshToken,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      return await _fetchAndPersistSession(
        accessToken: accessToken,
        refreshToken: storedTokens.refreshToken,
        expiresAtUtc: cachedSession?.expiresAtUtc,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final refreshedSession = await _tryRefreshSession(
          refreshToken: storedTokens.refreshToken,
          fallbackExpiresAtUtc: cachedSession?.expiresAtUtc,
          cachedSession: cachedSession,
        );
        if (refreshedSession != null) {
          return refreshedSession;
        }
      }

      if (error.statusCode == 0 && cachedSession != null) {
        return cachedSession;
      }

      rethrow;
    }
  }

  Future<AuthSession?> recoverSessionAfterUnauthorized() async {
    final storedTokens = await _readStoredTokens();
    final accessToken = storedTokens.accessToken;
    final cachedSession = await _readCachedSession(
      accessToken,
      storedTokens.refreshToken,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return _tryRefreshSession(
      refreshToken: storedTokens.refreshToken,
      fallbackExpiresAtUtc: cachedSession?.expiresAtUtc,
      cachedSession: cachedSession,
    );
  }

  Future<CurrentUser> fetchCurrentUser(String accessToken) async {
    final response = await _apiClient.getJsonMap(
      '/api/auth/me',
      accessToken: accessToken,
      allowUnauthorizedRecovery: false,
    );

    return CurrentUser.fromJson(response);
  }

  Future<void> clearSession() async {
    await _tokenStorage.clear();
  }

  Future<AuthSession?> _readCachedSession(
    String? accessToken,
    String? refreshToken,
  ) async {
    final raw = await _tokenStorage.readCachedSessionJson();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! JsonMap) {
        return null;
      }

      final session = AuthSession.fromJson(decoded);
      if (accessToken != null &&
          accessToken.isNotEmpty &&
          session.accessToken.trim().isNotEmpty &&
          session.accessToken != accessToken) {
        return null;
      }
      if (refreshToken != null &&
          refreshToken.isNotEmpty &&
          (session.refreshToken?.trim().isNotEmpty ?? false) &&
          session.refreshToken != refreshToken) {
        return null;
      }

      return session;
    } on FormatException {
      return null;
    }
  }

  Future<AuthSession> _fetchAndPersistSession({
    required String accessToken,
    required String? refreshToken,
    required DateTime? expiresAtUtc,
  }) async {
    final currentUser = await fetchCurrentUser(accessToken);
    final session = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: currentUser,
      expiresAtUtc: expiresAtUtc,
    );

    await _persistSession(session);
    return session;
  }

  Future<void> _persistSession(AuthSession session) async {
    await _tokenStorage.writeToken(session.accessToken);
    await _tokenStorage.writeRefreshToken(session.refreshToken);
    await _tokenStorage.writeCachedSessionJson(jsonEncode(session.toJson()));
  }

  Future<AuthSession?> _tryRefreshSession({
    required String? refreshToken,
    required DateTime? fallbackExpiresAtUtc,
    required AuthSession? cachedSession,
  }) async {
    final refreshedTokens = await _refreshTokens(refreshToken);
    if (refreshedTokens == null) {
      return null;
    }

    try {
      return await _fetchAndPersistSession(
        accessToken: refreshedTokens.accessToken!,
        refreshToken: refreshedTokens.refreshToken,
        expiresAtUtc: refreshedTokens.expiresAtUtc ?? fallbackExpiresAtUtc,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 0 && cachedSession != null) {
        return cachedSession;
      }

      rethrow;
    }
  }

  Future<_StoredTokens?> _refreshTokens(String? refreshToken) async {
    final refreshPath = AppConfig.authRefreshPath;
    final normalizedRefreshToken = refreshToken?.trim() ?? '';

    if (refreshPath == null || normalizedRefreshToken.isEmpty) {
      return null;
    }

    try {
      final response = RefreshTokenResponse.fromJson(
        await _apiClient.postJsonMap(
          refreshPath,
          body: <String, dynamic>{'refreshToken': normalizedRefreshToken},
          allowUnauthorizedRecovery: false,
        ),
      );

      final nextAccessToken = response.accessToken.trim();
      if (nextAccessToken.isEmpty) {
        return null;
      }

      final nextRefreshToken = response.refreshToken?.trim().isNotEmpty ?? false
          ? response.refreshToken!.trim()
          : normalizedRefreshToken;

      return _StoredTokens(
        accessToken: nextAccessToken,
        refreshToken: nextRefreshToken,
        expiresAtUtc: response.expiresAtUtc,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) {
        return null;
      }

      rethrow;
    }
  }

  Future<_StoredTokens> _readStoredTokens() async {
    return _StoredTokens(
      accessToken: await _tokenStorage.readToken(),
      refreshToken: await _tokenStorage.readRefreshToken(),
      expiresAtUtc: null,
    );
  }
}

class _StoredTokens {
  const _StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAtUtc;
}
