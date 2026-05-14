import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'getJsonMap retries once after unauthorized recovery returns new token',
    () async {
      var currentToken = 'stale-token';
      var requestCount = 0;

      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          requestCount += 1;

          if (request.headers['Authorization'] == 'Bearer stale-token') {
            return http.Response(
              '{"status":401,"title":"Unauthorized","detail":"expired"}',
              401,
              headers: <String, String>{
                'content-type': 'application/problem+json',
              },
            );
          }

          return http.Response('{"ok":true}', 200);
        }),
      );

      client.configureAuthentication(
        accessTokenProvider: () => currentToken,
        unauthorizedRecoveryHandler: () async {
          currentToken = 'fresh-token';
          return currentToken;
        },
      );

      final response = await client.getJsonMap(
        '/api/test',
        accessToken: 'stale-token',
      );

      expect(requestCount, 2);
      expect(response['ok'], true);
    },
  );

  test('getJsonMap surfaces backend message and validation errors', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        return http.Response(
          '{"message":"Barkod bulunamadi","errors":{"barcode":["Gecersiz barkod"]}}',
          400,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(
      client.getJsonMap('/api/test', accessToken: 'token'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.title, 'title', 'Barkod bulunamadi')
            .having(
              (error) => error.detail,
              'detail',
              contains('barcode: Gecersiz barkod'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Barkod bulunamadi'),
            ),
      ),
    );
  });
}
