import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/green_grocer/product_cases/data/green_grocer_product_cases_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/widgets/given_warehouse_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets('renders create sheet labels without mojibake', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GivenWarehouseOrderCreateSheet(
            repository: _FakeWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                MobileWarehouseCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    expect(find.text('Yeni Verilen Depo Siparisi'), findsOneWidget);
    expect(find.text('Kaynak depo: 110'), findsOneWidget);
    expect(find.text('Satirlar'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Siparisi Olustur'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Vazgec'), findsOneWidget);
    expect(find.text('Siparisi Olustur'), findsOneWidget);

    final renderedText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join('\n');

    expect(renderedText, isNot(contains(String.fromCharCode(0x00C3))));
    expect(renderedText, isNot(contains(String.fromCharCode(0x00C2))));
    expect(renderedText, isNot(contains(String.fromCharCode(0x00E2))));
  });

  testWidgets(
    'lays out product entry actions on terminal width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GivenWarehouseOrderCreateSheet(
              repository: _FakeWarehouseOrdersRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileWarehouseCatalogRepository:
                  MobileWarehouseCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
            ),
          ),
        ),
      );

      await _pickWarehouse(tester);

      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi'),
        findsWidgets,
      );
      expect(find.widgetWithText(FilledButton, 'Urun'), findsWidgets);
      expect(find.byIcon(Icons.photo_camera_back_rounded), findsWidgets);
    },
  );

  testWidgets('keeps a fresh barcode entry row after adding a product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GivenWarehouseOrderCreateSheet(
            repository: _FakeWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                MobileWarehouseCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    await _pickWarehouse(tester);

    await _pickWarehouseOrderProduct(tester);

    expect(find.text('1 kalem'), findsOneWidget);
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsOneWidget);
    expect(find.text('Okutmaya hazir'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Test Urun')).dy,
      greaterThan(tester.getTopLeft(find.text('Giris satiri')).dy),
    );
  });
  testWidgets('resolves manav case quantity before returning create request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    WarehouseOrderCreateRequest? request;
    final greenGrocerRepository = _FakeGreenGrocerProductCasesRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  request =
                      await showModalBottomSheet<WarehouseOrderCreateRequest>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => GivenWarehouseOrderCreateSheet(
                          repository: _FakeWarehouseOrdersRepository(
                            product: const ProductLookupItem(
                              warehouseNo: 56,
                              barcode: '8690000000012',
                              stockCode: '015792',
                              stockName: 'MNV Test Urun',
                              modelCode: '10',
                              price: 125,
                              unitName: 'KASA',
                              isOrderBlocked: false,
                            ),
                          ),
                          accessToken: 'token',
                          defaultWarehouseNo: '56',
                          greenGrocerProductCasesRepository:
                              greenGrocerRepository,
                          greenGrocerProductCasesEnabled: true,
                          mobileWarehouseCatalogRepository:
                              MobileWarehouseCatalogLocalRepository(
                                database: MemoryLocalDatabase(),
                              ),
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
    await _pickWarehouse(tester);
    await _pickWarehouseOrderProduct(tester);

    final quantityField = find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.controller?.text == '1',
    );
    await tester.ensureVisible(quantityField.first);
    await tester.enterText(quantityField.first, '3');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Siparisi Olustur'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Siparisi Olustur'));
    await tester.pumpAndSettle();

    expect(greenGrocerRepository.requests, isNotEmpty);
    expect(greenGrocerRepository.requests.last.stockCode, '015792');
    expect(greenGrocerRepository.requests.last.inputQuantity, 3);
    expect(greenGrocerRepository.requests.last.sourceWarehouseNo, 56);
    expect(greenGrocerRepository.requests.last.targetWarehouseNo, 50);
    expect(request, isNotNull);
    expect(request!.lines.single.quantity, 11.25);
    expect(request!.lines.single.greenGrocerCase, isNotNull);
    expect(request!.lines.single.greenGrocerCase!.inputQuantity, 3);
    expect(request!.lines.single.greenGrocerCase!.estimatedQuantity, 11.25);
    final requestJson = request!.toJson();
    final lineJson =
        (requestJson['lines'] as List<dynamic>).single as Map<String, dynamic>;
    final greenGrocerCaseJson =
        lineJson['greenGrocerCase'] as Map<String, dynamic>;
    expect(greenGrocerCaseJson['inputMode'], 'Case');
    expect(greenGrocerCaseJson['microUnit'], 'KG');
  });
}

Future<void> _pickWarehouse(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Sec'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('50 - MERKEZ DEPO'));
  await tester.pumpAndSettle();
}

Future<void> _pickWarehouseOrderProduct(WidgetTester tester) async {
  final productField = find
      .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
      .first;
  await tester.ensureVisible(productField);
  await tester.enterText(productField, '8690000000012');
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();

  expect(find.text('Urun Ara'), findsNothing);
  await _confirmPendingProduct(tester);
}

Future<void> _confirmPendingProduct(WidgetTester tester) async {
  final addButton = find.widgetWithText(FilledButton, 'Kaleme Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

class _FakeWarehouseOrdersRepository implements WarehouseOrdersRepository {
  _FakeWarehouseOrdersRepository({ProductLookupItem? product})
    : product =
          product ??
          const ProductLookupItem(
            warehouseNo: 110,
            barcode: '8690000000012',
            stockCode: '015792',
            stockName: 'Test Urun',
            price: 125,
            unitName: 'AD',
            isOrderBlocked: false,
          );

  final ProductLookupItem product;

  @override
  bool get supportsCreate => true;

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return <ProductLookupItem>[product];
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

class _FakeGreenGrocerProductCasesRepository
    implements GreenGrocerProductCasesRepository {
  final List<GreenGrocerProductCaseResolutionRequest> requests =
      <GreenGrocerProductCaseResolutionRequest>[];

  @override
  Future<GreenGrocerProductCaseResolutionResult> resolvePreview({
    required String accessToken,
    required GreenGrocerProductCaseResolutionRequest request,
  }) async {
    requests.add(request);
    return GreenGrocerProductCaseResolutionResult(
      stockCode: request.stockCode,
      stockName: 'MNV Test Urun',
      modelCode: '10',
      modelName: 'MANAV',
      unit1: 'KG',
      unit2: 'KASA',
      unit2Factor: 1,
      inputQuantity: request.inputQuantity,
      inputMode: 'Case',
      conversionMode: 'AverageKgPerCase',
      microUnit: 'KG',
      estimatedQuantity: request.inputQuantity * 3.75,
      averageKgPerCase: 3.75,
      unitsPerCase: 1,
      averageSource: 'Profile',
      averageRecordCount: 4,
      averageCaseCount: request.inputQuantity,
      coefficientOfVariation: 0.1,
      latestLabelDate: DateTime(2026),
      confidence: 'High',
      requiresManualApproval: false,
      isOrderLinkable: false,
      isUsable: true,
      warnings: const <String>[],
      errors: const <String>[],
    );
  }
}
