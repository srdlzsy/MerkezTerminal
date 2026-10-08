import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalDeviceInfo {
  const TerminalDeviceInfo({
    required this.appVersion,
    required this.buildNumber,
    required this.supportedAbis,
    this.manufacturer,
    this.deviceModel,
    this.androidVersion,
    this.androidSdk,
  });

  final String appVersion;
  final int buildNumber;
  final String? manufacturer;
  final String? deviceModel;
  final String? androidVersion;
  final int? androidSdk;
  final List<String> supportedAbis;

  Map<String, Object?> toJson() => <String, Object?>{
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'manufacturer': manufacturer,
    'deviceModel': deviceModel,
    'androidVersion': androidVersion,
    'androidSdk': androidSdk,
    'supportedAbis': supportedAbis,
  };
}

abstract interface class TerminalDeviceInfoProvider {
  Future<TerminalDeviceInfo?> read();
}

class AndroidTerminalDeviceInfoProvider implements TerminalDeviceInfoProvider {
  const AndroidTerminalDeviceInfoProvider({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'furpa_merkez_terminal/update';
  final MethodChannel _channel;

  @override
  Future<TerminalDeviceInfo?> read() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getTerminalDeviceInfo',
    );
    final version = raw?['appVersion']?.toString().trim() ?? '';
    final buildNumber = _asInt(raw?['buildNumber']);
    if (version.isEmpty || buildNumber == null || buildNumber <= 0) {
      return null;
    }

    return TerminalDeviceInfo(
      appVersion: version,
      buildNumber: buildNumber,
      manufacturer: _asText(raw?['manufacturer']),
      deviceModel: _asText(raw?['deviceModel']),
      androidVersion: _asText(raw?['androidVersion']),
      androidSdk: _asInt(raw?['androidSdk']),
      supportedAbis: switch (raw?['supportedAbis']) {
        final List<Object?> values =>
          values
              .map((value) => value?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
        _ => const <String>[],
      },
    );
  }

  static int? _asInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  static String? _asText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class TerminalHeartbeatService {
  TerminalHeartbeatService({
    required ApiClient apiClient,
    TerminalDeviceInfoProvider? deviceInfoProvider,
    SharedPreferencesAsync? preferences,
    DateTime Function()? utcNow,
  }) : _apiClient = apiClient,
       _deviceInfoProvider =
           deviceInfoProvider ?? const AndroidTerminalDeviceInfoProvider(),
       _preferences = preferences ?? SharedPreferencesAsync(),
       _utcNow = utcNow ?? DateTime.now;

  static const Duration heartbeatInterval = Duration(hours: 6);
  static const String _lastSentAtKey = 'installation.heartbeat.lastSentAtUtc';
  static const String _lastBuildKey = 'installation.heartbeat.lastBuildNumber';
  static const String _lastVersionKey = 'installation.heartbeat.lastVersion';

  final ApiClient _apiClient;
  final TerminalDeviceInfoProvider _deviceInfoProvider;
  final SharedPreferencesAsync _preferences;
  final DateTime Function() _utcNow;
  Future<bool>? _activeRequest;

  Future<bool> sendIfDue({bool force = false}) {
    final activeRequest = _activeRequest;
    if (activeRequest != null) {
      return activeRequest;
    }

    final request = _sendIfDue(force: force);
    _activeRequest = request;
    return request.whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    });
  }

  Future<bool> _sendIfDue({required bool force}) async {
    try {
      final info = await _deviceInfoProvider.read();
      if (info == null) {
        return false;
      }

      final lastBuild = await _preferences.getInt(_lastBuildKey);
      final lastVersion =
          (await _preferences.getString(_lastVersionKey))?.trim() ?? '';
      final versionChanged =
          lastBuild != info.buildNumber || lastVersion != info.appVersion;
      if (!force && !versionChanged && !await _intervalElapsed()) {
        return false;
      }

      await _apiClient.postJsonMap(
        '/api/terminal-installations/heartbeat',
        body: info.toJson(),
        verifyWarehouseContext: false,
      );

      final now = _utcNow().toUtc();
      await _preferences.setString(_lastSentAtKey, now.toIso8601String());
      await _preferences.setInt(_lastBuildKey, info.buildNumber);
      await _preferences.setString(_lastVersionKey, info.appVersion);
      return true;
    } on Object {
      // Telemetry must never block login, offline mode, or business operations.
      return false;
    }
  }

  Future<bool> _intervalElapsed() async {
    final raw = await _preferences.getString(_lastSentAtKey);
    final lastSentAt = DateTime.tryParse(raw ?? '')?.toUtc();
    if (lastSentAt == null) {
      return true;
    }
    return _utcNow().toUtc().difference(lastSentAt) >= heartbeatInterval;
  }
}
