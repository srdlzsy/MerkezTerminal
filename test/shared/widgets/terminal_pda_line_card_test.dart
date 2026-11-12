import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('puts product name before line number on compact cards', (
    tester,
  ) async {
    const stockName = 'MNV DOMATES SALKIM KG';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TerminalPdaLineCard(
              title: 'Satir 1',
              subtitle: stockName,
              trailing: TerminalLineDeleteButton(onPressed: () {}),
              child: const Text('Miktar bilgileri'),
            ),
          ),
        ),
      ),
    );

    final productName = tester.widget<Text>(find.text(stockName));
    final lineLabel = tester.widget<Text>(find.text('Satir 1'));

    expect(productName.maxLines, 2);
    expect(productName.style?.fontWeight, FontWeight.w900);
    expect(lineLabel.style?.fontWeight, FontWeight.w700);
    expect(find.widgetWithText(FilledButton, 'Sil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows full product title when requested on terminal width', (
    tester,
  ) async {
    const stockName =
        'KARLIDAG 750GR TUZLU TEREYAG COK UZUN STOK KARTI ACIKLAMASI';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TerminalPdaLineCard(
              title: stockName,
              showFullTitle: true,
              trailing: Icon(Icons.check_circle_outline_rounded),
              child: Text('Satir bilgileri'),
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text(stockName));
    expect(title.maxLines, isNull);
    expect(title.overflow, TextOverflow.visible);
    expect(tester.takeException(), isNull);
  });
}
