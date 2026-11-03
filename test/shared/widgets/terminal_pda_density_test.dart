import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('compact info grid keeps two columns on a narrow PDA card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: TerminalPdaInfoGrid(
                compact: true,
                items: <TerminalPdaInfo>[
                  TerminalPdaInfo(label: 'Belge', value: 'F56.100'),
                  TerminalPdaInfo(label: 'Miktar', value: '24'),
                  TerminalPdaInfo(label: 'Tarih', value: '03.11.2026'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final firstTop = tester.getTopLeft(find.text('Belge')).dy;
    final secondTop = tester.getTopLeft(find.text('Miktar')).dy;
    final thirdTop = tester.getTopLeft(find.text('Tarih')).dy;

    expect(secondTop, firstTop);
    expect(thirdTop, greaterThan(firstTop));
    expect(
      tester.getSize(find.byType(TerminalPdaInfoGrid)).height,
      lessThan(100),
    );
  });

  testWidgets('list page padding uses eight pixels on 320 width', (
    tester,
  ) async {
    const contentKey = Key('content');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 568)),
          child: Scaffold(
            body: Builder(
              builder: (context) => Padding(
                padding: terminalPdaListPagePadding(context),
                child: const SizedBox(key: contentKey, width: 20, height: 20),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(contentKey)), const Offset(8, 8));
  });

  testWidgets('dense frameless section uses less vertical space', (
    tester,
  ) async {
    const childKey = Key('section-child');

    Future<double> pumpSection({
      required bool dense,
      required bool framed,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: SectionCard(
                  title: 'Evraklar',
                  subtitle: '3 kayit bulundu.',
                  dense: dense,
                  framed: framed,
                  child: const SizedBox(key: childKey, height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(childKey)).dy;
    }

    final regularChildTop = await pumpSection(dense: false, framed: true);
    final compactChildTop = await pumpSection(dense: true, framed: false);

    expect(compactChildTop, lessThan(regularChildTop));
  });
}
