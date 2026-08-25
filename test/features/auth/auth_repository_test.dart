import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
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
      await controller.refreshWarehouseContextGuard();

      expect(signedIn, isTrue);
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
