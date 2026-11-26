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

  testWidgets(
    'clears stale max error when linked dispatch and accepted quantities increase together',
    (tester) async {
      final dispatchController = TextEditingController(text: '5');
      final acceptedController = TextEditingController(text: '5');
      addTearDown(() {
        dispatchController.dispose();
        acceptedController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                final dispatchMax =
                    double.tryParse(dispatchController.text) ?? 0;
                return Form(
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    children: <Widget>[
                      TerminalQuantityStepper(
                        controller: dispatchController,
                        label: 'Irs. Miktar*',
                        onChanged: (value) {
                          acceptedController.text = value;
                          setState(() {});
                        },
                      ),
                      TerminalQuantityStepper(
                        controller: acceptedController,
                        label: 'Fiili Miktar*',
                        maximum: dispatchMax,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '+' on Irs. Miktar* (5 -> 6): Fiili Miktar* syncs to 6 before setState.
      await tester.tap(find.byTooltip('Artir').first);
      await tester.pumpAndSettle();

      expect(dispatchController.text, '6');
      expect(acceptedController.text, '6');
      expect(find.text('En fazla 5'), findsNothing);
    },
  );
}
