import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets(
    'product lookup field selects on focus and places cursor on tap',
    (tester) async {
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

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, controller.text.length);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
        TextInputType.text,
      );
    },
  );

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

    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, controller.text.length);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );
  });

  testWidgets('product draft entry panel fits compact terminal height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final quantityController = TextEditingController(text: '1');
    final lookupController = TextEditingController();
    addTearDown(quantityController.dispose);
    addTearDown(lookupController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: ProductDraftEntryPanel(
              stockCode: 'STK-001',
              stockName: 'Cok Uzun Test Urunu PDA Panel Denemesi',
              quantityController: quantityController,
              unitLabel: 'ADET',
              barcode: '8690000000012',
              packageLabel: '12',
              priceLabel: '10,00',
              scanRow: TerminalResponsiveLookupRow(
                field: ProductLookupField(
                  controller: lookupController,
                  onSubmit: () {},
                ),
                action: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Urun'),
                ),
                trailingAction: IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_back_rounded),
                ),
              ),
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Barkod / stok kodu / urun adi'), findsOneWidget);
    expect(find.text('Kaleme Ekle'), findsOneWidget);
    expect(
      tester
          .getBottomRight(find.widgetWithText(FilledButton, 'Kaleme Ekle'))
          .dy,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets('terminal create input dock stays fixed without nested scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 460),
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: Scaffold(
            body: SizedBox(
              height: 220,
              child: TerminalCreateInputDock(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const SizedBox(height: 54),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Kaleme Ekle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Kaleme Ekle'), findsOneWidget);
    expect(
      tester
          .getBottomRight(find.widgetWithText(FilledButton, 'Kaleme Ekle'))
          .dy,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets('compact product line shows product identity and package info', (
    tester,
  ) async {
    final quantityController = TextEditingController(text: '12');
    addTearDown(quantityController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TerminalCompactProductLineCard(
              lineNo: 1,
              stockCode: '015792',
              stockName: 'Cok Uzun Test Urunu Manav Koli Denemesi',
              quantityController: quantityController,
              unitLabel: 'ADET',
              packageLabel: '12',
              barcode: '8690000000012',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('Cok Uzun Test Urunu Manav Koli Denemesi'),
      findsOneWidget,
    );
    expect(find.text('015792'), findsOneWidget);
    expect(find.text('Koli ici 12'), findsOneWidget);
  });
}
