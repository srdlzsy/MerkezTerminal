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
      PdaCreateScreenScenario(name: '320x568', size: Size(320, 568)),
      PdaCreateScreenScenario(
        name: '320x640 keyboard',
        size: Size(320, 640),
        keyboardInset: 220,
        hideKeyboardBeforeSave: true,
      ),
      PdaCreateScreenScenario(
        name: '320x568 keyboard',
        size: Size(320, 568),
        keyboardInset: 180,
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
  Finder? lineItemFinder,
  Future<void> Function(WidgetTester tester)? prepare,
  Iterable<PdaCreateScreenScenario> scenarios = defaultPdaCreateScreenScenarios,
}) async {
  try {
    for (final scenario in scenarios) {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      final subject = buildSubject();

      Widget buildFrame(double keyboardInset) {
        final mediaQueryData = MediaQueryData(
          size: scenario.size,
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          textScaler: TextScaler.linear(scenario.textScale),
        );
        final visibleHeight = scenario.size.height - keyboardInset;

        return MaterialApp(
          key: ValueKey<String>(scenario.name),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: scenario.size.width,
                height: visibleHeight,
                child: MediaQuery(data: mediaQueryData, child: subject),
              ),
            ),
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
      if (lineItemFinder != null &&
          scenario.keyboardInset == 0 &&
          scenario.textScale == 1) {
        expect(
          lineItemFinder,
          findsWidgets,
          reason: '${scenario.name}: eklenen kalem listede kalmali.',
        );
        expect(
          lineItemFinder.hitTestable(),
          findsWidgets,
          reason:
              '${scenario.name}: en az bir kalem ekranda gorunur ve dokunulabilir olmali.',
        );
      }

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
        if (lineItemFinder != null) {
          expect(
            lineItemFinder,
            findsWidgets,
            reason: '${scenario.name}: eklenen kalem listede kalmali.',
          );
          expect(
            lineItemFinder.hitTestable(),
            findsWidgets,
            reason:
                '${scenario.name}: klavye kapandiginda en az bir kalem gorunur olmali.',
          );
        }
      }

      final entryTopBeforeListScroll = tester
          .getTopLeft(entryRowFinder.first)
          .dy;

      if (saveButtonFinder.evaluate().isEmpty) {
        final scrollable = find.byType(Scrollable).hitTestable().first;
        for (
          var attempt = 0;
          attempt < 20 && saveButtonFinder.evaluate().isEmpty;
          attempt += 1
        ) {
          await tester.drag(scrollable, const Offset(0, -140));
          await tester.pump();
        }
        expect(
          saveButtonFinder,
          findsWidgets,
          reason: '${scenario.name}: kaydet butonu listede bulunabilmeli.',
        );
      } else {
        await tester.ensureVisible(saveButtonFinder);
      }
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
      final saveRect = tester.getRect(saveButtonFinder.first);
      expect(
        saveRect.left,
        greaterThanOrEqualTo(0),
        reason: '${scenario.name}: kaydet butonu sol tarafta kesilmemeli.',
      );
      expect(
        saveRect.right,
        lessThanOrEqualTo(scenario.size.width),
        reason: '${scenario.name}: kaydet butonu sag tarafta kesilmemeli.',
      );
      expect(
        saveRect.top,
        greaterThanOrEqualTo(0),
        reason: '${scenario.name}: kaydet butonu ustte kesilmemeli.',
      );
      expect(
        saveRect.bottom,
        lessThanOrEqualTo(scenario.size.height),
        reason: '${scenario.name}: kaydet butonu altta kesilmemeli.',
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
