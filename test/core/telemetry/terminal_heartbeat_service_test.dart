import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/telemetry/terminal_heartbeat_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 10, 8, 8);
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('sends once and throttles the same build for six hours', () async {
    final requests = <http.Request>[];
    final provider = _FakeDeviceInfoProvider(_deviceInfo(buildNumber: 91));
    final service = TerminalHeartbeatService(
      apiClient: _apiClient(requests),
      deviceInfoProvider: provider,
      utcNow: () => now,
    );

    expect(await service.sendIfDue(), isTrue);
    expect(await service.sendIfDue(), isFalse);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/api/terminal-installations/heartbeat');
    expect(jsonDecode(requests.single.body), containsPair('buildNumber', 91));

    now = now.add(const Duration(hours: 6));
    expect(await service.sendIfDue(), isTrue);
    expect(requests, hasLength(2));
  });

  test('sends immediately when the installed build changes', () async {
    final requests = <http.Request>[];
    final provider = _FakeDeviceInfoProvider(_deviceInfo(buildNumber: 91));
    final service = TerminalHeartbeatService(
      apiClient: _apiClient(requests),
      deviceInfoProvider: provider,
      utcNow: () => now,
    );

    expect(await service.sendIfDue(), isTrue);
    provider.info = _deviceInfo(buildNumber: 92, version: '1.1.91');
    expect(await service.sendIfDue(), isTrue);
    expect(requests, hasLength(2));
  });

  test('connection failures do not escape to the application', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5228',
      httpClient: MockClient(
        (_) async => throw http.ClientException('offline'),
      ),
    )..configureAuthentication(accessTokenProvider: () => 'access-token');
    final service = TerminalHeartbeatService(
      apiClient: client,
      deviceInfoProvider: _FakeDeviceInfoProvider(_deviceInfo(buildNumber: 91)),
      utcNow: () => now,
    );

    expect(await service.sendIfDue(), isFalse);
  });
}

ApiClient _apiClient(List<http.Request> requests) {
  final client = ApiClient(
    baseUrl: 'http://localhost:5228',
    httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 200);
    }),
  );
  client.configureAuthentication(accessTokenProvider: () => 'access-token');
  return client;
}

TerminalDeviceInfo _deviceInfo({
  required int buildNumber,
  String version = '1.1.90',
}) => TerminalDeviceInfo(
  appVersion: version,
  buildNumber: buildNumber,
  manufacturer: 'Zebra',
  deviceModel: 'TC21',
  androidVersion: '13',
  androidSdk: 33,
  supportedAbis: const <String>['arm64-v8a'],
);

class _FakeDeviceInfoProvider implements TerminalDeviceInfoProvider {
  _FakeDeviceInfoProvider(this.info);

  TerminalDeviceInfo? info;

  @override
  Future<TerminalDeviceInfo?> read() async => info;
}
