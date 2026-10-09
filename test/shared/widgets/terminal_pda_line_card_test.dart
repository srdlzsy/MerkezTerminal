import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
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
