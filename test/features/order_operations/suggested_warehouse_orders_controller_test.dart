import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/presentation/view_models/suggested_warehouse_orders_controller.dart';

void main() {
  test(
    'loads suggested warehouse orders and converts selected lines',
    () async {
      final repository = _FakeSuggestedWarehouseOrdersRepository();
      final controller = SuggestedWarehouseOrdersController(
        repository: repository,
        accessToken: 'token',
      );
      addTearDown(controller.dispose);

      await controller.loadSuggestions(sourceWarehouseNo: 50);

      expect(repository.lastFilter?.sourceWarehouseNo, 50);
      expect(controller.items, hasLength(2));
      expect(controller.selectedCount, 0);

      final item = controller.items.first;
      controller.toggleItem(item);
      controller.updateQuantity(item, '12,5');

      final result = await controller.convertSelected(
        orderDate: DateTime(2026, 7, 1),
        deliveryDate: DateTime(2026, 7, 2),
        description: 'Oneriden olustu',
      );

      expect(result?.documentNoLabel, 'D50.91');
      expect(repository.lastRequest?.sourceWarehouseNo, 50);
      expect(repository.lastRequest?.description, 'Oneriden olustu');
      expect(repository.lastRequest?.lines, hasLength(1));
      expect(repository.lastRequest?.lines.single.stockCode, '010001');
      expect(repository.lastRequest?.lines.single.quantity, 12.5);
      expect(repository.lastRequest?.lines.single.recommendedQuantity, 9);
      expect(controller.selectedCount, 0);
    },
  );

  test('does not convert without a selected line', () async {
    final controller = SuggestedWarehouseOrdersController(
      repository: _FakeSuggestedWarehouseOrdersRepository(),
      accessToken: 'token',
    );
    addTearDown(controller.dispose);

    await controller.loadSuggestions(sourceWarehouseNo: 50);

    final result = await controller.convertSelected(
      orderDate: DateTime(2026, 7, 1),
      deliveryDate: DateTime(2026, 7, 2),
      description: '',
    );

    expect(result, isNull);
    expect(controller.convertError, contains('en az bir satir'));
  });

  test('does not convert when quantity exceeds source stock', () async {
    final controller = SuggestedWarehouseOrdersController(
      repository: _FakeSuggestedWarehouseOrdersRepository(),
      accessToken: 'token',
    );
    addTearDown(controller.dispose);

    await controller.loadSuggestions(sourceWarehouseNo: 50);

    final item = controller.items.first;
    controller.toggleItem(item);
    controller.updateQuantity(item, '121');

    final result = await controller.convertSelected(
      orderDate: DateTime(2026, 7, 1),
      deliveryDate: DateTime(2026, 7, 2),
      description: '',
    );

    expect(result, isNull);
    expect(controller.convertError, contains('kaynak stoktan buyuk'));
  });

  test(
    'converts green grocer suggestions only after manual quantity',
    () async {
      final repository = _FakeSuggestedWarehouseOrdersRepository();
      final controller = SuggestedWarehouseOrdersController(
        repository: repository,
        accessToken: 'token',
      );
      addTearDown(controller.dispose);

      await controller.loadSuggestions(sourceWarehouseNo: 56);

      final item = controller.items.single;
      expect(item.needsManualQuantity, isTrue);
      expect(item.defaultOrderQuantity, 0);

      controller.toggleItem(item);
      var result = await controller.convertSelected(
        orderDate: DateTime(2026, 7, 1),
        deliveryDate: DateTime(2026, 7, 2),
        description: '',
      );

      expect(result, isNull);
      expect(controller.convertError, contains('sifirdan buyuk'));

      controller.updateQuantity(item, '15');
      result = await controller.convertSelected(
        orderDate: DateTime(2026, 7, 1),
        deliveryDate: DateTime(2026, 7, 2),
        description: 'Manav',
      );

      expect(result?.documentNoLabel, 'D50.91');
      expect(repository.lastRequest?.sourceWarehouseNo, 56);
      expect(repository.lastRequest?.lines.single.stockCode, '016167');
      expect(repository.lastRequest?.lines.single.quantity, 15);
      expect(repository.lastRequest?.lines.single.recommendedQuantity, 0);
      expect(repository.lastRequest?.lines.single.unitPointer, 1);
    },
  );
}

class _FakeSuggestedWarehouseOrdersRepository
    implements SuggestedWarehouseOrdersRepository {
  SuggestedWarehouseOrderFilter? lastFilter;
  SuggestedWarehouseOrderConvertRequest? lastRequest;

  @override
  Future<List<SuggestedWarehouseOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedWarehouseOrderFilter filter,
  }) async {
    lastFilter = filter;
    if (filter.sourceWarehouseNo == 56) {
      return const <SuggestedWarehouseOrderListItem>[
        SuggestedWarehouseOrderListItem(
          stockCode: '016167',
          stockName: 'MNV MAYDANOZ ADET',
          modelCode: '12',
          modelName: 'Yesillik',
          barcode: '',
          unitName: 'ADET',
          quantity: 0,
          recommendedQuantity: 0,
          unitPrice: 0,
          unitPointer: 1,
          targetOnHand: 0,
          sourceOnHand: 0,
          salesQuantity: 0,
          openIncomingOrderQuantity: 0,
          packageFactor: 0,
          minDay: 0,
          recommendedDay: 0,
          maxDay: 0,
          recommendedStockQuantity: 0,
          needQuantity: 0,
          suggestedOrderQuantity: 0,
        ),
      ];
    }
    return const <SuggestedWarehouseOrderListItem>[
      SuggestedWarehouseOrderListItem(
        stockCode: '010001',
        stockName: 'Domates',
        modelCode: '01',
        barcode: '8690000000001',
        targetOnHand: 2,
        sourceOnHand: 120,
        salesQuantity: 86,
        openIncomingOrderQuantity: 3,
        packageFactor: 1,
        minDay: 0,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 14,
        needQuantity: 9,
        suggestedOrderQuantity: 9,
      ),
      SuggestedWarehouseOrderListItem(
        stockCode: '010002',
        stockName: 'Biber',
        modelCode: '01',
        barcode: '8690000000002',
        targetOnHand: 4,
        sourceOnHand: 80,
        salesQuantity: 30,
        openIncomingOrderQuantity: 0,
        packageFactor: 1,
        minDay: 0,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 8,
        needQuantity: 4,
        suggestedOrderQuantity: 4,
      ),
    ];
  }

  @override
  Future<WarehouseOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedWarehouseOrderConvertRequest request,
  }) async {
    lastRequest = request;
    return WarehouseOrderCreateResult(
      documentSerie: 'D50',
      documentOrderNo: 91,
      orderDate: request.orderDate,
      deliveryDate: request.deliveryDate,
      inWarehouseNo: 110,
      outWarehouseNo: request.sourceWarehouseNo,
      lineCount: request.lines.length,
      totalQuantity: request.lines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      ),
      writeConnectionName: 'test',
    );
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[
      WarehouseLookupItem(
        warehouseNo: 50,
        warehouseName: 'MERKEZ',
        address: '',
        district: '',
        province: '',
      ),
    ];
  }
}
