import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:http/http.dart' as http;

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<dynamic>;
typedef AccessTokenProvider = String? Function();
typedef UnauthorizedRecoveryHandler = Future<String?> Function();
typedef MutationRequestGuard = Future<void> Function();

const Map<String, String> _safeCreateStatusPaths = <String, String>{
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
  '/api/stok-islemleri/virmanlar': '/api/stok-islemleri/virmanlar/offline-sync',
  '/api/green-grocer/operations/adjustments':
      '/api/green-grocer/operations/adjustments/offline-sync',
};

class _SafeCreateRoute {
  const _SafeCreateRoute({
    required this.statusPath,
    required this.clientRequestId,
  });

  final String statusPath;
  final String clientRequestId;
}

class ApiBinaryResponse {
  const ApiBinaryResponse({
    required this.bodyBytes,
    required this.headers,
    required this.statusCode,
  });

  final Uint8List bodyBytes;
  final Map<String, String> headers;
  final int statusCode;

  String? get contentType => headers['content-type'];
  String? get contentDisposition => headers['content-disposition'];
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required http.Client httpClient,
    Duration requestTimeout = AppConfig.requestTimeout,
    Duration createRequestTimeout = AppConfig.createRequestTimeout,
    Duration safeCreateStatusPollInterval = const Duration(seconds: 3),
    Duration safeCreateStatusRequestTimeout = const Duration(seconds: 15),
  }) : _baseUri = Uri.parse(baseUrl),
       _httpClient = httpClient,
       _requestTimeout = requestTimeout,
       _createRequestTimeout = createRequestTimeout,
       _safeCreateStatusPollInterval = safeCreateStatusPollInterval,
       _safeCreateStatusRequestTimeout = safeCreateStatusRequestTimeout;

  final Uri _baseUri;
  final http.Client _httpClient;
  final Duration _requestTimeout;
  final Duration _createRequestTimeout;
  final Duration _safeCreateStatusPollInterval;
  final Duration _safeCreateStatusRequestTimeout;
  AccessTokenProvider? _accessTokenProvider;
  UnauthorizedRecoveryHandler? _unauthorizedRecoveryHandler;
  MutationRequestGuard? _mutationRequestGuard;

  void configureAuthentication({
    AccessTokenProvider? accessTokenProvider,
    UnauthorizedRecoveryHandler? unauthorizedRecoveryHandler,
    MutationRequestGuard? mutationRequestGuard,
  }) {
    _accessTokenProvider = accessTokenProvider;
    _unauthorizedRecoveryHandler = unauthorizedRecoveryHandler;
    _mutationRequestGuard = mutationRequestGuard;
  }

  Future<JsonMap> getJsonMap(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
  }) async {
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      request: (resolvedAccessToken) => _httpClient.get(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(accessToken: resolvedAccessToken),
      ),
    );

    return _decodeJsonMap(response);
  }

  Future<JsonList> getJsonList(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
  }) async {
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      request: (resolvedAccessToken) => _httpClient.get(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(accessToken: resolvedAccessToken),
      ),
    );

    return _decodeJsonList(response);
  }

  Future<JsonMap> postJsonMap(
    String path, {
    String? accessToken,
    Object? body,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
    bool verifyWarehouseContext = true,
    Duration? timeout,
  }) async {
    await _guardMutationRequest(verifyWarehouseContext);
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      timeout: timeout,
      request: (resolvedAccessToken) => _httpClient.post(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(accessToken: resolvedAccessToken),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    return _decodeJsonMap(response);
  }

  Future<JsonMap> postCreateJsonMap(
    String path, {
    String? accessToken,
    Object? body,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
    bool verifyWarehouseContext = true,
  }) async {
    await _guardMutationRequest(verifyWarehouseContext);

    final route = _resolveSafeCreateRoute(path, body);
    final deadline = DateTime.now().add(_createRequestTimeout);

    try {
      final response = await _send(
        accessToken: accessToken,
        allowUnauthorizedRecovery: allowUnauthorizedRecovery,
        timeout: _initialSafeCreateRequestTimeout(deadline),
        request: (resolvedAccessToken) => _httpClient.post(
          _buildUri(path, queryParameters: queryParameters),
          headers: _buildHeaders(accessToken: resolvedAccessToken),
          body: body == null ? null : jsonEncode(body),
        ),
      );

      return _decodeJsonMap(response);
    } on ApiException catch (error) {
      if (route == null || !_shouldWaitForSafeCreateResolution(error)) {
        rethrow;
      }

      return _pollSafeCreateStatus(
        route: route,
        accessToken: accessToken,
        allowUnauthorizedRecovery: allowUnauthorizedRecovery,
        deadline: deadline,
        fallbackError: error,
      );
    }
  }

  Duration _initialSafeCreateRequestTimeout(DateTime deadline) {
    const recoveryReserve = Duration(seconds: 30);
    final remaining = deadline.difference(DateTime.now());
    final preferred = remaining - recoveryReserve;

    if (preferred <= Duration.zero) {
      return remaining > Duration.zero
          ? remaining
          : const Duration(microseconds: 1);
    }

    return preferred;
  }

  Future<JsonMap> _pollSafeCreateStatus({
    required _SafeCreateRoute route,
    required String? accessToken,
    required bool allowUnauthorizedRecovery,
    required DateTime deadline,
    required ApiException fallbackError,
  }) async {
    var lastError = fallbackError;

    while (DateTime.now().isBefore(deadline)) {
      final delay = _durationWithinDeadline(
        _safeCreateStatusPollInterval,
        deadline,
      );
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (!DateTime.now().isBefore(deadline)) {
        break;
      }

      try {
        final response = await _send(
          accessToken: accessToken,
          allowUnauthorizedRecovery: allowUnauthorizedRecovery,
          timeout: _durationWithinDeadline(
            _safeCreateStatusRequestTimeout,
            deadline,
          ),
          request: (resolvedAccessToken) => _httpClient.get(
            _buildUri('${route.statusPath}/${route.clientRequestId}'),
            headers: _buildHeaders(accessToken: resolvedAccessToken),
          ),
        );
        final status = _decodeJsonMap(response);
        final normalizedStatus = _readString(status['status']).toLowerCase();
        final recommendedAction = _readString(status['recommendedAction']);
        final result = status['result'];

        if (normalizedStatus == 'completed' ||
            recommendedAction == 'Completed') {
          if (result is Map) {
            return result.map((key, value) => MapEntry(key.toString(), value));
          }
          throw lastError;
        }

        final statusError = _safeCreateStatusException(status, lastError);
        if (normalizedStatus == 'processing' ||
            recommendedAction == 'WaitAndCheck') {
          lastError = statusError;
          continue;
        }

        throw statusError;
      } on ApiException catch (error) {
        if (error.statusCode == 0 ||
            error.statusCode == 401 ||
            error.statusCode == 403) {
          rethrow;
        }

        if (error.statusCode == 404 || error.statusCode >= 500) {
          lastError = error.statusCode == 404 ? lastError : error;
          continue;
        }

        rethrow;
      }
    }

    throw lastError;
  }

  Duration _durationWithinDeadline(Duration preferred, DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return const Duration(microseconds: 1);
    }
    return remaining < preferred ? remaining : preferred;
  }

  _SafeCreateRoute? _resolveSafeCreateRoute(String path, Object? body) {
    if (body is! Map) {
      return null;
    }

    final clientRequestId = _readString(body['clientRequestId']);
    if (clientRequestId.isEmpty) {
      return null;
    }

    final normalizedPath = '/${path.split('?').first}'
        .replaceAll(RegExp(r'/+'), '/')
        .replaceFirst(RegExp(r'/$'), '');
    final statusPath = _safeCreateStatusPaths[normalizedPath];
    if (statusPath == null) {
      return null;
    }

    return _SafeCreateRoute(
      statusPath: statusPath,
      clientRequestId: clientRequestId,
    );
  }

  bool _shouldWaitForSafeCreateResolution(ApiException error) {
    if (error.statusCode >= 500 || error.statusCode == 0) {
      return true;
    }
    if (error.statusCode != 409) {
      return false;
    }

    final action = _readString(error.recommendedAction);
    if (action.isNotEmpty) {
      return action == 'WaitAndCheck';
    }

    final errorCode = _readString(error.errorCode).toUpperCase();
    return errorCode == 'MIKRO_WRITE_IN_PROGRESS' ||
        errorCode == 'MIKRO_WRITE_OUTCOME_UNCONFIRMED' ||
        errorCode == 'MIKRO_DOCUMENT_INCOMPLETE' ||
        error.retryable == true;
  }

  ApiException _safeCreateStatusException(
    JsonMap status,
    ApiException fallback,
  ) {
    return ApiException(
      statusCode: 409,
      title: 'Conflict',
      detail: _readNullableString(status['errorMessage']) ?? fallback.detail,
      errorCode: _readNullableString(status['errorCode']),
      retryable: _readBool(status['retryable']),
      retryAfterSeconds: _readInt(status['retryAfterSeconds']),
      relatedClientRequestId: fallback.relatedClientRequestId,
      correlationId: fallback.correlationId,
      recoveryState: _readNullableString(status['recoveryState']),
      recommendedAction: _readNullableString(status['recommendedAction']),
    );
  }

  String _readString(Object? value) => value?.toString().trim() ?? '';

  String? _readNullableString(Object? value) {
    final normalized = _readString(value);
    return normalized.isEmpty ? null : normalized;
  }

  bool? _readBool(Object? value) {
    if (value is bool) return value;
    return switch (_readString(value).toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_readString(value));
  }

  Future<JsonMap> putJsonMap(
    String path, {
    String? accessToken,
    Object? body,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
    bool verifyWarehouseContext = true,
  }) async {
    await _guardMutationRequest(verifyWarehouseContext);
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      request: (resolvedAccessToken) => _httpClient.put(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(accessToken: resolvedAccessToken),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    return _decodeJsonMap(response);
  }

  Future<ApiBinaryResponse> getBytes(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
    String accept = 'application/pdf',
    bool allowUnauthorizedRecovery = true,
  }) async {
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      request: (resolvedAccessToken) => _httpClient.get(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(
          accessToken: resolvedAccessToken,
          accept: accept,
          contentType: null,
        ),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwProblem(response);
    }

    return ApiBinaryResponse(
      bodyBytes: response.bodyBytes,
      headers: response.headers,
      statusCode: response.statusCode,
    );
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return _baseUri.replace(
      path: normalizedPath,
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
    );
  }

  Map<String, String> _buildHeaders({
    String? accessToken,
    String accept = 'application/json',
    String? contentType = 'application/json',
  }) {
    final normalizedAccessToken = _normalizeAccessToken(accessToken);
    final contentTypeHeader = switch (contentType) {
      final value? => <String, String>{'Content-Type': value},
      null => null,
    };
    final authorizationHeader = switch (normalizedAccessToken) {
      final value? when value.isNotEmpty => <String, String>{
        'Authorization': 'Bearer $value',
      },
      _ => null,
    };

    return <String, String>{
      'Accept': accept,
      ...?contentTypeHeader,
      ...?authorizationHeader,
    };
  }

  Future<http.Response> _send({
    required String? accessToken,
    required bool allowUnauthorizedRecovery,
    Duration? timeout,
    required Future<http.Response> Function(String? resolvedAccessToken)
    request,
  }) async {
    return _sendWithRecovery(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      hasRetriedUnauthorized: false,
      timeout: timeout ?? _requestTimeout,
      request: request,
    );
  }

  Future<http.Response> _sendWithRecovery({
    required String? accessToken,
    required bool allowUnauthorizedRecovery,
    required bool hasRetriedUnauthorized,
    required Duration timeout,
    required Future<http.Response> Function(String? resolvedAccessToken)
    request,
  }) async {
    final resolvedAccessToken = _resolveAccessToken(accessToken);

    try {
      final response = await request(resolvedAccessToken).timeout(timeout);

      if (response.statusCode == 401 &&
          allowUnauthorizedRecovery &&
          !hasRetriedUnauthorized &&
          resolvedAccessToken != null &&
          resolvedAccessToken.isNotEmpty) {
        final recoveredToken = await _recoverUnauthorizedAccessToken();
        final retriedAccessToken = _resolveAccessToken(recoveredToken);

        if (retriedAccessToken != null &&
            retriedAccessToken.isNotEmpty &&
            retriedAccessToken != resolvedAccessToken) {
          return _sendWithRecovery(
            accessToken: retriedAccessToken,
            allowUnauthorizedRecovery: false,
            hasRetriedUnauthorized: true,
            timeout: timeout,
            request: request,
          );
        }
      }

      return response;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        title: 'Timeout',
        detail: 'Sunucudan zamaninda yanit alinamadi.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
        detail: error.message,
      );
    }
  }

  String? _resolveAccessToken(String? requestedAccessToken) {
    final provided = _normalizeAccessToken(_accessTokenProvider?.call());
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }

    final requested = _normalizeAccessToken(requestedAccessToken);
    if (requested == null || requested.isEmpty) {
      return null;
    }

    return requested;
  }

  Future<String?> _recoverUnauthorizedAccessToken() async {
    final handler = _unauthorizedRecoveryHandler;
    if (handler == null) {
      return null;
    }

    final recovered = await handler();
    final normalized = _normalizeAccessToken(recovered);
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  Future<void> _guardMutationRequest(bool verifyWarehouseContext) async {
    if (!verifyWarehouseContext) {
      return;
    }

    final guard = _mutationRequestGuard;
    if (guard != null) {
      await guard();
    }
  }

  String? _normalizeAccessToken(String? value) {
    var normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    normalized = _stripBearerPrefix(normalized);

    if (normalized.startsWith('{')) {
      final embeddedAccessToken = _readEmbeddedAccessToken(normalized);
      if (embeddedAccessToken == null) {
        return null;
      }

      normalized = _stripBearerPrefix(embeddedAccessToken);
    }

    if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) {
      return null;
    }

    return normalized;
  }

  String _stripBearerPrefix(String value) {
    final normalized = value.trim();
    const bearerPrefix = 'bearer ';

    if (normalized.toLowerCase().startsWith(bearerPrefix)) {
      return normalized.substring(bearerPrefix.length).trim();
    }

    return normalized;
  }

  String? _readEmbeddedAccessToken(String value) {
    if (!value.startsWith('{')) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! JsonMap) {
        return null;
      }

      final accessToken = decoded['accessToken']?.toString().trim() ?? '';
      if (accessToken.isEmpty) {
        return null;
      }

      return accessToken;
    } on FormatException {
      return null;
    }
  }

  JsonMap _decodeJsonMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwProblem(response);
    }

    final decoded = _decode(response);

    if (decoded is JsonMap) {
      return decoded;
    }

    throw const ApiException(
      statusCode: 0,
      title: 'Beklenmeyen Yanit',
      detail: 'Sunucudan nesne tipinde JSON yaniti bekleniyordu.',
    );
  }

  JsonList _decodeJsonList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwProblem(response);
    }

    final decoded = _decode(response);

    if (decoded is JsonList) {
      return decoded;
    }

    throw const ApiException(
      statusCode: 0,
      title: 'Beklenmeyen Yanit',
      detail: 'Sunucudan liste tipinde JSON yaniti bekleniyordu.',
    );
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    final body = utf8.decode(response.bodyBytes);

    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return <String, dynamic>{'raw': body};
    }
  }

  Never _throwProblem(http.Response response) {
    final decoded = _decode(response);

    if (decoded is JsonMap) {
      final title = _problemTitle(decoded);
      throw ApiException(
        statusCode: response.statusCode,
        title: title,
        detail: _problemDetail(decoded, title: title),
        errorCode: _problemString(decoded, 'errorCode'),
        retryable: _problemBool(decoded, 'retryable'),
        retryAfterSeconds: _problemInt(decoded, 'retryAfterSeconds'),
        relatedClientRequestId: _problemString(
          decoded,
          'relatedClientRequestId',
        ),
        correlationId:
            _problemString(decoded, 'correlationId') ??
            _responseCorrelationId(response),
        recoveryState: _problemString(decoded, 'recoveryState'),
        recommendedAction: _problemString(decoded, 'recommendedAction'),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      title: 'Istek basarisiz',
      detail: response.body.isEmpty ? null : utf8.decode(response.bodyBytes),
      correlationId: _responseCorrelationId(response),
    );
  }

  String? _responseCorrelationId(http.Response response) {
    final value =
        response.headers['x-correlation-id']?.trim() ??
        response.headers['correlation-id']?.trim() ??
        '';
    return value.isEmpty ? null : value;
  }

  Object? _problemValue(JsonMap decoded, String key) {
    if (decoded.containsKey(key)) {
      return decoded[key];
    }

    final extensions = decoded['extensions'];
    if (extensions is Map) {
      return extensions[key];
    }
    return null;
  }

  String? _problemString(JsonMap decoded, String key) {
    final value = _problemValue(decoded, key)?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool? _problemBool(JsonMap decoded, String key) {
    final value = _problemValue(decoded, key);
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return switch (value.trim().toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    }
    return null;
  }

  int? _problemInt(JsonMap decoded, String key) {
    final value = _problemValue(decoded, key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _problemTitle(JsonMap decoded) {
    for (final key in const <String>['title', 'message', 'error']) {
      final value = decoded[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return 'Istek basarisiz';
  }

  String? _problemDetail(JsonMap decoded, {required String title}) {
    final parts = <String>[];

    for (final key in const <String>[
      'detail',
      'errorMessage',
      'error_description',
    ]) {
      final value = decoded[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != title) {
        parts.add(value);
      }
    }

    final errors = _flattenProblemErrors(decoded['errors']);
    if (errors.isNotEmpty) {
      parts.add(errors);
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' | ');
  }

  String _flattenProblemErrors(Object? value) {
    if (value == null) {
      return '';
    }

    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .join(' | ');
    }

    if (value is Map) {
      return value.entries
          .map((entry) {
            final key = entry.key.toString();
            final entryValue = _flattenProblemErrors(entry.value);
            if (entryValue.isEmpty) {
              return '';
            }
            return '$key: $entryValue';
          })
          .where((item) => item.isNotEmpty)
          .join(' | ');
    }

    return value.toString().trim();
  }
}
