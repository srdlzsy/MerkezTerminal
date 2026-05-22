import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:http/http.dart' as http;

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.version,
    required this.apkUri,
  });

  final String currentVersion;
  final String version;
  final Uri apkUri;
}

class AppUpdateService {
  AppUpdateService({
    required http.Client httpClient,
    Uri? manifestUri,
    MethodChannel? channel,
  }) : _httpClient = httpClient,
       _manifestUri = manifestUri ?? Uri.parse(AppConfig.updateManifestUrl),
       _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'furpa_merkez_terminal/update';

  final http.Client _httpClient;
  final Uri _manifestUri;
  final MethodChannel _channel;

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final currentVersion = await _currentVersion();
    if (currentVersion == null || currentVersion.trim().isEmpty) {
      return null;
    }

    final response = await _httpClient
        .get(_manifestUri)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppUpdateException(
        'Guncelleme bilgisi okunamadi. HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const AppUpdateException('Guncelleme cevabi gecersiz.');
    }

    final remoteVersion = decoded['version'];
    final apk = decoded['apk'];
    if (remoteVersion is! String ||
        remoteVersion.trim().isEmpty ||
        apk is! String ||
        apk.trim().isEmpty) {
      throw const AppUpdateException('Guncelleme bilgisi eksik.');
    }

    final apkUri = Uri.tryParse(apk.trim());
    if (apkUri == null || !apkUri.hasScheme || apkUri.host.isEmpty) {
      throw const AppUpdateException('APK adresi gecersiz.');
    }

    if (_compareVersions(remoteVersion, currentVersion) <= 0) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      version: remoteVersion.trim(),
      apkUri: apkUri,
    );
  }

  Future<bool> downloadAndInstall(AppUpdateInfo updateInfo) async {
    final openedInstaller = await _channel
        .invokeMethod<bool>('downloadAndInstallApk', <String, Object?>{
          'url': updateInfo.apkUri.toString(),
          'fileName': 'furpa-terminal-${updateInfo.version}.apk',
        });

    return openedInstaller ?? false;
  }

  Future<String?> _currentVersion() async {
    try {
      return await _channel.invokeMethod<String>('getAppVersion');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static int _compareVersions(String left, String right) {
    final leftParts = _parseVersionParts(left);
    final rightParts = _parseVersionParts(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index += 1) {
      final leftPart = index < leftParts.length ? leftParts[index] : 0;
      final rightPart = index < rightParts.length ? rightParts[index] : 0;

      if (leftPart != rightPart) {
        return leftPart.compareTo(rightPart);
      }
    }

    return 0;
  }

  static List<int> _parseVersionParts(String value) {
    final normalized = value.trim().split('+').first.split('-').first;

    return normalized
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')))
        .map((part) => part ?? 0)
        .toList(growable: false);
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
