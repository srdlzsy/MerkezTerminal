import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('offers copy action when an error contains a support code', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TerminalMessageBlock.error(
            message: 'Kayit tamamlanamadi.\nDestek kodu: trace-123',
          ),
        ),
      ),
    );

    final copyButton = find.byTooltip('Destek kodunu kopyala');
    expect(copyButton, findsOneWidget);

    await tester.tap(copyButton);
    await tester.pump();

    expect(find.text('Destek kodu kopyalandi.'), findsOneWidget);
  });
}
