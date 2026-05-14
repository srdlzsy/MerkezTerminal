import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';

abstract class WarehouseOrdersRepository {
  bool get supportsCreate;

  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  });

  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  });

  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  });

  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  });
}
