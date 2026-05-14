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
  ApiClient({required String baseUrl, required http.Client httpClient})
    : _baseUri = Uri.parse(baseUrl),
      _httpClient = httpClient;

  final Uri _baseUri;
  final http.Client _httpClient;
  AccessTokenProvider? _accessTokenProvider;
  UnauthorizedRecoveryHandler? _unauthorizedRecoveryHandler;

  void configureAuthentication({
    AccessTokenProvider? accessTokenProvider,
    UnauthorizedRecoveryHandler? unauthorizedRecoveryHandler,
  }) {
    _accessTokenProvider = accessTokenProvider;
    _unauthorizedRecoveryHandler = unauthorizedRecoveryHandler;
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
  }) async {
    final response = await _send(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      request: (resolvedAccessToken) => _httpClient.post(
        _buildUri(path, queryParameters: queryParameters),
        headers: _buildHeaders(accessToken: resolvedAccessToken),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    return _decodeJsonMap(response);
  }

  Future<JsonMap> putJsonMap(
    String path, {
    String? accessToken,
    Object? body,
    Map<String, String>? queryParameters,
    bool allowUnauthorizedRecovery = true,
  }) async {
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
    final contentTypeHeader = switch (contentType) {
      final value? => <String, String>{'Content-Type': value},
      null => null,
    };
    final authorizationHeader = switch (accessToken) {
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
    required Future<http.Response> Function(String? resolvedAccessToken)
    request,
  }) async {
    return _sendWithRecovery(
      accessToken: accessToken,
      allowUnauthorizedRecovery: allowUnauthorizedRecovery,
      hasRetriedUnauthorized: false,
      request: request,
    );
  }

  Future<http.Response> _sendWithRecovery({
    required String? accessToken,
    required bool allowUnauthorizedRecovery,
    required bool hasRetriedUnauthorized,
    required Future<http.Response> Function(String? resolvedAccessToken)
    request,
  }) async {
    final resolvedAccessToken = _resolveAccessToken(accessToken);

    try {
      final response = await request(
        resolvedAccessToken,
      ).timeout(AppConfig.requestTimeout);

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
    final provided = _accessTokenProvider?.call()?.trim() ?? '';
    if (provided.isNotEmpty) {
      return provided;
    }

    final requested = requestedAccessToken?.trim() ?? '';
    if (requested.isEmpty) {
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
    final normalized = recovered?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
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
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      title: 'Istek basarisiz',
      detail: response.body.isEmpty ? null : utf8.decode(response.bodyBytes),
    );
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
