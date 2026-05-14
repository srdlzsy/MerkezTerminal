import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/view_models/outgoing_warehouse_shipments_controller.dart';

void main() {
  test('loadShipments selects first record and loads detail', () async {
    final repository = _FakeOutgoingWarehouseShipmentsRepository();
    final controller = OutgoingWarehouseShipmentsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadShipments();

    expect(controller.shipments, hasLength(2));
    expect(controller.selectedShipment?.documentNoLabel, 'F110.3694');
    expect(controller.selectedShipmentDetail?.items, hasLength(1));
  });

  test('createShipment reloads list and selects created document', () async {
    final repository = _FakeOutgoingWarehouseShipmentsRepository();
    final controller = OutgoingWarehouseShipmentsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    final result = await controller.createShipment(
      WarehouseShipmentCreateRequest(
        targetWarehouseNo: 50,
        transitWarehouseNo: 60,
        movementDate: DateTime(2026, 4, 17),
        documentDate: DateTime(2026, 4, 17),
        documentNo: '',
        description: '',
        lines: const <WarehouseShipmentCreateLine>[
          WarehouseShipmentCreateLine(
            warehouseOrderLineGuid: 'order-line-guid',
            stockCode: '015792',
            quantity: 10,
            unitPrice: 125,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
          ),
        ],
      ),
    );

    expect(result?.documentNoLabel, 'F110.0');
    expect(controller.selectedShipment?.documentNoLabel, 'F110.0');
    expect(controller.selectedShipmentDetail?.header.documentNoLabel, 'F110.0');
  });

  test(
    'selectShipment ignores stale detail response from earlier selection',
    () async {
      final repository = _DelayedOutgoingWarehouseShipmentsRepository();
      final controller = OutgoingWarehouseShipmentsController(
        repository: repository,
        accessToken: 'token',
        defaultWarehouseNo: '110',
      );

      const firstItem = WarehouseShipmentListItem(
        documentDate: null,
        movementDate: null,
        documentNo: 'SVK-0001',
        documentSerie: 'F110',
        documentOrderNo: 3694,
        sourceWarehouseNo: 110,
        sourceWarehouse: 'KESTEL 1',
        targetWarehouseNo: 50,
        targetWarehouse: 'MERKEZ DEPO',
        shippingWarehouseNo: 60,
        shippingState: 0,
        plaque: '',
        driverNameSurname: '',
        driverTckn: '',
        descriptionEttn: '',
        warehouseOrderNo: 'D110.1915',
        lineCount: 1,
        totalQuantity: 10,
        totalAmount: 1250,
      );
      const secondItem = WarehouseShipmentListItem(
        documentDate: null,
        movementDate: null,
        documentNo: 'SVK-0002',
        documentSerie: 'F110',
        documentOrderNo: 3695,
        sourceWarehouseNo: 110,
        sourceWarehouse: 'KESTEL 1',
        targetWarehouseNo: 60,
        targetWarehouse: 'NAKLIYE',
        shippingWarehouseNo: 60,
        shippingState: 1,
        plaque: '16 ABC 123',
        driverNameSurname: 'Ad Soyad',
        driverTckn: '11111111111',
        descriptionEttn: '',
        warehouseOrderNo: '',
        lineCount: 2,
        totalQuantity: 20,
        totalAmount: 2400,
      );

      final firstFuture = controller.selectShipment(firstItem);
      final secondFuture = controller.selectShipment(secondItem);

      repository.completeDetail(
        3695,
        _buildWarehouseShipmentDetail(
          documentOrderNo: 3695,
          documentNo: 'SVK-0002',
          targetWarehouseNo: 60,
          targetWarehouse: 'NAKLIYE',
          shippingState: 1,
          quantity: 20,
          warehouseOrderNo: '',
        ),
      );
      await secondFuture;

      expect(controller.selectedShipment?.documentNoLabel, 'F110.3695');
      expect(
        controller.selectedShipmentDetail?.header.documentNoLabel,
        'F110.3695',
      );

      repository.completeDetail(
        3694,
        _buildWarehouseShipmentDetail(
          documentOrderNo: 3694,
          documentNo: 'SVK-0001',
          targetWarehouseNo: 50,
          targetWarehouse: 'MERKEZ DEPO',
          shippingState: 0,
          quantity: 10,
          warehouseOrderNo: 'D110.1915',
        ),
      );
      await firstFuture;

      expect(controller.selectedShipment?.documentNoLabel, 'F110.3695');
      expect(
        controller.selectedShipmentDetail?.header.documentNoLabel,
        'F110.3695',
      );
    },
  );
}

class _FakeOutgoingWarehouseShipmentsRepository
    implements OutgoingWarehouseShipmentsRepository {
  @override
  bool get supportsEDespatch => true;

  final List<WarehouseShipmentListItem> _items = <WarehouseShipmentListItem>[
    const WarehouseShipmentListItem(
      documentDate: null,
      movementDate: null,
      documentNo: 'SVK-0001',
      documentSerie: 'F110',
      documentOrderNo: 3694,
      sourceWarehouseNo: 110,
      sourceWarehouse: 'KESTEL 1',
      targetWarehouseNo: 50,
      targetWarehouse: 'MERKEZ DEPO',
      shippingWarehouseNo: 60,
      shippingState: 0,
      plaque: '',
      driverNameSurname: '',
      driverTckn: '',
      descriptionEttn: '',
      warehouseOrderNo: 'D110.1915',
      lineCount: 1,
      totalQuantity: 10,
      totalAmount: 1250,
    ),
    const WarehouseShipmentListItem(
      documentDate: null,
      movementDate: null,
      documentNo: 'SVK-0002',
      documentSerie: 'F110',
      documentOrderNo: 3695,
      sourceWarehouseNo: 110,
      sourceWarehouse: 'KESTEL 1',
      targetWarehouseNo: 60,
      targetWarehouse: 'NAKLIYE',
      shippingWarehouseNo: 60,
      shippingState: 1,
      plaque: '16 ABC 123',
      driverNameSurname: 'Ad Soyad',
      driverTckn: '11111111111',
      descriptionEttn: '',
      warehouseOrderNo: '',
      lineCount: 2,
      totalQuantity: 20,
      totalAmount: 2400,
    ),
  ];

  @override
  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  }) async {
    const createdItem = WarehouseShipmentListItem(
      documentDate: null,
      movementDate: null,
      documentNo: '',
      documentSerie: 'F110',
      documentOrderNo: 0,
      sourceWarehouseNo: 110,
      sourceWarehouse: 'KESTEL 1',
      targetWarehouseNo: 50,
      targetWarehouse: 'MERKEZ DEPO',
      shippingWarehouseNo: 60,
      shippingState: 0,
      plaque: '',
      driverNameSurname: '',
      driverTckn: '',
      descriptionEttn: '',
      warehouseOrderNo: 'D110.1915',
      lineCount: 1,
      totalQuantity: 10,
      totalAmount: 1250,
    );

    _items.insert(0, createdItem);

    return const WarehouseShipmentCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 0,
      movementDate: null,
      documentDate: null,
      documentNo: '',
      sourceWarehouseNo: 110,
      targetWarehouseNo: 50,
      transitWarehouseNo: 60,
      lineCount: 1,
      linkedWarehouseOrderLineCount: 1,
      totalQuantity: 10,
      totalAmount: 1250,
      writeConnectionName: 'testMikroConnection',
    );
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) async {
    return const EDespatchSendResult(
      documentType: 4,
      documentSerie: 'F110',
      documentOrderNo: 3694,
      eDespatchDocumentNo: 'FRM2026001',
      eDespatchUuid: 'uuid-123',
      serviceDocumentId: '123456789',
      serviceDocumentNumber: 'IRS2026000000012',
      sentAt: null,
      endpointUrl: 'http://example.test',
    );
  }

  @override
  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentPdfDocument(
      fileName: 'F110_3694-e-irsaliye.pdf',
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
    );
  }

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final isCreatedDocument = documentSerie == 'F110' && documentOrderNo == 0;

    return WarehouseShipmentDetail(
      header: WarehouseShipmentDetailHeader(
        documentDate: null,
        movementDate: null,
        documentNo: isCreatedDocument ? '' : 'SVK-0001',
        documentSerie: 'F110',
        documentOrderNo: isCreatedDocument ? 0 : 3694,
        sourceWarehouseNo: 110,
        sourceWarehouse: 'KESTEL 1',
        targetWarehouseNo: 50,
        targetWarehouse: 'MERKEZ DEPO',
        shippingWarehouseNo: 60,
        shippingState: 0,
        plaque: '',
        driverNameSurname: '',
        driverTckn: '',
        descriptionEttn: '',
        warehouseOrderNo: 'D110.1915',
        warehouseOrderNos: const <String>['D110.1915'],
        lineCount: 1,
        totalQuantity: 10,
        totalAmount: 1250,
      ),
      items: const <WarehouseShipmentDetailItem>[
        WarehouseShipmentDetailItem(
          movementGuid: 'movement-guid-1',
          lineNo: 0,
          stockCode: '015792',
          stockName: 'Urun',
          unitName: 'AD',
          unitPointer: 1,
          quantity: 10,
          unitPrice: 125,
          lineAmount: 1250,
          description: '',
          partyCode: '',
          lotNo: 0,
          projectCode: '',
          warehouseOrderNo: 'D110.1915',
        ),
      ],
    );
  }

  @override
  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  }) async {
    return List<WarehouseShipmentListItem>.from(_items);
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
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

class _DelayedOutgoingWarehouseShipmentsRepository
    extends _FakeOutgoingWarehouseShipmentsRepository {
  final Map<int, Completer<WarehouseShipmentDetail>> _detailCompleters =
      <int, Completer<WarehouseShipmentDetail>>{};

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    return (_detailCompleters[documentOrderNo] ??=
            Completer<WarehouseShipmentDetail>())
        .future;
  }

  void completeDetail(int documentOrderNo, WarehouseShipmentDetail detail) {
    final completer = _detailCompleters[documentOrderNo] ??=
        Completer<WarehouseShipmentDetail>();
    if (!completer.isCompleted) {
      completer.complete(detail);
    }
  }
}

WarehouseShipmentDetail _buildWarehouseShipmentDetail({
  required int documentOrderNo,
  required String documentNo,
  required int targetWarehouseNo,
  required String targetWarehouse,
  required int shippingState,
  required double quantity,
  required String warehouseOrderNo,
}) {
  return WarehouseShipmentDetail(
    header: WarehouseShipmentDetailHeader(
      documentDate: null,
      movementDate: null,
      documentNo: documentNo,
      documentSerie: 'F110',
      documentOrderNo: documentOrderNo,
      sourceWarehouseNo: 110,
      sourceWarehouse: 'KESTEL 1',
      targetWarehouseNo: targetWarehouseNo,
      targetWarehouse: targetWarehouse,
      shippingWarehouseNo: 60,
      shippingState: shippingState,
      plaque: '',
      driverNameSurname: '',
      driverTckn: '',
      descriptionEttn: '',
      warehouseOrderNo: warehouseOrderNo,
      warehouseOrderNos: warehouseOrderNo.isEmpty
          ? const <String>[]
          : <String>[warehouseOrderNo],
      lineCount: 1,
      totalQuantity: quantity,
      totalAmount: quantity * 125,
    ),
    items: <WarehouseShipmentDetailItem>[
      WarehouseShipmentDetailItem(
        movementGuid: 'movement-guid-$documentOrderNo',
        lineNo: 0,
        stockCode: '015792',
        stockName: 'Urun',
        unitName: 'AD',
        unitPointer: 1,
        quantity: quantity,
        unitPrice: 125,
        lineAmount: quantity * 125,
        description: '',
        partyCode: '',
        lotNo: 0,
        projectCode: '',
        warehouseOrderNo: warehouseOrderNo,
      ),
    ],
  );
}
