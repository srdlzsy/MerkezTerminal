import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

void main() {
  testWidgets('startup lockup stays compact and does not decode the old logo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: FurpaStartupLockup())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('FURPA'), findsOneWidget);
    expect(find.text('MERKEZ TERMINAL'), findsOneWidget);
    expect(find.byType(FurpaStartupMark), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(FurpaStartupLockup).hitTestable(), findsOneWidget);
  });
}
