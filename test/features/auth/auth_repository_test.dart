import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
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
