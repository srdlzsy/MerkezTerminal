import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('product lookup field selects old text when focus returns', (
    tester,
  ) async {
    final controller = TextEditingController(text: '8690000000012');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductLookupField(
            controller: controller,
            focusNode: focusNode,
            onSubmit: () {},
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, controller.text.length);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );
  });

  testWidgets('terminal lookup search field autofocuses and selects query', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'test urun');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TerminalLookupSearchField(
            controller: controller,
            onSearch: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, controller.text.length);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );
  });
}
