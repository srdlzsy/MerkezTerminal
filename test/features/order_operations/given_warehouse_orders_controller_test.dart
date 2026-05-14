import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/models/given_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/view_models/given_warehouse_orders_controller.dart';

void main() {
  test('loadOrders selects first record and loads its detail', () async {
    final repository = _FakeGivenWarehouseOrdersRepository();
    final controller = GivenWarehouseOrdersController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadOrders();

    expect(controller.orders, hasLength(2));
    expect(controller.selectedOrder?.documentNoLabel, 'D110.1915');
    expect(controller.selectedOrderDetail?.items, hasLength(1));
  });

  test('createOrder reloads list and selects created document', () async {
    final repository = _FakeGivenWarehouseOrdersRepository();
    final controller = GivenWarehouseOrdersController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    final result = await controller.createOrder(
      WarehouseOrderCreateRequest(
        outWarehouseNo: 50,
        orderDate: DateTime(2026, 4, 17),
        deliveryDate: DateTime(2026, 4, 17),
        description: '',
        lines: const <WarehouseOrderCreateLine>[
          WarehouseOrderCreateLine(
            stockCode: '015550',
            quantity: 10,
            recommendedQuantity: 0,
            unitPrice: 0,
            unitPointer: 1,
            description: '',
            packageCode: '',
            projectCode: '',
            responsibilityCenter: '',
          ),
        ],
      ),
    );

    expect(result?.documentNoLabel, 'F110.0');
    expect(controller.selectedOrder?.documentNoLabel, 'F110.0');
    expect(controller.selectedOrderDetail?.header.documentNoLabel, 'F110.0');
  });
}

class _FakeGivenWarehouseOrdersRepository
    implements GivenWarehouseOrdersRepository {
  final List<WarehouseOrderListItem> _orders = <WarehouseOrderListItem>[
    const WarehouseOrderListItem(
      documentKey: 'key-1',
      documentDate: null,
      documentSerie: 'D110',
      documentOrderNo: 1915,
      documentNumber: '',
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 110,
      inWarehouseName: 'KESTEL 1',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 12,
      totalAmount: 0,
      deliveryDate: null,
    ),
    const WarehouseOrderListItem(
      documentKey: 'key-2',
      documentDate: null,
      documentSerie: 'D110',
      documentOrderNo: 1916,
      documentNumber: '',
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 110,
      inWarehouseName: 'KESTEL 1',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 2,
      totalQuantity: 24,
      totalAmount: 0,
      deliveryDate: null,
    ),
  ];

  @override
  bool get supportsCreate => true;

  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final isCreatedDocument = documentSerie == 'F110' && documentOrderNo == 0;

    return WarehouseOrderDetail(
      header: WarehouseOrderDetailHeader(
        documentKey: isCreatedDocument ? 'key-created' : 'key-1',
        documentDate: null,
        deliveryDate: null,
        documentSerie: isCreatedDocument ? 'F110' : 'D110',
        documentOrderNo: isCreatedDocument ? 0 : 1915,
        documentNumber: '',
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        relatedWarehouseNo: 50,
        relatedWarehouseName: 'MERKEZ DEPO',
        inWarehouseNo: 110,
        inWarehouseName: 'KESTEL 1',
        outWarehouseNo: 50,
        outWarehouseName: 'MERKEZ DEPO',
        lineCount: 1,
        totalQuantity: isCreatedDocument ? 10 : 12,
        totalDeliveredQuantity: 0,
        totalRemainingQuantity: isCreatedDocument ? 10 : 12,
        totalAmount: 0,
        isClosed: false,
      ),
      items: <WarehouseOrderDetailItem>[
        WarehouseOrderDetailItem(
          lineNo: 0,
          stockCode: '015550',
          stockName: 'Urun',
          unitName: 'AD',
          unitPointer: 1,
          quantity: isCreatedDocument ? 10 : 12,
          deliveredQuantity: 0,
          remainingQuantity: isCreatedDocument ? 10 : 12,
          unitPrice: 0,
          lineAmount: 0,
          isClosed: false,
          description: '',
          packageCode: '',
          projectCode: '',
        ),
      ],
    );
  }

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async {
    return List<WarehouseOrderListItem>.from(_orders);
  }

  @override
  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  }) async {
    const createdOrder = WarehouseOrderListItem(
      documentKey: 'key-created',
      documentDate: null,
      documentSerie: 'F110',
      documentOrderNo: 0,
      documentNumber: '',
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      relatedWarehouseNo: 50,
      relatedWarehouseName: 'MERKEZ DEPO',
      inWarehouseNo: 110,
      inWarehouseName: 'KESTEL 1',
      outWarehouseNo: 50,
      outWarehouseName: 'MERKEZ DEPO',
      lineCount: 1,
      totalQuantity: 10,
      totalAmount: 0,
      deliveryDate: null,
    );

    _orders.insert(0, createdOrder);

    return const WarehouseOrderCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 0,
      orderDate: null,
      deliveryDate: null,
      inWarehouseNo: 110,
      outWarehouseNo: 50,
      lineCount: 1,
      totalQuantity: 10,
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
