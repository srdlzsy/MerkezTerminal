import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/presentation/views/warehouse_acceptances_page.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

void main() {
  testWidgets('uses a dedicated compact acceptance screen on small PDA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WarehouseAcceptancesPage(
            repository: _FakeWarehouseAcceptancesRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '56',
            userWarehouseName: 'MANAV DEPO',
            canSubmit: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final document = find.text('F56.1');
    await tester.ensureVisible(document);
    await tester.tap(document);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('warehouse-acceptance-lines')),
      findsOneWidget,
    );
    expect(find.text('MNV DOMATES SALKIM KG'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Kabul Et'), findsOneWidget);
    expect(find.textContaining('Her satirda varsayilan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('treats an equal decimal KG quantity as complete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WarehouseAcceptancesPage(
            repository: _FakeWarehouseAcceptancesRepository(
              detailQuantity: 0.31999999999999995,
            ),
            accessToken: 'token',
            defaultWarehouseNo: '56',
            userWarehouseName: 'MANAV DEPO',
            canSubmit: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final document = find.text('F56.1');
    await tester.ensureVisible(document);
    await tester.tap(document);
    await tester.pumpAndSettle();

    final quantityField = find.widgetWithText(TextField, 'Sayilan');
    expect(quantityField, findsOneWidget);
    await tester.enterText(quantityField, '0.32');
    await tester.pump();

    expect(find.text('Tam'), findsOneWidget);
    expect(find.text('Fazla'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeWarehouseAcceptancesRepository
    implements WarehouseAcceptancesRepository {
  _FakeWarehouseAcceptancesRepository({this.detailQuantity = 2});

  final double detailQuantity;

  static const item = WarehouseShipmentListItem(
    documentDate: null,
    movementDate: null,
    documentNo: 'IRS0001',
    documentSerie: 'F56',
    documentOrderNo: 1,
    sourceWarehouseNo: 56,
    sourceWarehouse: 'MANAV DEPO',
    targetWarehouseNo: 120,
    targetWarehouse: 'SUBE 120',
    shippingWarehouseNo: 56,
    shippingState: 1,
    plaque: '',
    driverNameSurname: '',
    driverTckn: '',
    descriptionEttn: '',
    warehouseOrderNo: '',
    lineCount: 1,
    totalQuantity: 2,
    totalAmount: 0,
  );

  @override
  Future<List<WarehouseAcceptanceListItem>> fetchAcceptances({
    required String accessToken,
    required WarehouseAcceptanceListFilter filter,
  }) async {
    return const <WarehouseAcceptanceListItem>[item];
  }

  @override
  Future<WarehouseAcceptanceDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentDetail(
      header: const WarehouseShipmentDetailHeader(
        documentDate: null,
        movementDate: null,
        documentNo: 'IRS0001',
        documentSerie: 'F56',
        documentOrderNo: 1,
        sourceWarehouseNo: 56,
        sourceWarehouse: 'MANAV DEPO',
        targetWarehouseNo: 120,
        targetWarehouse: 'SUBE 120',
        shippingWarehouseNo: 56,
        shippingState: 1,
        plaque: '',
        driverNameSurname: '',
        driverTckn: '',
        descriptionEttn: '',
        warehouseOrderNo: '',
        warehouseOrderNos: <String>[],
        lineCount: 1,
        totalQuantity: 2,
        totalAmount: 0,
      ),
      items: <WarehouseShipmentDetailItem>[
        WarehouseShipmentDetailItem(
          movementGuid: '11111111-1111-1111-1111-111111111111',
          lineNo: 1,
          stockCode: '016129',
          stockName: 'MNV DOMATES SALKIM KG',
          unitName: 'KG',
          unitPointer: 1,
          quantity: detailQuantity,
          unitPrice: 0,
          lineAmount: 0,
          description: '',
          partyCode: '',
          lotNo: 0,
          projectCode: '',
          warehouseOrderNo: '',
        ),
      ],
    );
  }

  @override
  Future<WarehouseAcceptanceResult> acceptShipment({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required WarehouseAcceptanceRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseAcceptanceDifferenceItem>> fetchDifferences({
    required String accessToken,
    required WarehouseAcceptanceDifferenceFilter filter,
  }) async {
    return const <WarehouseAcceptanceDifferenceItem>[];
  }
}
