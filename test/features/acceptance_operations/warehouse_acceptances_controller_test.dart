import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/presentation/view_models/warehouse_acceptances_controller.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

void main() {
  test('loadAcceptances selects first record and loads detail', () async {
    final repository = _FakeWarehouseAcceptancesRepository();
    final controller = WarehouseAcceptancesController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadAcceptances();

    expect(controller.acceptances, hasLength(2));
    expect(controller.selectedAcceptance?.documentNoLabel, 'F110.3694');
    expect(controller.selectedAcceptanceDetail?.items, hasLength(1));
  });

  test('acceptShipment stores last result and reloads pending list', () async {
    final repository = _FakeWarehouseAcceptancesRepository();
    final controller = WarehouseAcceptancesController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadAcceptances();
    final result = await controller.acceptShipment(
      const WarehouseAcceptanceRequest(
        allowDiscrepancy: false,
        lines: <WarehouseAcceptanceRequestLine>[
          WarehouseAcceptanceRequestLine(
            movementGuid: 'movement-guid-1',
            receivedQuantity: 10,
          ),
        ],
      ),
    );

    expect(result?.documentNoLabel, 'F110.3694');
    expect(controller.lastAcceptanceResult?.totalReceivedQuantity, 10);
    expect(controller.acceptances, hasLength(1));
    expect(controller.selectedAcceptance?.documentNoLabel, 'F110.3695');
  });
}

class _FakeWarehouseAcceptancesRepository
    implements WarehouseAcceptancesRepository {
  final List<WarehouseAcceptanceListItem> _items =
      <WarehouseAcceptanceListItem>[
        const WarehouseShipmentListItem(
          documentDate: null,
          movementDate: null,
          documentNo: 'SVK-0001',
          documentSerie: 'F110',
          documentOrderNo: 3694,
          sourceWarehouseNo: 50,
          sourceWarehouse: 'MERKEZ DEPO',
          targetWarehouseNo: 110,
          targetWarehouse: 'KESTEL 1',
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
          sourceWarehouseNo: 50,
          sourceWarehouse: 'MERKEZ DEPO',
          targetWarehouseNo: 110,
          targetWarehouse: 'KESTEL 1',
          shippingWarehouseNo: 60,
          shippingState: 0,
          plaque: '',
          driverNameSurname: '',
          driverTckn: '',
          descriptionEttn: '',
          warehouseOrderNo: '',
          lineCount: 2,
          totalQuantity: 6,
          totalAmount: 720,
        ),
      ];

  @override
  Future<List<WarehouseAcceptanceListItem>> fetchAcceptances({
    required String accessToken,
    required WarehouseAcceptanceListFilter filter,
  }) async {
    return List<WarehouseAcceptanceListItem>.from(_items);
  }

  @override
  Future<WarehouseAcceptanceDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentDetail(
      header: WarehouseShipmentDetailHeader(
        documentDate: null,
        movementDate: null,
        documentNo: 'SVK-0001',
        documentSerie: 'F110',
        documentOrderNo: documentOrderNo,
        sourceWarehouseNo: 50,
        sourceWarehouse: 'MERKEZ DEPO',
        targetWarehouseNo: 110,
        targetWarehouse: 'KESTEL 1',
        shippingWarehouseNo: 60,
        shippingState: 0,
        plaque: '',
        driverNameSurname: '',
        driverTckn: '',
        descriptionEttn: '',
        warehouseOrderNo: '',
        warehouseOrderNos: const <String>[],
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
  }) async {
    _items.removeWhere(
      (item) =>
          item.documentSerie == documentSerie &&
          item.documentOrderNo == documentOrderNo,
    );

    return const WarehouseAcceptanceResult(
      documentSerie: 'F110',
      documentOrderNo: 3694,
      warehouseNo: 110,
      sourceWarehouseNo: 50,
      transitWarehouseNo: 60,
      shippingState: 1,
      lineCount: 1,
      totalShippedQuantity: 10,
      totalReceivedQuantity: 10,
      totalMissingQuantity: 0,
      totalExcessQuantity: 0,
      hasDiscrepancy: false,
      differenceResolutionStatus: 'none',
      writeConnectionName: 'testMikroConnection',
      lines: <WarehouseAcceptanceResultLine>[
        WarehouseAcceptanceResultLine(
          movementGuid: 'movement-guid-1',
          lineNo: 0,
          stockCode: '015792',
          shippedQuantity: 10,
          receivedQuantity: 10,
          differenceQuantity: 0,
          differenceType: 'none',
        ),
      ],
    );
  }

  @override
  Future<List<WarehouseAcceptanceDifferenceItem>> fetchDifferences({
    required String accessToken,
    required WarehouseAcceptanceDifferenceFilter filter,
  }) async {
    return const <WarehouseAcceptanceDifferenceItem>[];
  }
}
