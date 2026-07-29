import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/update/app_update_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('furpa_merkez_terminal/update');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'checkForUpdate returns remote APK when manifest version is newer',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAppVersion') {
              return '1.1.20';
            }
            return null;
          });

      final service = AppUpdateService(
        httpClient: MockClient((request) async {
          expect(request.url.toString(), 'http://updates.test/version.json');
          return http.Response(
            '{"version":"1.1.21","apk":"http://updates.test/app-release.apk"}',
            200,
          );
        }),
        manifestUri: Uri.parse('http://updates.test/version.json'),
        channel: channel,
      );

      final updateInfo = await service.checkForUpdate();

      expect(updateInfo?.currentVersion, '1.1.20');
      expect(updateInfo?.version, '1.1.21');
      expect(
        updateInfo?.apkUri.toString(),
        'http://updates.test/app-release.apk',
      );
    },
  );

  test(
    'downloadAndInstall sends sanitized update file request to channel',
    () async {
      Object? sentArguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'downloadAndInstallApk');
            sentArguments = call.arguments;
            return true;
          });

      final service = AppUpdateService(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        manifestUri: Uri.parse('http://updates.test/version.json'),
        channel: channel,
      );

      final opened = await service.downloadAndInstall(
        AppUpdateInfo(
          currentVersion: '1.1.20',
          version: '1.1.21 beta/terminal',
          apkUri: Uri.parse('http://updates.test/app-release.apk'),
        ),
      );

      expect(opened, isTrue);
      final arguments = sentArguments as Map<Object?, Object?>;
      expect(arguments['url'], 'http://updates.test/app-release.apk');
      expect(arguments['fileName'], 'furpa-terminal-1.1.21_beta_terminal.apk');
      expect(arguments['requestId'], isA<String>());
    },
  );

  test('checkForUpdate skips invalid manifest URL', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAppVersion') {
            return '1.1.20';
          }
          return null;
        });

    final service = AppUpdateService(
      httpClient: MockClient((request) async {
        fail('Invalid manifest URL should not be requested.');
      }),
      manifestUri: Uri.parse('/version.json'),
      channel: channel,
    );

    expect(await service.checkForUpdate(), isNull);
  });
}
