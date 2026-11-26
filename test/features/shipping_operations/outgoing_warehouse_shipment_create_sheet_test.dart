import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/widgets/outgoing_warehouse_shipment_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

import '../../support/barcode_resolution_test_data.dart';
import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('renders create sheet header fields without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Yeni Giden Depolar Arasi Sevk'), findsOneWidget);
    expect(find.text('Hedef depo no*'), findsOneWidget);
  });

  testWidgets('opens create lookup sheets on terminal width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Depo Ara'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Arama'), 'merkez');
    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Siparisli'));
    await tester.pumpAndSettle();
    await _dragShipmentCreateScroll(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Depo Siparisi Sec'), findsWidgets);
  });

  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => OutgoingWarehouseShipmentCreateSheet(
        repository: _FakeOutgoingWarehouseShipmentsRepository(),
        receivedWarehouseOrdersRepository:
            _FakeReceivedWarehouseOrdersRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileWarehouseCatalogRepository: _emptyWarehouseCatalogRepository(),
      ),
      prepare: (tester) async {
        await _pickShipmentTargetWarehouse(tester);
        await _enterShipmentBarcode(tester);
      },
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Kaydet'),
      lineItemFinder: find.text('Test Urun'),
    );
  });

  testWidgets('keeps fresh manual shipment row and merges duplicate quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await _enterShipmentBarcode(tester);

    expect(find.text('1 kalem'), findsOneWidget);
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('015792'), findsOneWidget);
    expect(find.text('KL'), findsOneWidget);
    expect(find.text('8690000000012'), findsWidgets);

    await _enterShipmentBarcode(tester);

    expect(find.text('1 kalem'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('blocks barcode-like quantity before creating shipment request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    WarehouseShipmentCreateRequest? request;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  request =
                      await showModalBottomSheet<
                        WarehouseShipmentCreateRequest
                      >(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => OutgoingWarehouseShipmentCreateSheet(
                          repository:
                              _FakeOutgoingWarehouseShipmentsRepository(),
                          receivedWarehouseOrdersRepository:
                              _FakeReceivedWarehouseOrdersRepository(),
                          accessToken: 'token',
                          defaultWarehouseNo: '110',
                          mobileWarehouseCatalogRepository:
                              _emptyWarehouseCatalogRepository(),
                          draft: _suspiciousQuantityShipmentDraft(),
                        ),
                      );
                },
                child: const Text('Ac'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();

    expect(find.text('Test Urun'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Kaydet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();

    expect(request, isNull);
    expect(find.text('Barkod miktar alaninda'), findsOneWidget);
    expect(find.text('Yeni Giden Depolar Arasi Sevk'), findsOneWidget);
  });

  testWidgets('asks before increasing non-consecutive duplicate scans', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    WarehouseShipmentCreateRequest? request;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  request =
                      await showModalBottomSheet<
                        WarehouseShipmentCreateRequest
                      >(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => OutgoingWarehouseShipmentCreateSheet(
                          repository: _FakeOutgoingWarehouseShipmentsRepository(
                            barcodeResolutionBuilder: (request) {
                              final isSecondProduct =
                                  request.barcode == '2222222222222';
                              return buildBarcodeResolutionResult(
                                barcode: request.barcode,
                                warehouseNo:
                                    int.tryParse(request.warehouseNo ?? '') ??
                                    110,
                                stockCode: isSecondProduct ? 'B002' : 'A001',
                                stockName: isSecondProduct
                                    ? 'B Urun'
                                    : 'A Urun',
                                operationType: request.operationType ?? '',
                                screenCode: request.screenCode ?? '',
                              );
                            },
                          ),
                          receivedWarehouseOrdersRepository:
                              _FakeReceivedWarehouseOrdersRepository(),
                          accessToken: 'token',
                          defaultWarehouseNo: '110',
                          mobileWarehouseCatalogRepository:
                              _emptyWarehouseCatalogRepository(),
                        ),
                      );
                },
                child: const Text('Ac'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await _enterShipmentBarcode(tester, barcode: '1111111111111');
    await _enterShipmentBarcode(tester, barcode: '1111111111111');

    expect(find.text('A Urun'), findsOneWidget);
    expect(find.text('Urun listede var'), findsNothing);

    await _enterShipmentBarcode(tester, barcode: '2222222222222');

    expect(find.text('B Urun'), findsOneWidget);
    expect(find.text('Urun listede var'), findsNothing);

    await _enterShipmentBarcode(
      tester,
      barcode: '1111111111111',
      settleAfterSubmit: false,
    );

    expect(find.text('Urun listede var'), findsOneWidget);
    expect(find.textContaining('Miktar artirilsin mi?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Vazgec'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A Urun'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Urun listede var'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Artir'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Kaydet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();

    expect(request, isNotNull);
    final linesByStockCode = <String, WarehouseShipmentCreateLine>{
      for (final line in request!.lines) line.stockCode: line,
    };
    expect(linesByStockCode['A001']?.quantity, 3);
    expect(linesByStockCode['B002']?.quantity, 1);
  });

  testWidgets('does not block shipment for target warehouse model warning', (
    tester,
  ) async {
    const targetWarehouseMessage = 'Hedef depo icin model kodu yoktur.';
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(
              barcodeResolutionBuilder: (request) {
                return buildBarcodeResolutionResult(
                  barcode: request.barcode,
                  warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 110,
                  operationType: request.operationType ?? '',
                  screenCode: request.screenCode ?? '',
                  isUsableInOperation: false,
                  isAllowedForTargetWarehouse: false,
                  targetWarehouseReason: targetWarehouseMessage,
                  operationDecision: targetWarehouseMessage,
                  warnings: const <String>[targetWarehouseMessage],
                  errors: const <String>[targetWarehouseMessage],
                );
              },
            ),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await _enterShipmentBarcode(tester);

    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text(targetWarehouseMessage), findsNothing);
    expect(find.textContaining('Eklendi: Test Urun'), findsNothing);
  });

  testWidgets(
    'does not block inter warehouse shipment for sales blocked flag',
    (tester) async {
      const salesBlockedMessage = 'Urun satisa/sevke kapali.';
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutgoingWarehouseShipmentCreateSheet(
              repository: _FakeOutgoingWarehouseShipmentsRepository(
                barcodeResolutionBuilder: (request) {
                  return buildBarcodeResolutionResult(
                    barcode: request.barcode,
                    warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 110,
                    operationType: request.operationType ?? '',
                    screenCode: request.screenCode ?? '',
                    isUsableInOperation: false,
                    isSalesBlocked: true,
                    operationDecision: salesBlockedMessage,
                    warnings: const <String>[salesBlockedMessage],
                    errors: const <String>[salesBlockedMessage],
                  );
                },
              ),
              receivedWarehouseOrdersRepository:
                  _FakeReceivedWarehouseOrdersRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileWarehouseCatalogRepository:
                  _emptyWarehouseCatalogRepository(),
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 - MERKEZ DEPO'));
      await tester.pumpAndSettle();

      await _enterShipmentBarcode(tester);

      expect(find.text('Test Urun'), findsOneWidget);
      expect(find.text(salesBlockedMessage), findsNothing);
      expect(find.textContaining('Eklendi: Test Urun'), findsNothing);
    },
  );

  testWidgets('allows editing order linked shipment lines', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Siparisli'));
    await tester.pumpAndSettle();
    await _dragShipmentCreateScroll(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D110.1915'));
    await tester.pumpAndSettle();

    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Siparis Urun'), findsOneWidget);
    expect(find.text('SIP001'), findsOneWidget);
    expect(find.text('AD'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Siparis Urun'), findsNothing);
    expect(find.text('SIP001'), findsNothing);
    expect(find.text('Giris satiri'), findsOneWidget);

    await _enterShipmentBarcode(tester);

    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('015792'), findsOneWidget);
  });
  testWidgets(
    'adds manav linked shipment quantities from scanned barcode weight',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      WarehouseShipmentCreateRequest? request;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    request =
                        await showModalBottomSheet<
                          WarehouseShipmentCreateRequest
                        >(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => OutgoingWarehouseShipmentCreateSheet(
                            repository:
                                _FakeOutgoingWarehouseShipmentsRepository(
                                  barcodeResolutionBuilder: (request) {
                                    final embeddedQuantity =
                                        request.barcode == '2700000002350'
                                        ? 2.35
                                        : 1.15;
                                    return buildBarcodeResolutionResult(
                                      barcode: request.barcode,
                                      warehouseNo:
                                          int.tryParse(
                                            request.warehouseNo ?? '',
                                          ) ??
                                          56,
                                      stockCode: '015792',
                                      stockName: 'MNV Test Urun',
                                      unitName: 'KG',
                                      unitMultiplier: 1,
                                      isVariableWeightBarcode: true,
                                      embeddedQuantity: embeddedQuantity,
                                      embeddedQuantityUnit: 'KG',
                                      operationType:
                                          request.operationType ?? '',
                                      screenCode: request.screenCode ?? '',
                                    );
                                  },
                                ),
                            receivedWarehouseOrdersRepository:
                                _GreenGrocerReceivedWarehouseOrdersRepository(),
                            accessToken: 'token',
                            defaultWarehouseNo: '56',
                            mobileWarehouseCatalogRepository:
                                _emptyWarehouseCatalogRepository(),
                          ),
                        );
                  },
                  child: const Text('Ac'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ac'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 - MERKEZ DEPO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siparisli'));
      await tester.pumpAndSettle();
      await _dragShipmentCreateScroll(tester);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('MNV.1001'));
      await tester.pumpAndSettle();

      await _enterShipmentBarcode(tester, barcode: '2700000002350');
      await _enterShipmentBarcode(tester, barcode: '2700000001150');

      await tester.scrollUntilVisible(
        find.text('Kaydet'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(request, isNotNull);
      expect(request!.lines, hasLength(1));
      expect(request!.lines.single.stockCode, '015792');
      expect(request!.lines.single.quantity, closeTo(3.5, 0.000001));
      expect(request!.lines.single.warehouseOrderLineGuid, isNull);
      expect(
        request!.lines.single.greenGrocerReferenceOrderLineGuid,
        'manav-order-line-guid',
      );
    },
  );

  testWidgets(
    'uses scanned manav barcode weight as linked shipment quantity step',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      WarehouseShipmentCreateRequest? request;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    request =
                        await showModalBottomSheet<
                          WarehouseShipmentCreateRequest
                        >(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => OutgoingWarehouseShipmentCreateSheet(
                            repository:
                                _FakeOutgoingWarehouseShipmentsRepository(
                                  barcodeResolutionBuilder: (request) {
                                    return buildBarcodeResolutionResult(
                                      barcode: request.barcode,
                                      warehouseNo:
                                          int.tryParse(
                                            request.warehouseNo ?? '',
                                          ) ??
                                          56,
                                      stockCode: '015792',
                                      stockName: 'MNV Test Urun',
                                      unitName: 'KG',
                                      unitMultiplier: 1,
                                      isVariableWeightBarcode: true,
                                      embeddedQuantity: 10,
                                      embeddedQuantityUnit: 'KG',
                                      operationType:
                                          request.operationType ?? '',
                                      screenCode: request.screenCode ?? '',
                                    );
                                  },
                                ),
                            receivedWarehouseOrdersRepository:
                                _GreenGrocerReceivedWarehouseOrdersRepository(),
                            accessToken: 'token',
                            defaultWarehouseNo: '56',
                            mobileWarehouseCatalogRepository:
                                _emptyWarehouseCatalogRepository(),
                          ),
                        );
                  },
                  child: const Text('Ac'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ac'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 - MERKEZ DEPO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siparisli'));
      await tester.pumpAndSettle();
      await _dragShipmentCreateScroll(tester);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('MNV.1001'));
      await tester.pumpAndSettle();

      await _enterShipmentBarcode(tester, barcode: '2700000010000');
      await _enterShipmentBarcode(tester, barcode: '2700000010000');

      final productLineCard = find.ancestor(
        of: find.text('MNV Test Urun').first,
        matching: find.byType(TerminalCompactProductLineCard),
      );
      expect(productLineCard, findsOneWidget);
      await tester.ensureVisible(productLineCard);
      await tester.tap(
        find.descendant(
          of: productLineCard,
          matching: find.byIcon(Icons.add_rounded),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Kaydet'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(request, isNotNull);
      expect(request!.lines, hasLength(1));
      expect(request!.lines.single.stockCode, '015792');
      expect(request!.lines.single.quantity, closeTo(30, 0.000001));
      expect(request!.lines.single.warehouseOrderLineGuid, isNull);
    },
  );

  testWidgets(
    'shows order filter bar, pending/critical badges, and allows partial manav submit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      WarehouseShipmentCreateRequest? request;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    request =
                        await showModalBottomSheet<
                          WarehouseShipmentCreateRequest
                        >(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => OutgoingWarehouseShipmentCreateSheet(
                            repository:
                                _FakeOutgoingWarehouseShipmentsRepository(
                                  barcodeResolutionBuilder: (request) {
                                    final embeddedQuantity =
                                        request.barcode == '2700000040000'
                                        ? 40.0
                                        : 20.0;
                                    return buildBarcodeResolutionResult(
                                      barcode: request.barcode,
                                      warehouseNo: 56,
                                      stockCode: '015792',
                                      stockName: 'MNV Test Urun',
                                      unitName: 'KG',
                                      unitMultiplier: 1,
                                      isVariableWeightBarcode: true,
                                      embeddedQuantity: embeddedQuantity,
                                      embeddedQuantityUnit: 'KG',
                                      operationType:
                                          request.operationType ?? '',
                                      screenCode: request.screenCode ?? '',
                                    );
                                  },
                                ),
                            receivedWarehouseOrdersRepository:
                                _TwoLineGreenGrocerReceivedWarehouseOrdersRepository(),
                            accessToken: 'token',
                            defaultWarehouseNo: '56',
                            mobileWarehouseCatalogRepository:
                                _emptyWarehouseCatalogRepository(),
                          ),
                        );
                  },
                  child: const Text('Ac'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ac'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 - MERKEZ DEPO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siparisli'));
      await tester.pumpAndSettle();
      await _dragShipmentCreateScroll(tester);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('MNV.2001'));
      await tester.pumpAndSettle();

      expect(find.text('Tumu (2)'), findsOneWidget);
      expect(find.text('Bekleyen (2)'), findsOneWidget);
      expect(find.text('Okutulan (0)'), findsOneWidget);
      expect(find.text('Bekliyor'), findsNWidgets(2));
      expect(
        find.textContaining('3 kasa | Hedef 25 | Sevk 10 | Kalan 15 KG'),
        findsOneWidget,
      );

      // Previous 10 + current 20 reaches the inclusive 30 KG tolerance limit.
      await _enterShipmentBarcode(tester, barcode: '2700000020000');
      expect(find.text('Bekleyen (1)'), findsOneWidget);
      expect(find.text('Okutulan (1)'), findsOneWidget);
      expect(find.text('Uygun'), findsOneWidget);

      // Submit ships only the 1 scanned line and skips the untouched empty Manav line.
      await tester.scrollUntilVisible(
        find.text('Kaydet'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(request, isNotNull);
      expect(request!.lines, hasLength(1));
      expect(request!.lines.single.stockCode, '015792');
      expect(request!.lines.single.quantity, closeTo(20, 0.000001));
    },
  );

  testWidgets(
    'order-linked picker works without preselecting warehouse across 320x533 and 360x640',
    (tester) async {
      for (final size in const <Size>[Size(320, 533), Size(360, 640)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ordersRepository = _MultiStoreReceivedWarehouseOrdersRepository();

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey<String>('order-picker-${size.width}x${size.height}'),
            home: Scaffold(
              body: OutgoingWarehouseShipmentCreateSheet(
                repository: _FakeOutgoingWarehouseShipmentsRepository(),
                receivedWarehouseOrdersRepository: ordersRepository,
                accessToken: 'token',
                defaultWarehouseNo: '110',
                mobileWarehouseCatalogRepository:
                    _emptyWarehouseCatalogRepository(),
                initialOrderLinked: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'),
          findsOneWidget,
        );

        // Open order picker WITHOUT choosing target warehouse first.
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('2 siparis'), findsOneWidget);
        expect(find.text('MILLET 1'), findsOneWidget);
        expect(find.text('GEMLIK 3 HISAR'), findsOneWidget);

        // Quick date preset triggers reload.
        await tester.tap(find.text('Son 3 Gun'));
        await tester.pumpAndSettle();
        expect(ordersRepository.fetchCount, greaterThanOrEqualTo(2));

        // Live client-side search filters immediately by store name.
        await tester.enterText(
          find.widgetWithText(TextField, 'Siparis veya sube ara'),
          'gemlik',
        );
        await tester.pumpAndSettle();
        expect(find.text('1 siparis'), findsOneWidget);
        expect(find.text('GEMLIK 3 HISAR'), findsOneWidget);
        expect(find.text('MILLET 1'), findsNothing);

        // Selecting order auto-fills target warehouse and opens ready-to-scan view.
        await tester.tap(find.text('D172.2044'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final warehouseField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Hedef depo no*'),
        );
        expect(warehouseField.controller?.text, '172');
        expect(find.text('172 · GEMLIK 3 HISAR'), findsOneWidget);
        expect(find.textContaining('D172.2044 · 1/1 satir'), findsOneWidget);
        expect(find.text('Siparis Urun'), findsOneWidget);
        expect(find.text('Tam'), findsOneWidget);
        expect(
          find.textContaining('Sip. 6 · Kalan 4 · Sevk 4 AD'),
          findsOneWidget,
        );
      }
    },
  );
}

Future<void> _pickShipmentTargetWarehouse(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Arama'), 'merkez');
  await tester.tap(find.text('Ara'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('50 - MERKEZ DEPO').last);
  await tester.pumpAndSettle();
}

Future<void> _enterShipmentBarcode(
  WidgetTester tester, {
  String barcode = '8690000000012',
  bool settleAfterSubmit = true,
}) async {
  final productField = await _findShipmentLookupField(tester);
  await tester.ensureVisible(productField);
  await tester.pumpAndSettle();

  await tester.enterText(productField, barcode);
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  if (settleAfterSubmit) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  if (settleAfterSubmit) {
    expect(find.text('Urun Ara'), findsNothing);
  }
  await _confirmPendingShipmentLine(
    tester,
    settleAfterSubmit: settleAfterSubmit,
  );
}

Future<void> _dragShipmentCreateScroll(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -260));
  await tester.pumpAndSettle();
}

Future<Finder> _findShipmentLookupField(WidgetTester tester) async {
  Finder fields = _shipmentLookupFields();
  if (fields.evaluate().isNotEmpty) {
    return fields.first;
  }

  await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 520));
  await tester.pumpAndSettle();

  fields = _shipmentLookupFields();
  if (fields.evaluate().isNotEmpty) {
    return fields.first;
  }

  await tester.scrollUntilVisible(
    find.text('Giris satiri').first,
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  return _shipmentLookupFields().first;
}

Finder _shipmentLookupFields() {
  final defaultField = find.widgetWithText(
    TextFormField,
    'Barkod / stok / urun',
  );
  if (defaultField.evaluate().isNotEmpty) {
    return defaultField;
  }

  return find.widgetWithText(TextFormField, 'Barkod okut / urun degistir');
}

Future<void> _confirmPendingShipmentLine(
  WidgetTester tester, {
  required bool settleAfterSubmit,
}) async {
  final addButton = find.widgetWithText(FilledButton, 'Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  if (settleAfterSubmit) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
}

CreateDraft _suspiciousQuantityShipmentDraft() {
  final now = DateTime(2026, 8, 14);
  return CreateDraft(
    id: 'draft-suspicious-shipment-quantity',
    moduleKey: 'outgoing-warehouse-shipments',
    userId: '56.magazaci',
    warehouseNo: '56',
    title: 'Depo Sevk - MERKEZ DEPO',
    createdAt: now,
    updatedAt: now,
    payload: <String, dynamic>{
      'targetWarehouseNo': '50',
      'transitWarehouseNo': '60',
      'documentNo': '',
      'description': '',
      'movementDate': now.toIso8601String(),
      'documentDate': now.toIso8601String(),
      'mode': 'manual',
      'selectedTargetWarehouse': <String, dynamic>{
        'warehouseNo': 50,
        'warehouseName': 'MERKEZ DEPO',
        'address': '',
        'district': '',
        'province': '',
      },
      'manualLines': <Map<String, dynamic>>[
        <String, dynamic>{
          'stockCode': '015792',
          'barcode': '8690000000012',
          'quantity': '252700186160007',
          'quantityStep': 1,
          'selectedProduct': <String, dynamic>{
            'warehouseNo': 56,
            'barcode': '8690000000012',
            'stockCode': '015792',
            'stockName': 'Test Urun',
            'price': 0,
            'unitName': 'KG',
            'unitMultiplier': 1,
            'isOrderBlocked': false,
          },
        },
      ],
    },
  );
}

MobileWarehouseCatalogLocalRepository _emptyWarehouseCatalogRepository() {
  return MobileWarehouseCatalogLocalRepository(database: MemoryLocalDatabase());
}

class _FakeOutgoingWarehouseShipmentsRepository
    implements OutgoingWarehouseShipmentsRepository {
  _FakeOutgoingWarehouseShipmentsRepository({this.barcodeResolutionBuilder});

  final BarcodeResolutionResult Function(BarcodeResolutionRequest request)?
  barcodeResolutionBuilder;

  @override
  bool get supportsEDespatch => true;

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) async {
    final builder = barcodeResolutionBuilder;
    if (builder != null) {
      return builder(request);
    }

    return buildBarcodeResolutionResult(
      barcode: request.barcode,
      warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 110,
      unitName: 'KL',
      unitMultiplier: 2,
      isCaseBarcode: true,
      matchedUnitsPerCase: 2,
      operationType: request.operationType ?? '',
      screenCode: request.screenCode ?? '',
    );
  }

  @override
  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentPdfDocument(
      fileName: 'test.pdf',
      bytes: Uint8List(0),
    );
  }

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  }) async {
    return const <WarehouseShipmentListItem>[];
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    int? sourceWarehouseNo,
    bool includeDelisted = true,
  }) async {
    return const <ProductLookupItem>[
      ProductLookupItem(
        warehouseNo: 110,
        barcode: '8690000000012',
        stockCode: '015792',
        stockName: 'Test Urun',
        price: 125,
        unitName: 'KL',
        unitMultiplier: 2,
        isOrderBlocked: false,
      ),
    ];
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[
      WarehouseLookupItem(
        warehouseNo: 50,
        warehouseName: 'MERKEZ DEPO',
        address: '',
        district: 'Osmangazi',
        province: 'Bursa',
      ),
    ];
  }
}

class _GreenGrocerReceivedWarehouseOrdersRepository
    implements ReceivedWarehouseOrdersRepository {
  @override
  bool get supportsCreate => false;

  @override
  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async => const WarehouseOrderDetail(
    header: WarehouseOrderDetailHeader(
      documentKey: 'MNV-1001',
      documentDate: null,
      deliveryDate: null,
      documentSerie: 'MNV',
      documentOrderNo: 1001,
      documentNumber: 'MNV.1001',
      warehouseNo: 56,
      warehouseName: 'MANAV DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 56,
      inWarehouseName: 'MANAV DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 3,
      totalDeliveredQuantity: 0,
      totalRemainingQuantity: 3,
      totalAmount: 0,
      isClosed: false,
    ),
    items: <WarehouseOrderDetailItem>[
      WarehouseOrderDetailItem(
        lineNo: 1,
        stockCode: '015792',
        stockName: 'MNV Test Urun',
        unitName: 'KG',
        unitPointer: 1,
        quantity: 3,
        deliveredQuantity: 0,
        remainingQuantity: 3,
        unitPrice: 0,
        lineAmount: 0,
        isClosed: false,
        description: '',
        packageCode: '',
        projectCode: '',
        modelCode: '10',
        lineGuid: 'manav-order-line-guid',
        greenGrocerCase: WarehouseOrderLineGreenGrocerCase(
          inputQuantity: 3,
          inputMode: 'Case',
          conversionMode: 'LabelAverageKgPerCase',
          estimatedQuantity: 25,
          microUnit: 'KG',
          averageKgPerCase: 8.333,
          averageSource: 'LabelHistory',
          confidence: 'High',
          allowOrderLinking: false,
          overDeliveryTolerancePercent: 20,
          severeOverDeliveryMultiplier: 1.5,
        ),
      ),
    ],
  );

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async => const <WarehouseOrderListItem>[
    WarehouseOrderListItem(
      documentKey: 'MNV-1001',
      documentDate: null,
      documentSerie: 'MNV',
      documentOrderNo: 1001,
      documentNumber: 'MNV.1001',
      warehouseNo: 56,
      warehouseName: 'MANAV DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 56,
      inWarehouseName: 'MANAV DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 3,
      totalAmount: 0,
      deliveryDate: null,
    ),
  ];

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    int? sourceWarehouseNo,
    bool includeDelisted = true,
  }) async {
    return const <ProductLookupItem>[];
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[];
  }
}

class _FakeReceivedWarehouseOrdersRepository
    implements ReceivedWarehouseOrdersRepository {
  @override
  bool get supportsCreate => false;

  @override
  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async => const WarehouseOrderDetail(
    header: WarehouseOrderDetailHeader(
      documentKey: 'D110-1915',
      documentDate: null,
      deliveryDate: null,
      documentSerie: 'D110',
      documentOrderNo: 1915,
      documentNumber: 'D110.1915',
      warehouseNo: 110,
      warehouseName: 'KAYNAK DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 110,
      inWarehouseName: 'KAYNAK DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 6,
      totalDeliveredQuantity: 2,
      totalRemainingQuantity: 4,
      totalAmount: 150,
      isClosed: false,
    ),
    items: <WarehouseOrderDetailItem>[
      WarehouseOrderDetailItem(
        lineNo: 1,
        stockCode: 'SIP001',
        stockName: 'Siparis Urun',
        unitName: 'AD',
        unitPointer: 1,
        quantity: 6,
        deliveredQuantity: 2,
        remainingQuantity: 4,
        unitPrice: 25,
        lineAmount: 150,
        isClosed: false,
        description: '',
        packageCode: '',
        projectCode: '',
        lineGuid: 'order-line-guid-1',
      ),
    ],
  );

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async => const <WarehouseOrderListItem>[
    WarehouseOrderListItem(
      documentKey: 'D110-1915',
      documentDate: null,
      documentSerie: 'D110',
      documentOrderNo: 1915,
      documentNumber: 'D110.1915',
      warehouseNo: 110,
      warehouseName: 'KAYNAK DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 110,
      inWarehouseName: 'KAYNAK DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 6,
      totalAmount: 150,
      deliveryDate: null,
    ),
  ];

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    int? sourceWarehouseNo,
    bool includeDelisted = true,
  }) async {
    return const <ProductLookupItem>[];
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[];
  }
}

class _TwoLineGreenGrocerReceivedWarehouseOrdersRepository
    extends _GreenGrocerReceivedWarehouseOrdersRepository {
  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async => const WarehouseOrderDetail(
    header: WarehouseOrderDetailHeader(
      documentKey: 'MNV-2001',
      documentDate: null,
      deliveryDate: null,
      documentSerie: 'MNV',
      documentOrderNo: 2001,
      documentNumber: 'MNV.2001',
      warehouseNo: 56,
      warehouseName: 'MANAV DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 56,
      inWarehouseName: 'MANAV DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 2,
      totalQuantity: 5,
      totalDeliveredQuantity: 0,
      totalRemainingQuantity: 5,
      totalAmount: 0,
      isClosed: false,
    ),
    items: <WarehouseOrderDetailItem>[
      WarehouseOrderDetailItem(
        lineNo: 1,
        stockCode: '015792',
        stockName: 'MNV Test Urun',
        unitName: 'KG',
        unitPointer: 1,
        quantity: 3,
        deliveredQuantity: 0,
        remainingQuantity: 3,
        unitPrice: 0,
        lineAmount: 0,
        isClosed: false,
        description: '',
        packageCode: '',
        projectCode: '',
        modelCode: '10',
        lineGuid: 'manav-order-line-guid-1',
        greenGrocerCase: WarehouseOrderLineGreenGrocerCase(
          inputQuantity: 3,
          inputMode: 'Case',
          conversionMode: 'LabelAverageKgPerCase',
          estimatedQuantity: 25,
          microUnit: 'KG',
          averageKgPerCase: 8.333,
          averageSource: 'LabelHistory',
          confidence: 'High',
          allowOrderLinking: false,
          overDeliveryTolerancePercent: 20,
          severeOverDeliveryMultiplier: 1.5,
          actualShippedQuantity: 10,
        ),
      ),
      WarehouseOrderDetailItem(
        lineNo: 2,
        stockCode: '015799',
        stockName: 'MNV Ikinci Urun',
        unitName: 'KG',
        unitPointer: 1,
        quantity: 2,
        deliveredQuantity: 0,
        remainingQuantity: 2,
        unitPrice: 0,
        lineAmount: 0,
        isClosed: false,
        description: '',
        packageCode: '',
        projectCode: '',
        modelCode: '10',
        lineGuid: 'manav-order-line-guid-2',
        greenGrocerCase: WarehouseOrderLineGreenGrocerCase(
          inputQuantity: 2,
          inputMode: 'Case',
          conversionMode: 'LabelAverageKgPerCase',
          estimatedQuantity: 15,
          microUnit: 'KG',
          averageKgPerCase: 7.5,
          averageSource: 'LabelHistory',
          confidence: 'High',
          allowOrderLinking: false,
          overDeliveryTolerancePercent: 20,
          severeOverDeliveryMultiplier: 1.5,
        ),
      ),
    ],
  );

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async => const <WarehouseOrderListItem>[
    WarehouseOrderListItem(
      documentKey: 'MNV-2001',
      documentDate: null,
      documentSerie: 'MNV',
      documentOrderNo: 2001,
      documentNumber: 'MNV.2001',
      warehouseNo: 56,
      warehouseName: 'MANAV DEPO',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 56,
      inWarehouseName: 'MANAV DEPO',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 2,
      totalQuantity: 5,
      totalAmount: 0,
      deliveryDate: null,
    ),
  ];
}

class _MultiStoreReceivedWarehouseOrdersRepository
    extends _FakeReceivedWarehouseOrdersRepository {
  int fetchCount = 0;

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async {
    fetchCount += 1;
    return <WarehouseOrderListItem>[
      WarehouseOrderListItem(
        documentKey: 'D105-1915',
        documentDate: DateTime(2026, 11, 26),
        documentSerie: 'D105',
        documentOrderNo: 1915,
        documentNumber: 'D105.1915',
        warehouseNo: 110,
        warehouseName: 'KAYNAK DEPO',
        relatedWarehouseNo: 105,
        relatedWarehouseName: 'MILLET 1',
        inWarehouseNo: 110,
        inWarehouseName: 'KAYNAK DEPO',
        outWarehouseNo: 105,
        outWarehouseName: 'MILLET 1',
        lineCount: 3,
        totalQuantity: 12,
        totalAmount: 420,
        deliveryDate: DateTime(2026, 11, 27),
      ),
      WarehouseOrderListItem(
        documentKey: 'D172-2044',
        documentDate: DateTime(2026, 11, 26),
        documentSerie: 'D172',
        documentOrderNo: 2044,
        documentNumber: 'D172.2044',
        warehouseNo: 110,
        warehouseName: 'KAYNAK DEPO',
        relatedWarehouseNo: 172,
        relatedWarehouseName: 'GEMLIK 3 HISAR',
        inWarehouseNo: 110,
        inWarehouseName: 'KAYNAK DEPO',
        outWarehouseNo: 172,
        outWarehouseName: 'GEMLIK 3 HISAR',
        lineCount: 1,
        totalQuantity: 6,
        totalAmount: 150,
        deliveryDate: null,
      ),
    ];
  }
}
