import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String appName = 'Furpa Merkez Terminal';
  static const Duration requestTimeout = Duration(seconds: 25);
  static const String _defaultBaseUrl = 'http://192.168.254.214:7508';

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');

    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const configuredAndroid = String.fromEnvironment('API_BASE_URL_ANDROID');

      if (configuredAndroid.isNotEmpty) {
        return _normalizeBaseUrl(configuredAndroid);
      }

      return _defaultBaseUrl;
    }

    if (kIsWeb) {
      const configuredWeb = String.fromEnvironment('API_BASE_URL_WEB');

      if (configuredWeb.isNotEmpty) {
        return _normalizeBaseUrl(configuredWeb);
      }

      return _defaultBaseUrl;
    }

    const configuredDesktop = String.fromEnvironment('API_BASE_URL_DESKTOP');

    if (configuredDesktop.isNotEmpty) {
      return _normalizeBaseUrl(configuredDesktop);
    }

    return _defaultBaseUrl;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  static String? get authRefreshPath {
    const configured = String.fromEnvironment('AUTH_REFRESH_PATH');
    final trimmed = configured.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('/')) {
      return trimmed;
    }

    return '/$trimmed';
  }
}
