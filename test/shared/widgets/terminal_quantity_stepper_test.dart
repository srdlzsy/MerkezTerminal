import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('rejects manually entered create quantity above the shared max', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '100001');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TerminalQuantityStepper(
              controller: controller,
              validator: (_) => null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('En fazla 100000'), findsOneWidget);
  });

  testWidgets('accepts the documented maximum create quantity', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '100000');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TerminalQuantityStepper(controller: controller),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
  });
}
