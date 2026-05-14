import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/view_models/warehouse_returns_controller.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

void main() {
  test('loadReturns selects first record and loads detail', () async {
    final repository = _FakeWarehouseReturnsRepository();
    final controller = WarehouseReturnsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
      direction: WarehouseReturnDirection.outgoing,
    );

    await controller.loadReturns();

    expect(controller.returns, hasLength(2));
    expect(controller.selectedReturn?.documentNoLabel, 'F110.42');
    expect(controller.selectedReturnDetail?.items, hasLength(1));
  });

  test('sendEDespatch stores last result and refreshes detail', () async {
    final repository = _FakeWarehouseReturnsRepository();
    final controller = WarehouseReturnsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
      direction: WarehouseReturnDirection.outgoing,
    );

    await controller.loadReturns();
    final result = await controller.sendEDespatch(
      const EDespatchSendRequest(
        plaque: '16 ABC 123',
        driverNameSurname: 'Ad Soyad',
        driverTckn: '11111111111',
      ),
    );

    expect(result?.serviceDocumentNumber, 'IRS2026000000012');
    expect(controller.lastEDespatchResult?.eDespatchDocumentNo, 'FRM2026001');
    expect(controller.selectedReturnDetail?.header.plaque, '16 ABC 123');
  });

  test('fetchEDespatchPdf returns binary document', () async {
    final repository = _FakeWarehouseReturnsRepository();
    final controller = WarehouseReturnsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
      direction: WarehouseReturnDirection.outgoing,
    );

    await controller.loadReturns();
    final document = await controller.fetchEDespatchPdf();

    expect(document?.fileName, 'F110_42-e-irsaliye.pdf');
    expect(document?.bytes, isNotEmpty);
  });
}

class _FakeWarehouseReturnsRepository implements WarehouseReturnsRepository {
  final List<WarehouseReturnListItem> _items = <WarehouseReturnListItem>[
    const WarehouseShipmentListItem(
      documentDate: null,
      movementDate: null,
      documentNo: 'IAD-0001',
      documentSerie: 'F110',
      documentOrderNo: 42,
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
      warehouseOrderNo: '',
      lineCount: 1,
      totalQuantity: 5,
      totalAmount: 625,
    ),
    const WarehouseShipmentListItem(
      documentDate: null,
      movementDate: null,
      documentNo: 'IAD-0002',
      documentSerie: 'F110',
      documentOrderNo: 43,
      sourceWarehouseNo: 110,
      sourceWarehouse: 'KESTEL 1',
      targetWarehouseNo: 60,
      targetWarehouse: 'NAKLIYE',
      shippingWarehouseNo: 60,
      shippingState: 1,
      plaque: '',
      driverNameSurname: '',
      driverTckn: '',
      descriptionEttn: '',
      warehouseOrderNo: '',
      lineCount: 2,
      totalQuantity: 8,
      totalAmount: 840,
    ),
  ];

  String _plaque = '';
  String _driverNameSurname = '';
  String _driverTckn = '';

  @override
  Future<List<WarehouseReturnListItem>> fetchReturns({
    required String accessToken,
    required WarehouseReturnDirection direction,
    required WarehouseReturnListFilter filter,
  }) async {
    return List<WarehouseReturnListItem>.from(_items);
  }

  @override
  Future<WarehouseReturnDetail> fetchReturnDetail({
    required String accessToken,
    required WarehouseReturnDirection direction,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentDetail(
      header: WarehouseShipmentDetailHeader(
        documentDate: null,
        movementDate: null,
        documentNo: 'IAD-0001',
        documentSerie: 'F110',
        documentOrderNo: 42,
        sourceWarehouseNo: 110,
        sourceWarehouse: 'KESTEL 1',
        targetWarehouseNo: 50,
        targetWarehouse: 'MERKEZ DEPO',
        shippingWarehouseNo: 60,
        shippingState: 0,
        plaque: _plaque,
        driverNameSurname: _driverNameSurname,
        driverTckn: _driverTckn,
        descriptionEttn: _plaque.isEmpty ? '' : 'uuid-123',
        warehouseOrderNo: '',
        warehouseOrderNos: const <String>[],
        lineCount: 1,
        totalQuantity: 5,
        totalAmount: 625,
      ),
      items: const <WarehouseShipmentDetailItem>[
        WarehouseShipmentDetailItem(
          movementGuid: 'movement-guid-1',
          lineNo: 1,
          stockCode: '015792',
          stockName: 'Urun',
          unitName: 'AD',
          unitPointer: 1,
          quantity: 5,
          unitPrice: 125,
          lineAmount: 625,
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
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) async {
    _plaque = request.plaque;
    _driverNameSurname = request.driverNameSurname;
    _driverTckn = request.driverTckn;

    return const EDespatchSendResult(
      documentType: 4,
      documentSerie: 'F110',
      documentOrderNo: 42,
      eDespatchDocumentNo: 'FRM2026001',
      eDespatchUuid: 'uuid-123',
      serviceDocumentId: '123456789',
      serviceDocumentNumber: 'IRS2026000000012',
      sentAt: null,
      endpointUrl: 'http://example.test',
    );
  }

  @override
  Future<WarehouseReturnPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseReturnPdfDocument(
      fileName: 'F110_42-e-irsaliye.pdf',
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
    );
  }

  @override
  Future<WarehouseReturnCreateResult> createReturn({
    required String accessToken,
    required WarehouseReturnCreateRequest request,
  }) async {
    return const WarehouseReturnCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 99,
      documentNo: 'IAD-0099',
      movementDate: null,
      documentDate: null,
      sourceWarehouseNo: 110,
      targetWarehouseNo: 50,
      transitWarehouseNo: 60,
      lineCount: 1,
      linkedWarehouseOrderLineCount: 0,
      totalQuantity: 5,
      totalAmount: 625,
      writeConnectionName: 'testMikroConnection',
    );
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
