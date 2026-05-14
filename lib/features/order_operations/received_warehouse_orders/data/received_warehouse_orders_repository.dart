import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';

abstract class ReceivedWarehouseOrdersRepository
    implements WarehouseOrdersRepository {}

class ApiReceivedWarehouseOrdersRepository
    implements ReceivedWarehouseOrdersRepository {
  const ApiReceivedWarehouseOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  bool get supportsCreate => false;

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/alinan-depo-siparisleri',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => WarehouseOrderListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/siparis-islemleri/alinan-depo-siparisleri/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return WarehouseOrderDetail.fromJson(response);
  }

  @override
  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  }) async {
    throw UnsupportedError(
      'Alinan depo siparisleri ekraninda create islemi desteklenmiyor.',
    );
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    throw UnsupportedError(
      'Alinan depo siparisleri ekraninda depo arama desteklenmiyor.',
    );
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    throw UnsupportedError(
      'Alinan depo siparisleri ekraninda urun arama desteklenmiyor.',
    );
  }
}
