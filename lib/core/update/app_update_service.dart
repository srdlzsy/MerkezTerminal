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
    this.currentBuildNumber,
    this.buildNumber,
    this.apkAbi,
  });

  final String currentVersion;
  final String version;
  final Uri apkUri;
  final int? currentBuildNumber;
  final int? buildNumber;
  final String? apkAbi;
}

typedef AppUpdateProgressCallback =
    void Function(AppUpdateDownloadProgress progress);

class AppUpdateDownloadProgress {
  const AppUpdateDownloadProgress({
    required this.bytesRead,
    required this.totalBytes,
  });

  final int bytesRead;
  final int totalBytes;

  bool get hasTotal => totalBytes > 0;

  double? get fraction {
    if (!hasTotal) {
      return null;
    }

    return (bytesRead / totalBytes).clamp(0, 1).toDouble();
  }
}

class AppUpdateService {
  AppUpdateService({
    required http.Client httpClient,
    Uri? manifestUri,
    MethodChannel? channel,
  }) : _httpClient = httpClient,
       _manifestUri = manifestUri ?? Uri.parse(AppConfig.updateManifestUrl),
       _channel = channel ?? const MethodChannel(_channelName) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const String _channelName = 'furpa_merkez_terminal/update';

  final http.Client _httpClient;
  final Uri _manifestUri;
  final MethodChannel _channel;
  final Map<String, AppUpdateProgressCallback> _progressCallbacks =
      <String, AppUpdateProgressCallback>{};

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    if (!_isAbsoluteHttpUri(_manifestUri)) {
      return null;
    }

    final installed = await _currentVersionInfo();
    if (installed == null || installed.version.trim().isEmpty) {
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
    if (remoteVersion is! String || remoteVersion.trim().isEmpty) {
      throw const AppUpdateException('Guncelleme bilgisi eksik.');
    }

    final remoteBuildNumber = _readManifestBuildNumber(decoded);
    final apkSelection = await _selectApk(decoded);
    if (apkSelection == null || !_isAbsoluteHttpUri(apkSelection.uri)) {
      throw const AppUpdateException('APK adresi gecersiz.');
    }

    final hasNewerBuild =
        remoteBuildNumber != null && installed.buildNumber != null
        ? remoteBuildNumber > installed.buildNumber!
        : _compareVersions(remoteVersion, installed.version) > 0;
    if (!hasNewerBuild) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: installed.version,
      version: remoteVersion.trim(),
      apkUri: apkSelection.uri,
      currentBuildNumber: installed.buildNumber,
      buildNumber: remoteBuildNumber,
      apkAbi: apkSelection.abi,
    );
  }

  Future<bool> downloadAndInstall(
    AppUpdateInfo updateInfo, {
    AppUpdateProgressCallback? onProgress,
  }) async {
    final requestId =
        'apk-${DateTime.now().microsecondsSinceEpoch}-${updateInfo.version.hashCode}';
    if (onProgress != null) {
      _progressCallbacks[requestId] = onProgress;
    }

    final openedInstaller = await _channel
        .invokeMethod<bool>('downloadAndInstallApk', <String, Object?>{
          'url': updateInfo.apkUri.toString(),
          'fileName': _updateFileName(updateInfo.version, updateInfo.apkAbi),
          'requestId': requestId,
          'expectedVersion': updateInfo.version,
          'expectedVersionCode': updateInfo.buildNumber,
          'installedVersionCode': updateInfo.currentBuildNumber,
        })
        .whenComplete(() {
          _progressCallbacks.remove(requestId);
        });

    return openedInstaller ?? false;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'downloadProgress') {
      return;
    }

    final arguments = call.arguments;
    if (arguments is! Map) {
      return;
    }

    final requestId = arguments['requestId']?.toString();
    if (requestId == null || requestId.isEmpty) {
      return;
    }

    final callback = _progressCallbacks[requestId];
    if (callback == null) {
      return;
    }

    callback(
      AppUpdateDownloadProgress(
        bytesRead: _readInt(arguments['bytesRead']),
        totalBytes: _readInt(arguments['totalBytes']),
      ),
    );
  }

  Future<_InstalledAppVersion?> _currentVersionInfo() async {
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'getAppVersionInfo',
      );
      final version = response?['versionName']?.toString().trim() ?? '';
      if (version.isNotEmpty) {
        return _InstalledAppVersion(
          version: version,
          buildNumber: _readNullableInt(response?['versionCode']),
        );
      }
    } on MissingPluginException {
      // Eski native katman ile geriye uyumluluk icin devam et.
    } on PlatformException {
      // Eski native katman ile geriye uyumluluk icin devam et.
    }

    try {
      final version = await _channel.invokeMethod<String>('getAppVersion');
      if (version == null || version.trim().isEmpty) {
        return null;
      }
      return _InstalledAppVersion(version: version.trim());
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<List<String>> _supportedAbis() async {
    try {
      final abis = await _channel.invokeListMethod<String>('getSupportedAbis');
      return abis
              ?.map((abi) => abi.trim())
              .where((abi) => abi.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
    } on MissingPluginException {
      return const <String>[];
    } on PlatformException {
      return const <String>[];
    }
  }

  Future<_SelectedUpdateApk?> _selectApk(Map<String, Object?> manifest) async {
    final supportedAbis = await _supportedAbis();
    final abiApks = _readAbiApkMap(manifest);
    for (final abi in supportedAbis) {
      final uri = _readHttpUri(abiApks[abi]);
      if (uri != null) {
        return _SelectedUpdateApk(uri: uri, abi: abi);
      }
    }

    final fallbackUri = _readHttpUri(_readFallbackApk(manifest));
    if (fallbackUri != null) {
      return _SelectedUpdateApk(uri: fallbackUri);
    }

    return null;
  }

  static Map<String, Object?> _readAbiApkMap(Map<String, Object?> manifest) {
    final android = manifest['android'];
    final candidates = <Object?>[
      if (android is Map) android['apks'],
      if (android is Map) android['apkByAbi'],
      if (android is Map) android['apksByAbi'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        return candidate.map(
          (key, value) => MapEntry(key.toString().trim(), value),
        )..removeWhere((key, _) => key.isEmpty);
      }
    }

    if (android is Map) {
      return android.map((key, value) => MapEntry(key.toString().trim(), value))
        ..removeWhere(
          (key, value) =>
              key.isEmpty ||
              key == 'apk' ||
              key == 'universal' ||
              key == 'universalUrl',
        );
    }

    return const <String, Object?>{};
  }

  static Object? _readFallbackApk(Map<String, Object?> manifest) {
    final android = manifest['android'];
    if (android is Map) {
      final apk = android['apk'];
      if (apk is String && apk.trim().isNotEmpty) {
        return apk;
      }

      final universalUrl = android['universalUrl'];
      if (universalUrl is String && universalUrl.trim().isNotEmpty) {
        return universalUrl;
      }

      final universal = android['universal'];
      if (universal is String && universal.trim().isNotEmpty) {
        return universal;
      }
    }

    return manifest['apk'];
  }

  static int? _readManifestBuildNumber(Map<String, Object?> manifest) {
    final android = manifest['android'];
    return _readNullableInt(manifest['buildNumber']) ??
        _readNullableInt(manifest['versionCode']) ??
        (android is Map
            ? _readNullableInt(android['buildNumber']) ??
                  _readNullableInt(android['versionCode'])
            : null);
  }

  static Uri? _readHttpUri(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || !_isAbsoluteHttpUri(uri)) {
      return null;
    }

    return uri;
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

  static bool _isAbsoluteHttpUri(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty;
  }

  static String _updateFileName(String version, String? apkAbi) {
    final safeVersion = version
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceFirst(RegExp(r'^_+'), '')
        .replaceFirst(RegExp(r'_+$'), '');
    final suffix = safeVersion.isEmpty ? 'update' : safeVersion;
    final safeAbi =
        apkAbi
            ?.trim()
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
            .replaceFirst(RegExp(r'^_+'), '')
            .replaceFirst(RegExp(r'_+$'), '') ??
        '';
    final abiSuffix = safeAbi.isEmpty ? '' : '-$safeAbi';
    return 'furpa-terminal-$suffix$abiSuffix.apk';
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString().trim());
  }
}

class _InstalledAppVersion {
  const _InstalledAppVersion({required this.version, this.buildNumber});

  final String version;
  final int? buildNumber;
}

class _SelectedUpdateApk {
  const _SelectedUpdateApk({required this.uri, this.abi});

  final Uri uri;
  final String? abi;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
