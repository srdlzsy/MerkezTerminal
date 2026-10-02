import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test(
    'restoreSession refreshes tokens with default auth refresh route',
    () async {
      final storage = TokenStorage();
      await storage.ensureAuthClientProfile('terminal');
      await storage.writeToken('stale-token');
      await storage.writeRefreshToken('refresh-1');

      final requestedPaths = <String>[];
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            requestedPaths.add(request.url.path);

            if (request.url.path == '/api/auth/me' &&
                request.headers['Authorization'] == 'Bearer stale-token') {
              return http.Response('{"title":"Unauthorized"}', 401);
            }

            if (request.url.path == '/api/auth/refresh') {
              expect(jsonDecode(request.body), <String, dynamic>{
                'refreshToken': 'refresh-1',
              });
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'accessToken': 'fresh-token',
                  'expiresAtUtc': '2026-08-11T12:00:00Z',
                  'refreshToken': 'refresh-2',
                  'refreshTokenExpiresAtUtc': '2026-08-25T12:00:00Z',
                }),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            if (request.url.path == '/api/auth/me' &&
                request.headers['Authorization'] == 'Bearer fresh-token') {
              return http.Response(
                jsonEncode(_currentUserJson()),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );

      final session = await repository.restoreSession();

      expect(requestedPaths, <String>[
        '/api/auth/me',
        '/api/auth/refresh',
        '/api/auth/me',
      ]);
      expect(session?.accessToken, 'fresh-token');
      expect(session?.refreshToken, 'refresh-2');
      expect(session?.refreshTokenExpiresAtUtc, DateTime.utc(2026, 8, 25, 12));
      expect(await storage.readRefreshToken(), 'refresh-2');
    },
  );

  test(
    'restoreSession uses a valid cached session without waiting for api',
    () async {
      final storage = TokenStorage();
      await storage.ensureAuthClientProfile('terminal');
      await storage.writeToken('cached-token');
      await storage.writeRefreshToken('cached-refresh');
      final cachedSession = <String, dynamic>{
        'accessToken': 'cached-token',
        'refreshToken': 'cached-refresh',
        'expiresAtUtc': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'user': _currentUserJson(),
      };
      await storage.writeCachedSessionJson(jsonEncode(cachedSession));
      var requestCount = 0;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            requestCount += 1;
            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );

      final session = await repository.restoreSession();

      expect(session?.accessToken, 'cached-token');
      expect(session?.user.warehouseNo, '110');
      expect(requestCount, 0);
    },
  );

  test('restoreSession refreshes an expired cached session directly', () async {
    final storage = TokenStorage();
    await storage.ensureAuthClientProfile('terminal');
    await storage.writeToken('expired-token');
    await storage.writeRefreshToken('refresh-1');
    await storage.writeCachedSessionJson(
      jsonEncode(<String, dynamic>{
        'accessToken': 'expired-token',
        'refreshToken': 'refresh-1',
        'expiresAtUtc': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'user': _currentUserJson(),
      }),
    );
    final requestedPaths = <String>[];
    final repository = AuthRepository(
      tokenStorage: storage,
      apiClient: ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path == '/api/auth/refresh') {
            return http.Response(
              jsonEncode(<String, dynamic>{
                'accessToken': 'fresh-token',
                'refreshToken': 'refresh-2',
                'expiresAtUtc': DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
              }),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          return http.Response('{"title":"Unexpected"}', 500);
        }),
      ),
    );

    final session = await repository.restoreSession();

    expect(requestedPaths, <String>['/api/auth/refresh']);
    expect(session?.accessToken, 'fresh-token');
    expect(session?.user.warehouseNo, '110');
  });

  test(
    'shares one refresh request between concurrent recovery callers',
    () async {
      final storage = TokenStorage();
      await storage.ensureAuthClientProfile('terminal');
      await storage.writeToken('stale-token');
      await storage.writeRefreshToken('refresh-1');
      await storage.writeCachedSessionJson(
        jsonEncode(<String, dynamic>{
          'accessToken': 'stale-token',
          'refreshToken': 'refresh-1',
          'expiresAtUtc': DateTime.now()
              .toUtc()
              .add(const Duration(hours: 1))
              .toIso8601String(),
          'user': _currentUserJson(),
        }),
      );

      var refreshRequestCount = 0;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/auth/me') {
              return http.Response('{"title":"Unauthorized"}', 401);
            }

            if (request.url.path == '/api/auth/refresh') {
              refreshRequestCount += 1;
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'accessToken': 'fresh-token',
                  'refreshToken': 'refresh-2',
                  'expiresAtUtc': '2026-10-02T12:00:00Z',
                }),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );

      final unauthorizedRecovery = repository.recoverSessionAfterUnauthorized();
      final secondRecovery = repository.recoverSessionAfterUnauthorized();

      final sessions = await Future.wait(<Future<AuthSession?>>[
        unauthorizedRecovery,
        secondRecovery,
      ]);

      expect(refreshRequestCount, 1);
      expect(sessions, everyElement(isNotNull));
      expect(
        sessions.map((session) => session?.accessToken),
        everyElement('fresh-token'),
      );
      expect(await storage.readToken(), 'fresh-token');
      expect(await storage.readRefreshToken(), 'refresh-2');
    },
  );

  test(
    'uses the stored newer session after a late refresh token 401',
    () async {
      final storage = TokenStorage();
      await storage.ensureAuthClientProfile('terminal');
      await storage.writeToken('stale-token');
      await storage.writeRefreshToken('refresh-1');
      await storage.writeCachedSessionJson(
        jsonEncode(<String, dynamic>{
          'accessToken': 'stale-token',
          'refreshToken': 'refresh-1',
          'expiresAtUtc': '2026-10-02T10:00:00Z',
          'user': _currentUserJson(),
        }),
      );

      var refreshRequestCount = 0;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/auth/refresh') {
              refreshRequestCount += 1;
              await storage.writeToken('fresh-token');
              await storage.writeRefreshToken('refresh-2');
              await storage.writeCachedSessionJson(
                jsonEncode(<String, dynamic>{
                  'accessToken': 'fresh-token',
                  'refreshToken': 'refresh-2',
                  'expiresAtUtc': '2026-10-02T12:00:00Z',
                  'user': _currentUserJson(),
                }),
              );
              return http.Response('{"title":"Unauthorized"}', 401);
            }

            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );

      final session = await repository.recoverSessionAfterUnauthorized();

      expect(refreshRequestCount, 1);
      expect(session?.accessToken, 'fresh-token');
      expect(session?.refreshToken, 'refresh-2');
    },
  );

  test(
    'clearSession posts refresh token to logout and clears local tokens',
    () async {
      final storage = TokenStorage();
      await storage.writeToken('access-token');
      await storage.writeRefreshToken('refresh-token');

      Map<String, dynamic>? logoutBody;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            expect(request.url.path, '/api/auth/logout');
            logoutBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response('', 204);
          }),
        ),
      );

      await repository.clearSession();

      expect(logoutBody, <String, dynamic>{'refreshToken': 'refresh-token'});
      expect(await storage.readToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    },
  );

  test('signIn identifies the installation as a terminal client', () async {
    final storage = TokenStorage();
    final loginBodies = <Map<String, dynamic>>[];
    final repository = AuthRepository(
      tokenStorage: storage,
      apiClient: ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            loginBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
            return http.Response(
              jsonEncode(<String, dynamic>{
                'accessToken': 'access-token',
                'refreshToken': 'refresh-token',
                'expiresAtUtc': '2026-10-01T12:00:00Z',
                'user': _currentUserJson(),
              }),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/auth/me') {
            return http.Response(
              jsonEncode(_currentUserJson()),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/auth/logout') {
            return http.Response('', 204);
          }
          return http.Response('{"title":"Unexpected"}', 500);
        }),
      ),
    );

    await repository.signIn(usernameOrEmail: '160.sube', password: 'secret');
    final firstDeviceId = loginBodies.single['deviceId'] as String;
    expect(loginBodies.single, containsPair('clientType', 'terminal'));
    expect(firstDeviceId, startsWith('terminal-'));
    expect(firstDeviceId.length, lessThanOrEqualTo(100));

    await repository.clearSession();
    await repository.signIn(usernameOrEmail: '160.sube', password: 'secret');

    expect(loginBodies, hasLength(2));
    expect(loginBodies.last['deviceId'], firstDeviceId);
  });

  test(
    'restoreSession clears a cached session from the legacy profile',
    () async {
      final storage = TokenStorage();
      await storage.writeToken('legacy-access-token');
      await storage.writeRefreshToken('legacy-refresh-token');
      await storage.writeCachedSessionJson('{"accessToken":"legacy"}');
      var requestCount = 0;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            requestCount += 1;
            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );

      final session = await repository.restoreSession();

      expect(session, isNull);
      expect(requestCount, 0);
      expect(await storage.readToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(await storage.readCachedSessionJson(), isNull);
      expect(await storage.ensureAuthClientProfile('terminal'), isTrue);
    },
  );

  test('fetchWarehouseContext reads lightweight warehouse context', () async {
    final repository = AuthRepository(
      tokenStorage: TokenStorage(),
      apiClient: ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/auth/warehouse-context');
          expect(request.headers['Authorization'], 'Bearer access-token');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'userId': 'user-1',
              'username': '160.magazaci',
              'tokenWarehouseNo': '160',
              'tokenWarehouseName': '160 SUBE',
              'currentWarehouseNo': '161',
              'currentWarehouseName': 'Depo 161',
              'isTerminalUser': true,
              'requiresRelogin': true,
              'reason': 'WarehouseChanged',
              'serverTimeUtc': '2026-08-25T07:25:00Z',
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      ),
    );

    final context = await repository.fetchWarehouseContext(
      accessToken: 'access-token',
    );

    expect(context.tokenWarehouseNo, '160');
    expect(context.currentWarehouseNo, '161');
    expect(context.requiresRelogin, isTrue);
    expect(context.reason, 'WarehouseChanged');
    expect(context.serverTimeUtc, DateTime.utc(2026, 8, 25, 7, 25));
  });

  test(
    'refreshWarehouseContextGuard signs out when relogin is required',
    () async {
      final storage = TokenStorage();
      final requestedPaths = <String>[];
      Map<String, dynamic>? logoutBody;
      final repository = AuthRepository(
        tokenStorage: storage,
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            requestedPaths.add(request.url.path);

            if (request.url.path == '/api/auth/login') {
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'accessToken': 'access-token',
                  'refreshToken': 'refresh-token',
                  'expiresAtUtc': '2026-08-25T12:00:00Z',
                  'user': _currentUserJson(),
                }),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            if (request.url.path == '/api/auth/me') {
              return http.Response(
                jsonEncode(_currentUserJson()),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            if (request.url.path == '/api/auth/warehouse-context') {
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'userId': 'user-1',
                  'username': 'demo',
                  'tokenWarehouseNo': '110',
                  'tokenWarehouseName': 'KESTEL 1',
                  'currentWarehouseNo': '160',
                  'currentWarehouseName': 'SUBE 160',
                  'isTerminalUser': true,
                  'requiresRelogin': true,
                  'reason': 'WarehouseChanged',
                  'serverTimeUtc': '2026-08-25T07:25:00Z',
                }),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }

            if (request.url.path == '/api/auth/logout') {
              logoutBody = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response('', 204);
            }

            return http.Response('{"title":"Unexpected"}', 500);
          }),
        ),
      );
      final controller = AppSessionController(authRepository: repository);

      final signedIn = await controller.signIn(
        usernameOrEmail: 'demo',
        password: 'secret',
      );
      final result = await controller.refreshWarehouseContextGuard();

      expect(signedIn, isTrue);
      expect(result, WarehouseContextGuardResult.signedOut);
      expect(controller.status, AppSessionStatus.unauthenticated);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, contains('Depo/IP'));
      expect(logoutBody, <String, dynamic>{'refreshToken': 'refresh-token'});
      expect(requestedPaths, <String>[
        '/api/auth/login',
        '/api/auth/me',
        '/api/auth/warehouse-context',
        '/api/auth/logout',
      ]);
    },
  );
}

Map<String, dynamic> _currentUserJson() {
  return <String, dynamic>{
    'id': 'user-1',
    'username': 'demo',
    'email': 'demo@example.com',
    'firstName': 'Demo',
    'lastName': 'User',
    'warehouseNo': '110',
    'warehouseName': 'KESTEL 1',
    'isActive': true,
    'roles': <String>['Operator'],
    'permissions': <String>['stok-islemleri.sayim-sonuclari.list'],
    'modules': <dynamic>[],
  };
}
