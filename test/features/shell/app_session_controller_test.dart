import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test(
    'handleUnauthorized applies refreshed session and returns new token',
    () async {
      final repository = _FakeAuthRepository();
      final controller = AppSessionController(authRepository: repository);

      repository.signInResult = _buildSession(
        accessToken: 'token-1',
        refreshToken: 'refresh-1',
      );
      repository.unauthorizedRecoveryResult = _buildSession(
        accessToken: 'token-2',
        refreshToken: 'refresh-2',
      );

      await controller.signIn(usernameOrEmail: 'demo', password: '1234');
      final recoveredToken = await controller.handleUnauthorized();

      expect(recoveredToken, 'token-2');
      expect(controller.status, AppSessionStatus.authenticated);
      expect(controller.accessToken, 'token-2');
    },
  );

  test(
    'handleUnauthorized signs user out when recovery is unavailable',
    () async {
      final repository = _FakeAuthRepository();
      final controller = AppSessionController(authRepository: repository);

      repository.signInResult = _buildSession(accessToken: 'token-1');

      await controller.signIn(usernameOrEmail: 'demo', password: '1234');
      final recoveredToken = await controller.handleUnauthorized();

      expect(recoveredToken, isNull);
      expect(controller.status, AppSessionStatus.unauthenticated);
      expect(
        controller.errorMessage,
        'Oturum suresi doldu. Lutfen tekrar giris yapin.',
      );
      expect(repository.clearSessionCallCount, 1);
    },
  );

  test(
    'refreshSessionOnResume keeps current session during connection errors',
    () async {
      final repository = _FakeAuthRepository();
      final controller = AppSessionController(authRepository: repository);

      repository.signInResult = _buildSession(accessToken: 'token-1');
      repository.refreshSessionError = const ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
        detail: 'offline',
      );

      await controller.signIn(usernameOrEmail: 'demo', password: '1234');
      await controller.refreshSessionOnResume();

      expect(controller.status, AppSessionStatus.authenticated);
      expect(controller.accessToken, 'token-1');
      expect(repository.clearSessionCallCount, 0);
    },
  );

  test('warehouse context guard reports verified context', () async {
    final repository = _FakeAuthRepository();
    final controller = AppSessionController(authRepository: repository);
    repository.signInResult = _buildSession(accessToken: 'token-1');
    repository.warehouseContextResult = _warehouseContext(
      requiresRelogin: false,
    );

    await controller.signIn(usernameOrEmail: 'demo', password: '1234');
    final result = await controller.refreshWarehouseContextGuard();

    expect(result, WarehouseContextGuardResult.verified);
    expect(controller.status, AppSessionStatus.authenticated);
  });

  test(
    'warehouse context guard keeps offline session but reports unavailable',
    () async {
      final repository = _FakeAuthRepository();
      final controller = AppSessionController(authRepository: repository);
      repository.signInResult = _buildSession(accessToken: 'token-1');
      repository.warehouseContextError = const ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
        detail: 'offline',
      );

      await controller.signIn(usernameOrEmail: 'demo', password: '1234');
      final result = await controller.refreshWarehouseContextGuard();

      expect(result, WarehouseContextGuardResult.unavailable);
      expect(controller.status, AppSessionStatus.authenticated);
      expect(repository.clearSessionCallCount, 0);
    },
  );

  test(
    'mutation guard blocks save when warehouse context is unavailable',
    () async {
      final repository = _FakeAuthRepository();
      final controller = AppSessionController(authRepository: repository);
      repository.signInResult = _buildSession(accessToken: 'token-1');
      repository.warehouseContextError = const ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
        detail: 'offline',
      );

      await controller.signIn(usernameOrEmail: 'demo', password: '1234');

      await expectLater(
        controller.ensureWarehouseContextForMutation(),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 0)
              .having(
                (error) => error.message,
                'message',
                contains('islem gonderilmedi'),
              ),
        ),
      );
      expect(controller.status, AppSessionStatus.authenticated);
    },
  );

  test('mutation guard signs out and reports old and new warehouse', () async {
    final repository = _FakeAuthRepository();
    final controller = AppSessionController(authRepository: repository);
    repository.signInResult = _buildSession(accessToken: 'token-1');
    repository.warehouseContextResult = _warehouseContext(
      requiresRelogin: true,
    );

    await controller.signIn(usernameOrEmail: 'demo', password: '1234');

    await expectLater(
      controller.ensureWarehouseContextForMutation(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              allOf(contains('110 KESTEL 1'), contains('160 SUBE 160')),
            ),
      ),
    );
    expect(controller.status, AppSessionStatus.unauthenticated);
    expect(repository.clearSessionCallCount, 1);
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  AuthSession? signInResult;
  AuthSession? restoreSessionResult;
  AuthSession? refreshSessionResult;
  AuthSession? unauthorizedRecoveryResult;
  ApiException? signInError;
  ApiException? restoreSessionError;
  ApiException? refreshSessionError;
  ApiException? unauthorizedRecoveryError;
  WarehouseContext? warehouseContextResult;
  ApiException? warehouseContextError;
  int clearSessionCallCount = 0;

  @override
  Future<AuthSession> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    if (signInError case final error?) {
      throw error;
    }

    return signInResult!;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (restoreSessionError case final error?) {
      throw error;
    }

    return restoreSessionResult;
  }

  @override
  Future<AuthSession?> refreshSession() async {
    if (refreshSessionError case final error?) {
      throw error;
    }

    return refreshSessionResult;
  }

  @override
  Future<AuthSession?> recoverSessionAfterUnauthorized() async {
    if (unauthorizedRecoveryError case final error?) {
      throw error;
    }

    return unauthorizedRecoveryResult;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCallCount += 1;
  }

  @override
  Future<WarehouseContext> fetchWarehouseContext({String? accessToken}) async {
    if (warehouseContextError case final error?) {
      throw error;
    }
    return warehouseContextResult!;
  }
}

AuthSession _buildSession({required String accessToken, String? refreshToken}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAtUtc: DateTime.utc(2026, 5, 11, 12),
    user: const CurrentUser(
      id: 'user-1',
      username: 'demo',
      email: 'demo@example.com',
      firstName: 'Demo',
      lastName: 'User',
      warehouseNo: '110',
      warehouseName: 'KESTEL 1',
      isActive: true,
      roles: <String>['Operator'],
      permissions: <String>['stok-islemleri.sayim-sonuclari.list'],
      modules: <PermissionModule>[],
    ),
  );
}

WarehouseContext _warehouseContext({required bool requiresRelogin}) {
  return WarehouseContext(
    userId: 'user-1',
    username: 'demo',
    tokenWarehouseNo: '110',
    tokenWarehouseName: 'KESTEL 1',
    currentWarehouseNo: requiresRelogin ? '160' : '110',
    currentWarehouseName: requiresRelogin ? 'SUBE 160' : 'KESTEL 1',
    isTerminalUser: true,
    requiresRelogin: requiresRelogin,
    reason: requiresRelogin ? 'WarehouseChanged' : '',
  );
}
