import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';

enum AppSessionStatus { booting, unauthenticated, authenticated }

class AppSessionController extends ChangeNotifier {
  AppSessionController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  static const String _sessionExpiredMessage =
      'Oturum suresi doldu. Lutfen tekrar giris yapin.';

  final AuthRepository _authRepository;

  AppSessionStatus _status = AppSessionStatus.booting;
  AuthSession? _session;
  String? _errorMessage;
  Future<String?>? _unauthorizedRecovery;
  Future<void>? _resumeRefresh;

  AppSessionStatus get status => _status;
  String? get accessToken => _session?.accessToken;
  CurrentUser? get currentUser => _session?.user;
  String? get errorMessage => _errorMessage;
  List<MenuEntry> get menuEntries =>
      flattenMenus(currentUser?.modules ?? const <PermissionModule>[]);

  bool can(String permissionCode) {
    return currentUser?.hasPermission(permissionCode) ?? false;
  }

  Future<void> restoreSession() async {
    _status = AppSessionStatus.booting;
    notifyListeners();

    try {
      _session = await _authRepository.restoreSession();
      _errorMessage = null;
      _status = _session == null
          ? AppSessionStatus.unauthenticated
          : AppSessionStatus.authenticated;
    } on ApiException catch (error) {
      await _setUnauthenticated(
        clearStoredSession: true,
        errorMessage: _resolveSessionErrorMessage(error),
      );
      return;
    }

    notifyListeners();
  }

  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      _session = await _authRepository.signIn(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      _errorMessage = null;
      _status = AppSessionStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _session = null;
      _status = AppSessionStatus.unauthenticated;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshSessionOnResume() async {
    if (_status != AppSessionStatus.authenticated) {
      return;
    }

    final activeRefresh = _resumeRefresh;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refreshFuture = _performResumeRefresh();
    _resumeRefresh = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      if (identical(_resumeRefresh, refreshFuture)) {
        _resumeRefresh = null;
      }
    }
  }

  Future<String?> handleUnauthorized() async {
    if (_status != AppSessionStatus.authenticated) {
      return null;
    }

    final activeRecovery = _unauthorizedRecovery;
    if (activeRecovery != null) {
      return activeRecovery;
    }

    final recoveryFuture = _performUnauthorizedRecovery();
    _unauthorizedRecovery = recoveryFuture;

    try {
      return await recoveryFuture;
    } finally {
      if (identical(_unauthorizedRecovery, recoveryFuture)) {
        _unauthorizedRecovery = null;
      }
    }
  }

  Future<void> signOut() async {
    await _setUnauthenticated(clearStoredSession: true);
  }

  Future<void> _performResumeRefresh() async {
    try {
      final refreshedSession = await _authRepository.refreshSession();
      if (refreshedSession == null) {
        await _setUnauthenticated(
          clearStoredSession: true,
          errorMessage: _sessionExpiredMessage,
        );
        return;
      }

      _session = refreshedSession;
      _errorMessage = null;
      _status = AppSessionStatus.authenticated;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.statusCode == 0) {
        return;
      }

      await _setUnauthenticated(
        clearStoredSession: true,
        errorMessage: _resolveSessionErrorMessage(error),
      );
    }
  }

  Future<String?> _performUnauthorizedRecovery() async {
    try {
      final refreshedSession = await _authRepository
          .recoverSessionAfterUnauthorized();
      if (refreshedSession == null) {
        await _setUnauthenticated(
          clearStoredSession: true,
          errorMessage: _sessionExpiredMessage,
        );
        return null;
      }

      _session = refreshedSession;
      _errorMessage = null;
      _status = AppSessionStatus.authenticated;
      notifyListeners();
      return refreshedSession.accessToken;
    } on ApiException catch (error) {
      await _setUnauthenticated(
        clearStoredSession: true,
        errorMessage: _resolveSessionErrorMessage(error),
      );
      return null;
    }
  }

  Future<void> _setUnauthenticated({
    required bool clearStoredSession,
    String? errorMessage,
  }) async {
    if (clearStoredSession) {
      await _authRepository.clearSession();
    }

    _session = null;
    _errorMessage = errorMessage;
    _status = AppSessionStatus.unauthenticated;
    notifyListeners();
  }

  String _resolveSessionErrorMessage(ApiException error) {
    if (error.statusCode == 401) {
      return _sessionExpiredMessage;
    }

    return error.message;
  }
}
