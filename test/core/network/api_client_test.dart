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

  test('ProblemDetails exposes safe create conflict metadata', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        return http.Response(
          '{"title":"Conflict","status":409,'
          '"detail":"Mikro belge icerigi uyusmuyor",'
          '"errorCode":"MIKRO_DOCUMENT_CONTENT_MISMATCH",'
          '"retryable":false,"correlationId":"trace-123"}',
          409,
          headers: <String, String>{'content-type': 'application/problem+json'},
        );
      }),
    );

    await expectLater(
      client.getJsonMap('/api/test', accessToken: 'token'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.errorCode,
              'errorCode',
              'MIKRO_DOCUMENT_CONTENT_MISMATCH',
            )
            .having((error) => error.retryable, 'retryable', isFalse)
            .having(
              (error) => error.correlationId,
              'correlationId',
              'trace-123',
            ),
      ),
    );
  });

  test('uses response header as correlation id fallback', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        return http.Response(
          '{"title":"Server Error","detail":"Kayit tamamlanamadi"}',
          500,
          headers: <String, String>{
            'content-type': 'application/problem+json',
            'x-correlation-id': 'header-trace-456',
          },
        );
      }),
    );

    await expectLater(
      client.getJsonMap('/api/test', accessToken: 'token'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.correlationId,
              'correlationId',
              'header-trace-456',
            )
            .having(
              (error) => error.message,
              'message',
              contains('Destek kodu: header-trace-456'),
            ),
      ),
    );
  });

  test('authorization header keeps only the compact access token', () async {
    final capturedAuthorizationHeaders = <String?>[];
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        capturedAuthorizationHeaders.add(request.headers['Authorization']);
        return http.Response('{"ok":true}', 200);
      }),
    );

    await client.getJsonMap('/api/test', accessToken: 'Bearer compact-token');
    await client.getJsonMap(
      '/api/test',
      accessToken:
          '{"accessToken":"json-token","user":{"permissions":["a","b"]}}',
    );

    expect(capturedAuthorizationHeaders, <String?>[
      'Bearer compact-token',
      'Bearer json-token',
    ]);
    expect(capturedAuthorizationHeaders.join(' '), isNot(contains('user')));
    expect(
      capturedAuthorizationHeaders.join(' '),
      isNot(contains('permissions')),
    );
  });

  test('authorization header is omitted for invalid token payloads', () async {
    final capturedAuthorizationHeaders = <String?>[];
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        capturedAuthorizationHeaders.add(request.headers['Authorization']);
        return http.Response('{"ok":true}', 200);
      }),
    );

    await client.getJsonMap(
      '/api/test',
      accessToken: '{"user":{"permissions":["too-large"]}}',
    );
    await client.getJsonMap('/api/test', accessToken: 'token with spaces');

    expect(capturedAuthorizationHeaders, <String?>[null, null]);
  });

  test(
    'post request is not sent when warehouse mutation guard fails',
    () async {
      var requestCount = 0;
      var guardCount = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          requestCount += 1;
          return http.Response('{"ok":true}', 200);
        }),
      );
      client.configureAuthentication(
        mutationRequestGuard: () async {
          guardCount += 1;
          throw const ApiException(
            statusCode: 0,
            title: 'Depo Bilgisi Dogrulanamadi',
          );
        },
      );

      await expectLater(
        client.postJsonMap('/api/test', body: <String, dynamic>{'value': 1}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.title,
            'title',
            'Depo Bilgisi Dogrulanamadi',
          ),
        ),
      );

      expect(guardCount, 1);
      expect(requestCount, 0);
    },
  );

  test(
    'post request runs once after warehouse mutation guard succeeds',
    () async {
      var requestCount = 0;
      var guardCount = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          requestCount += 1;
          return http.Response('{"ok":true}', 200);
        }),
      );
      client.configureAuthentication(
        mutationRequestGuard: () async {
          guardCount += 1;
        },
      );

      final response = await client.postJsonMap(
        '/api/test',
        body: <String, dynamic>{'value': 1},
      );

      expect(response['ok'], isTrue);
      expect(guardCount, 1);
      expect(requestCount, 1);
    },
  );

  test('post request can explicitly bypass warehouse mutation guard', () async {
    var requestCount = 0;
    var guardCount = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        requestCount += 1;
        return http.Response('{"ok":true}', 200);
      }),
    );
    client.configureAuthentication(
      mutationRequestGuard: () async {
        guardCount += 1;
      },
    );

    await client.postJsonMap('/api/auth/login', verifyWarehouseContext: false);

    expect(guardCount, 0);
    expect(requestCount, 1);
  });
}
