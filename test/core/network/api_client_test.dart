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
          '"retryable":false,"retryAfterSeconds":5,'
          '"correlationId":"trace-123",'
          '"relatedClientRequestId":"existing-request-456"}',
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
            .having((error) => error.retryAfterSeconds, 'retryAfterSeconds', 5)
            .having(
              (error) => error.correlationId,
              'correlationId',
              'trace-123',
            )
            .having(
              (error) => error.relatedClientRequestId,
              'relatedClientRequestId',
              'existing-request-456',
            ),
      ),
    );
  });

  test('English API validation error is shown as Turkish guidance', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        return http.Response(
          '{"title":"Bad Request","status":400,'
          '"detail":"Line quantity must be greater than zero."}',
          400,
        );
      }),
    );

    await expectLater(
      client.getJsonMap('/api/test'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.title, 'title', 'Gecersiz istek')
            .having(
              (error) => error.detail,
              'detail',
              'Eksik veya hatali alanlari kontrol edip yeniden kaydedin.',
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('must be')),
            ),
      ),
    );
  });

  test(
    'non-json server error is shown without technical response body',
    () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          return http.Response('<html>proxy failure</html>', 500);
        }),
      );

      await expectLater(
        client.getJsonMap('/api/test'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.title, 'title', 'Sunucu hatasi')
              .having(
                (error) => error.message,
                'message',
                allOf(
                  contains('Beklenmeyen bir sunucu hatasi'),
                  isNot(contains('<html>')),
                ),
              ),
        ),
      );
    },
  );

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

  test(
    'all critical create routes resolve completed status in the foreground',
    () async {
      const routes = <String, String>{
        '/api/mal-kabul-islemleri/firma-mal-kabulleri':
            '/api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync',
        '/api/stok-islemleri/sayim-sonuclari':
            '/api/stok-islemleri/sayim-sonuclari/offline-sync',
        '/api/siparis-islemleri/verilen-depo-siparisleri':
            '/api/siparis-islemleri/verilen-depo-siparisleri/offline-sync',
        '/api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order':
            '/api/siparis-islemleri/onerilen-depo-siparisleri/offline-sync',
        '/api/siparis-islemleri/verilen-firma-siparisleri':
            '/api/siparis-islemleri/verilen-firma-siparisleri/offline-sync',
        '/api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order':
            '/api/siparis-islemleri/onerilen-firma-siparisleri/offline-sync',
        '/api/sevk-islemleri/depolar-arasi-sevkler/giden':
            '/api/sevk-islemleri/depolar-arasi-sevkler/offline-sync',
        '/api/sevk-islemleri/firma-sevkleri/giden':
            '/api/sevk-islemleri/firma-sevkleri/offline-sync',
        '/api/iade-islemleri/depo-iadeleri/giden':
            '/api/iade-islemleri/depo-iadeleri/offline-sync',
        '/api/iade-islemleri/firma-iadeleri':
            '/api/iade-islemleri/firma-iadeleri/offline-sync',
        '/api/stok-islemleri/zayiat-fisleri':
            '/api/stok-islemleri/zayiat-fisleri/offline-sync',
        '/api/stok-islemleri/masraf-fisleri':
            '/api/stok-islemleri/masraf-fisleri/offline-sync',
        '/api/stok-islemleri/virmanlar':
            '/api/stok-islemleri/virmanlar/offline-sync',
        '/api/green-grocer/operations/adjustments':
            '/api/green-grocer/operations/adjustments/offline-sync',
      };

      for (final entry in routes.entries) {
        var statusRequestCount = 0;
        final requestedPaths = <String>[];
        final client = ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            requestedPaths.add(request.url.path);
            if (request.method == 'POST') {
              return http.Response(
                '{"title":"Conflict","status":409,'
                '"errorCode":"MIKRO_WRITE_IN_PROGRESS",'
                '"retryable":true,"recommendedAction":"WaitAndCheck"}',
                409,
              );
            }

            statusRequestCount += 1;
            if (statusRequestCount == 1) {
              return http.Response(
                '{"status":"Processing",'
                '"recommendedAction":"WaitAndCheck",'
                '"retryAfterSeconds":1}',
                200,
              );
            }

            return http.Response(
              '{"status":"Completed","recommendedAction":"Completed",'
              '"result":{"documentSerie":"F110",'
              '"documentOrderNo":42}}',
              200,
            );
          }),
          createRequestTimeout: const Duration(seconds: 1),
          safeCreateStatusPollInterval: Duration.zero,
          safeCreateStatusRequestTimeout: const Duration(milliseconds: 100),
        );

        final response = await client.postCreateJsonMap(
          entry.key,
          body: const <String, dynamic>{
            'clientRequestId': '11111111-1111-1111-1111-111111111111',
          },
        );

        expect(response['documentSerie'], 'F110', reason: entry.key);
        expect(response['documentOrderNo'], 42, reason: entry.key);
        expect(statusRequestCount, 2, reason: entry.key);
        expect(
          requestedPaths,
          contains('${entry.value}/11111111-1111-1111-1111-111111111111'),
          reason: entry.key,
        );
      }
    },
  );

  test(
    'safe create automatically retries once with the same request',
    () async {
      var postCount = 0;
      var getCount = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          if (request.method == 'POST') {
            postCount += 1;
            if (postCount == 2) {
              expect(
                request.body,
                contains('22222222-2222-2222-2222-222222222222'),
              );
              return http.Response(
                '{"documentSerie":"F110","documentOrderNo":43}',
                200,
              );
            }
            return http.Response('{"title":"Server Error","status":500}', 500);
          }

          getCount += 1;
          return http.Response(
            '{"status":"Failed",'
            '"errorMessage":"Mikro tarafinda belge bulunamadi.",'
            '"errorCode":"SAFE_WRITE_RETRY_ALLOWED",'
            '"retryable":true,"retryAfterSeconds":5,'
            '"recommendedAction":"RetrySameRequest"}',
            200,
          );
        }),
        createRequestTimeout: const Duration(seconds: 1),
        safeCreateStatusPollInterval: Duration.zero,
      );

      final response = await client.postCreateJsonMap(
        '/api/stok-islemleri/virmanlar',
        body: const <String, dynamic>{
          'clientRequestId': '22222222-2222-2222-2222-222222222222',
        },
      );

      expect(response['documentSerie'], 'F110');
      expect(response['documentOrderNo'], 43);
      expect(postCount, 2);
      expect(getCount, 1);
    },
  );

  test('safe create never automatically retries more than once', () async {
    var postCount = 0;
    var cancelCount = 0;
    var getCount = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          if (request.url.path.endsWith('/vazgec')) {
            cancelCount += 1;
            expect(
              request.url.path,
              '/api/mobile-sync/guvenli-yazmalar/'
              '22222222-2222-2222-2222-222222222222/vazgec',
            );
            return http.Response('{"outcome":"Cancelled"}', 200);
          }
          postCount += 1;
          return http.Response('{"title":"Server Error","status":500}', 500);
        }

        getCount += 1;
        return http.Response(
          '{"status":"Failed",'
          '"errorMessage":"Mikro tarafinda belge bulunamadi.",'
          '"errorCode":"SAFE_WRITE_RETRY_ALLOWED",'
          '"retryable":true,"retryAfterSeconds":5,'
          '"recommendedAction":"RetrySameRequest"}',
          200,
        );
      }),
      createRequestTimeout: const Duration(seconds: 1),
      safeCreateStatusPollInterval: Duration.zero,
    );

    await expectLater(
      client.postCreateJsonMap(
        '/api/stok-islemleri/virmanlar',
        body: const <String, dynamic>{
          'clientRequestId': '22222222-2222-2222-2222-222222222222',
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.errorCode,
          'errorCode',
          'SAFE_WRITE_RETRY_EXHAUSTED',
        ),
      ),
    );

    expect(postCount, 2);
    expect(cancelCount, 1);
    expect(getCount, 2);
  });

  test(
    'safe create keeps the retry decision when exhausted record cannot close',
    () async {
      var createPostCount = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/vazgec')) {
            return http.Response('{"title":"Service unavailable"}', 503);
          }
          if (request.method == 'POST') {
            createPostCount += 1;
            return http.Response(
              '{"title":"Conflict","status":409,'
              '"errorCode":"SAFE_WRITE_RETRY_ALLOWED",'
              '"retryable":true,"recommendedAction":"RetrySameRequest"}',
              409,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      await expectLater(
        client.postCreateJsonMap(
          '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
          body: const <String, dynamic>{
            'clientRequestId': '44444444-4444-4444-4444-444444444444',
          },
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.errorCode,
            'errorCode',
            'SAFE_WRITE_RETRY_ALLOWED',
          ),
        ),
      );

      expect(createPostCount, 2);
    },
  );

  test('safe create automatically retries a direct retry decision', () async {
    var postCount = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        postCount += 1;
        if (postCount == 1) {
          return http.Response(
            '{"title":"Conflict","status":409,'
            '"errorCode":"SAFE_WRITE_RETRY_ALLOWED",'
            '"retryable":true,"recommendedAction":"RetrySameRequest"}',
            409,
          );
        }

        return http.Response(
          '{"documentSerie":"F56","documentOrderNo":88971}',
          200,
        );
      }),
    );

    final response = await client.postCreateJsonMap(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
      body: const <String, dynamic>{
        'clientRequestId': '33333333-3333-3333-3333-333333333333',
      },
    );

    expect(postCount, 2);
    expect(response['documentSerie'], 'F56');
    expect(response['documentOrderNo'], 88971);
  });

  test(
    'safe create does not poll status for a definite validation error',
    () async {
      var requestCount = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:5228',
        httpClient: MockClient((request) async {
          requestCount += 1;
          return http.Response(
            '{"title":"Bad Request","status":400,"detail":"Miktar gecersiz"}',
            400,
          );
        }),
        safeCreateStatusPollInterval: Duration.zero,
      );

      await expectLater(
        client.postCreateJsonMap(
          '/api/stok-islemleri/zayiat-fisleri',
          body: const <String, dynamic>{
            'clientRequestId': '33333333-3333-3333-3333-333333333333',
          },
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );

      expect(requestCount, 1);
    },
  );

  test('unregistered create route keeps the regular create behavior', () async {
    var requestCount = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        requestCount += 1;
        return http.Response('{"title":"Server Error"}', 500);
      }),
      safeCreateStatusPollInterval: Duration.zero,
    );

    await expectLater(
      client.postCreateJsonMap(
        '/api/test',
        body: const <String, dynamic>{
          'clientRequestId': '44444444-4444-4444-4444-444444444444',
        },
      ),
      throwsA(isA<ApiException>()),
    );

    expect(requestCount, 1);
  });

  test('create requests use their dedicated longer timeout', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{"ok":true}', 200);
      }),
      requestTimeout: const Duration(milliseconds: 50),
      createRequestTimeout: const Duration(milliseconds: 5),
    );

    final regularResponse = await client.postJsonMap('/api/test');
    expect(regularResponse['ok'], isTrue);

    await expectLater(
      client.postCreateJsonMap('/api/test'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 0)
            .having(
              (error) => error.title,
              'title',
              'Islem zaman asimina ugradi',
            ),
      ),
    );
  });
}
