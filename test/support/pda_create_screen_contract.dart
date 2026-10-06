import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PdaCreateScreenScenario {
  const PdaCreateScreenScenario({
    required this.name,
    required this.size,
    this.keyboardInset = 0,
    this.textScale = 1,
    this.hideKeyboardBeforeSave = false,
  });

  final String name;
  final Size size;
  final double keyboardInset;
  final double textScale;
  final bool hideKeyboardBeforeSave;
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
      PdaCreateScreenScenario(
        name: '320x568 keyboard',
        size: Size(320, 568),
        keyboardInset: 200,
        hideKeyboardBeforeSave: true,
      ),
      PdaCreateScreenScenario(
        name: '320x640 buyuk yazi',
        size: Size(320, 640),
        textScale: 1.2,
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
      final subject = buildSubject();

      Widget buildFrame(double keyboardInset) {
        return MaterialApp(
          key: ValueKey<String>(scenario.name),
          home: MediaQuery(
            data: MediaQueryData(
              size: scenario.size,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
              textScaler: TextScaler.linear(scenario.textScale),
            ),
            child: Scaffold(body: subject),
          ),
        );
      }

      await tester.pumpWidget(buildFrame(0));
      await tester.pumpAndSettle();

      if (prepare != null) {
        await prepare(tester);
        await tester.pumpAndSettle();
      }

      if (scenario.keyboardInset > 0) {
        await tester.pumpWidget(buildFrame(scenario.keyboardInset));
        await tester.pumpAndSettle();
      }

      final layoutException = tester.takeException();
      expect(
        layoutException,
        isNull,
        reason: '${scenario.name}: create ekrani overflow/hata vermemeli.',
      );
      expect(
        entryRowFinder,
        findsWidgets,
        reason: '${scenario.name}: giris satiri gorunur kalmali.',
      );
      expect(
        entryRowFinder.hitTestable(),
        findsWidgets,
        reason:
            '${scenario.name}: giris satiri ekranda gorunur ve dokunulabilir olmali.',
      );
      expect(
        find.ancestor(
          of: entryRowFinder.first,
          matching: find.byType(Scrollable),
        ),
        findsNothing,
        reason:
            '${scenario.name}: giris paneli kaydirma alaninin disinda sabit kalmali.',
      );
      expect(
        find.byType(Scrollable),
        findsWidgets,
        reason:
            '${scenario.name}: kalem/kaydet bolgesi scroll edilebilir olmali.',
      );

      if (scenario.hideKeyboardBeforeSave && scenario.keyboardInset > 0) {
        await tester.pumpWidget(buildFrame(0));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${scenario.name}: klavye kapandiktan sonra create ekrani hata vermemeli.',
        );
        expect(
          entryRowFinder.hitTestable(),
          findsWidgets,
          reason:
              '${scenario.name}: klavye kapandiktan sonra giris satiri kullanilabilir kalmali.',
        );
      }

      final entryTopBeforeListScroll = tester
          .getTopLeft(entryRowFinder.first)
          .dy;

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
        saveButtonFinder.hitTestable(),
        findsWidgets,
        reason:
            '${scenario.name}: kaydet butonu ekranda gorunur ve dokunulabilir olmali.',
      );
      expect(
        entryRowFinder.hitTestable(),
        findsWidgets,
        reason:
            '${scenario.name}: scroll/klavye sonrasinda giris satiri gorunur ve dokunulabilir kalmali.',
      );
      expect(
        tester.getTopLeft(entryRowFinder.first).dy,
        closeTo(entryTopBeforeListScroll, 1),
        reason:
            '${scenario.name}: kalem listesi kayarken giris paneli yer degistirmemeli.',
      );
    }
  } finally {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
