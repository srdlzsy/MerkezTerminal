import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PdaCreateScreenScenario {
  const PdaCreateScreenScenario({
    required this.name,
    required this.size,
    this.keyboardInset = 0,
  });

  final String name;
  final Size size;
  final double keyboardInset;
}

const List<PdaCreateScreenScenario> defaultPdaCreateScreenScenarios =
    <PdaCreateScreenScenario>[
      PdaCreateScreenScenario(name: '320x640', size: Size(320, 640)),
      PdaCreateScreenScenario(name: '360x640', size: Size(360, 640)),
      PdaCreateScreenScenario(
        name: '320x640 keyboard',
        size: Size(320, 640),
        keyboardInset: 220,
      ),
    ];

Future<void> expectPdaCreateScreenContract(
  WidgetTester tester, {
  required Widget Function() buildSubject,
  required Finder entryRowFinder,
  required Finder saveButtonFinder,
  Future<void> Function(WidgetTester tester)? prepare,
  Iterable<PdaCreateScreenScenario> scenarios = defaultPdaCreateScreenScenarios,
}) async {
  try {
    for (final scenario in scenarios) {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: scenario.size,
              viewInsets: EdgeInsets.only(bottom: scenario.keyboardInset),
            ),
            child: Scaffold(body: buildSubject()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (prepare != null) {
        await prepare(tester);
        await tester.pumpAndSettle();
      }

      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.name}: create ekrani overflow/hata vermemeli.',
      );
      expect(
        entryRowFinder,
        findsWidgets,
        reason: '${scenario.name}: giris satiri gorunur kalmali.',
      );
      expect(
        find.byType(Scrollable),
        findsWidgets,
        reason:
            '${scenario.name}: kalem/kaydet bolgesi scroll edilebilir olmali.',
      );

      await tester.ensureVisible(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.name}: kaydet butonuna inerken overflow olmamali.',
      );
      expect(
        saveButtonFinder,
        findsWidgets,
        reason: '${scenario.name}: kaydet butonu erisilebilir olmali.',
      );
      expect(
        entryRowFinder,
        findsWidgets,
        reason:
            '${scenario.name}: scroll/klavye sonrasinda giris satiri kaybolmamali.',
      );
    }
  } finally {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
