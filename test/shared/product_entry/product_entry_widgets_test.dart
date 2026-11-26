import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      expect(tester.testTextInput.isVisible, isTrue);
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, controller.text.length);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
        TextInputType.text,
      );

      tester.testTextInput.hide();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.pump();

      expect(tester.testTextInput.isVisible, isTrue);
    },
  );

  for (final submitKey in <LogicalKeyboardKey>[
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.tab,
  ]) {
    testWidgets('scanner keeps full barcode and submits once with $submitKey', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      var submitCount = 0;
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductLookupField(
              controller: controller,
              focusNode: focusNode,
              onSubmit: () => submitCount += 1,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '8690000000012');
      await tester.sendKeyEvent(submitKey);
      await tester.pump();

      expect(controller.text, '8690000000012');
      expect(submitCount, 1);
    });
  }

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

    expect(tester.testTextInput.isVisible, isTrue);
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, controller.text.length);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );

    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
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
              informationLabels: const <String>['MANAV DEPO 56', 'Depo Urunu'],
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
                  tooltip: 'Kamera ile oku',
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
    expect(find.text('Barkod / stok / urun'), findsOneWidget);
    expect(find.text('Koli ici: 12 ADET'), findsOneWidget);
    expect(find.text('Barkod: 8690000000012'), findsOneWidget);
    expect(find.text('Fiyat: 10,00'), findsOneWidget);
    expect(find.text('DEPO'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('product-source-badge')),
      findsOneWidget,
    );
    expect(find.text('STK-001 | ADET'), findsOneWidget);
    expect(find.text('Oku'), findsOneWidget);
    expect(find.text('Vazgec'), findsOneWidget);
    expect(find.text('Ekle'), findsOneWidget);
    expect(
      tester.getBottomRight(find.widgetWithText(FilledButton, 'Ekle')).dy,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets(
    'selected product quantity and add actions stay tappable with keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quantityController = TextEditingController(text: '12');
      final lookupController = TextEditingController(text: '8690000000012');
      addTearDown(quantityController.dispose);
      addTearDown(lookupController.dispose);
      final entryPanel = ProductDraftEntryPanel(
        stockCode: 'STK-001',
        stockName: 'Klavye Acik Test Urunu',
        quantityController: quantityController,
        unitLabel: 'ADET',
        packageLabel: '12',
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
        ),
        onConfirm: () {},
        onCancel: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              viewInsets: EdgeInsets.only(bottom: 200),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Column(
                children: <Widget>[
                  const SizedBox(height: 36),
                  TerminalCreateInputDock(
                    padding: EdgeInsets.zero,
                    compactChild: entryPanel,
                    children: const <Widget>[Text('Ust bilgiler')],
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final quantityField = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            identical(widget.controller, quantityController),
      );
      expect(quantityField.hitTestable(), findsOneWidget);
      await tester.tap(quantityField);
      await tester.pump(const Duration(milliseconds: 400));
      expect(quantityField.hitTestable(), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Ekle').hitTestable(),
        findsOneWidget,
      );
      for (final tooltip in <String>['Azalt', 'Artir']) {
        final button = find.byTooltip(tooltip);
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.getSize(button).width, greaterThanOrEqualTo(40));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(40));
      }
    },
  );

  testWidgets('product draft entry panel shows only the source type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final quantityController = TextEditingController(text: '1');
    addTearDown(quantityController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductDraftEntryPanel(
            stockCode: 'STK-099',
            stockName: 'Firma Test Urunu',
            quantityController: quantityController,
            unitLabel: 'ADET',
            informationLabels: const <String>[
              'Model 99',
              'TEST FIRMA',
              'Firma Urunu',
            ],
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('Kaynak'), findsOneWidget);
    expect(find.text('FIRMA'), findsOneWidget);
    expect(find.text('Model 99'), findsNothing);
    expect(find.text('TEST FIRMA'), findsNothing);
  });

  testWidgets('terminal create input dock fits without nested scroll', (
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
            resizeToAvoidBottomInset: false,
            body: SizedBox(
              height: 220,
              child: TerminalCreateInputDock(
                padding: EdgeInsets.zero,
                compactChild: FilledButton(
                  onPressed: () {},
                  child: const Text('Kaleme Ekle'),
                ),
                children: <Widget>[
                  const SizedBox(height: 54),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Miktar'), findsNothing);
    expect(find.text('Kaleme Ekle'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Kaleme Ekle').hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .getBottomRight(find.widgetWithText(FilledButton, 'Kaleme Ekle'))
          .dy,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets('input dock keeps upper field mounted while it is edited', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    Widget buildSubject(double keyboardInset) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 568),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: Scaffold(
          body: TerminalCreateInputDock(
            compactChild: const Text('Giris satiri'),
            children: <Widget>[
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Sayim Adi'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildSubject(0));

    final nameField = find.widgetWithText(TextFormField, 'Sayim Adi');
    expect(nameField.hitTestable(), findsOneWidget);
    await tester.tap(nameField);
    await tester.pump();

    await tester.pumpWidget(buildSubject(200));
    await tester.pump();

    expect(nameField.hitTestable(), findsOneWidget);
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
              highlightOnMount: true,
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
    expect(find.textContaining('015792'), findsOneWidget);
    expect(find.textContaining('Koli ici 12 ADET'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.byTooltip('Satiri sil'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Satiri sil')).width, 44);
    expect(tester.getSize(find.byTooltip('Satiri sil')).height, 44);
    expect(tester.getSize(find.byTooltip('Azalt')), const Size(48, 48));
    expect(tester.getSize(find.byTooltip('Artir')), const Size(48, 48));
    expect(find.text('ADET'), findsOneWidget);
    final highlight = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey<String>('terminal-product-line-highlight')),
    );
    expect(highlight.tween.begin, 1);
    expect(highlight.tween.end, 0);
    await tester.pump(const Duration(milliseconds: 900));
    final productName = tester.widget<Text>(
      find.byKey(const ValueKey<String>('terminal-product-line-name')),
    );
    expect(productName.style?.fontWeight, FontWeight.w900);
    expect(productName.maxLines, 2);
    expect(productName.overflow, TextOverflow.ellipsis);
  });

  testWidgets('pda product line gives product name the full row', (
    tester,
  ) async {
    final quantityController = TextEditingController(text: '12');
    addTearDown(quantityController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TerminalCompactProductLineCard(
              lineNo: 1,
              stockCode: '015792',
              stockName: 'COK UZUN VE OKUNMASI GEREKEN TEST URUNU',
              quantityController: quantityController,
              unitLabel: 'ADET',
            ),
          ),
        ),
      ),
    );

    final productName = find.byKey(
      const ValueKey<String>('terminal-product-line-name'),
    );
    final quantityField = find.byType(TextFormField);
    final deleteButton = find.byTooltip('Satiri sil');
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(quantityField).dy,
      greaterThan(tester.getBottomLeft(productName).dy),
    );
    expect(
      tester.getTopLeft(deleteButton).dy,
      lessThan(tester.getTopLeft(quantityField).dy),
    );
  });

  testWidgets('compact product line warns for non-package multiple quantity', (
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
              stockName: 'AYTAC TEST URUN',
              quantityController: quantityController,
              unitLabel: 'ADET',
              packageLabel: '12',
              barcode: '8690000000012',
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Koli ici 12 ADET; girilen miktar koli kati degil.'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();

    expect(
      find.text('Koli ici 12 ADET; girilen miktar koli kati degil.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact product line adapts metadata density by card width', (
    tester,
  ) async {
    Future<double> pumpCard(double width) async {
      final controller = TextEditingController(text: '20');
      addTearDown(controller.dispose);
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: KeyedSubtree(
                  key: key,
                  child: TerminalCompactProductLineCard(
                    lineNo: 1,
                    stockCode: '044224',
                    stockName: 'TORKU TOZ SEKER 2KG*10',
                    quantityController: controller,
                    unitLabel: 'ADET',
                    packageLabel: '10',
                    barcode: '8690120010120',
                    onDelete: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return tester.getSize(find.byKey(key)).height;
    }

    final narrowHeight = await pumpCard(304);
    final wideHeight = await pumpCard(376);

    expect(wideHeight, lessThan(narrowHeight));
    expect(narrowHeight, lessThanOrEqualTo(145));
    expect(wideHeight, lessThanOrEqualTo(130));
  });

  testWidgets('long pressing product name opens full product details dialog', (
    tester,
  ) async {
    final quantityController = TextEditingController(text: '12');
    addTearDown(quantityController.dispose);
    const fullName = 'TORKU TOZ SEKER 2KG*10 COK UZUN TAM URUN ACIKLAMASI';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 304,
            child: TerminalCompactProductLineCard(
              lineNo: 1,
              stockCode: '044224',
              stockName: fullName,
              quantityController: quantityController,
              unitLabel: 'ADET',
              packageLabel: '10',
              barcode: '8690120010120',
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.longPress(
      find.byKey(const ValueKey<String>('terminal-product-line-name')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Stok kodu: 044224'), findsOneWidget);
    expect(find.text('Barkod: 8690120010120'), findsOneWidget);
    expect(find.text('Koli ici: 10 ADET'), findsOneWidget);
  });

  testWidgets(
    'centers quantity with unit between minus and plus with visible icons',
    (tester) async {
      final quantityController = TextEditingController(text: '24');
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 304,
              child: TerminalCompactProductLineCard(
                lineNo: 1,
                stockCode: '044224',
                stockName: 'TORKU TOZ SEKER 2KG*10',
                quantityController: quantityController,
                unitLabel: 'ADET',
                packageLabel: '10',
                barcode: '8690120010120',
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);

      final minusRect = tester.getRect(find.byTooltip('Azalt'));
      final plusRect = tester.getRect(find.byTooltip('Artir'));
      final qtyRect = tester.getRect(find.byType(TextFormField));
      final unitRect = tester.getRect(find.text('ADET'));

      final controlCenterX = (minusRect.right + plusRect.left) / 2;
      final groupCenterX = (qtyRect.left + unitRect.right) / 2;

      expect((groupCenterX - controlCenterX).abs(), lessThanOrEqualTo(4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dual quantity V2 card stacks full-width steppers on PDA and shows full error',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final dispatchController = TextEditingController(text: '11');
      final acceptedController = TextEditingController(text: '15');
      addTearDown(dispatchController.dispose);
      addTearDown(acceptedController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 344,
                  child: TerminalDualQuantityProductLineCard(
                    lineNo: 1,
                    stockCode: '006541',
                    stockName: 'COCA COLA 2 LT',
                    unitLabel: 'ADET',
                    packageLabel: '6',
                    barcode: '5000112665116',
                    priceLabel: 'Net 61,46 TL | Brut 78,99 TL',
                    onDelete: () {},
                    primaryQuantity: TerminalQuantityStepper(
                      controller: dispatchController,
                      label: 'Irs. Miktar*',
                      dense: true,
                    ),
                    secondaryQuantity: TerminalQuantityStepper(
                      controller: acceptedController,
                      label: 'Fiili Miktar*',
                      maximum: 11,
                      dense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dispatchRect = tester.getRect(
        find.widgetWithText(TextFormField, 'Irs. Miktar*'),
      );
      final acceptedRect = tester.getRect(
        find.widgetWithText(TextFormField, 'Fiili Miktar*'),
      );
      expect(acceptedRect.top, greaterThan(dispatchRect.bottom));
      expect(dispatchRect.width, greaterThan(180));
      expect(acceptedRect.width, greaterThan(180));
      expect(tester.getSize(find.byTooltip('Satiri sil')), const Size(44, 44));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('En fazla 11'), findsOneWidget);
      final errorRect = tester.getRect(find.text('En fazla 11'));
      expect(errorRect.width, greaterThan(180));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProductDraftEntryPanel places full-width Vazgec + icon Ekle bar below quantity on 320 and 360 dp',
    (tester) async {
      for (final width in <double>[320, 360]) {
        final primaryController = TextEditingController(text: '12');
        final secondaryController = TextEditingController(text: '12');
        addTearDown(primaryController.dispose);
        addTearDown(secondaryController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 640)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: ProductDraftEntryPanel(
                    stockCode: '006541',
                    stockName: 'COCA COLA 2 LT ZERO SUGAR',
                    quantityController: primaryController,
                    quantityLabel: 'Irs. Miktar*',
                    secondaryQuantityController: secondaryController,
                    secondaryQuantityLabel: 'Fiili Miktar*',
                    unitLabel: 'ADET',
                    packageLabel: '6',
                    barcode: '5000112665116',
                    priceLabel: 'Net 61,46 TL | Brut 78,99 TL',
                    onConfirm: () {},
                    onCancel: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cancelBtn = find.widgetWithText(OutlinedButton, 'Vazgec');
        final addBtn = find.widgetWithText(FilledButton, 'Ekle');
        final cancelRect = tester.getRect(cancelBtn);
        final addRect = tester.getRect(addBtn);
        final qtyRect = tester.getRect(
          find.widgetWithText(TextFormField, 'Fiili Miktar*'),
        );
        final titleRect = tester.getRect(
          find.text('COCA COLA 2 LT ZERO SUGAR'),
        );

        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
        expect(titleRect.width, greaterThan(width - 80));
        expect(cancelRect.top, greaterThan(qtyRect.bottom));
        expect((cancelRect.center.dy - addRect.center.dy).abs(), lessThan(2));
        expect((cancelRect.height - addRect.height).abs(), lessThanOrEqualTo(1));
        expect(addRect.width, greaterThanOrEqualTo(140));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
