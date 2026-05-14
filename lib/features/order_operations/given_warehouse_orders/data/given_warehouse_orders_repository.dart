import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';

abstract class GivenWarehouseOrdersRepository
    implements WarehouseOrdersRepository {}

class ApiGivenWarehouseOrdersRepository
    implements GivenWarehouseOrdersRepository {
  const ApiGivenWarehouseOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  bool get supportsCreate => true;

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/verilen-depo-siparisleri',
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
      '/api/siparis-islemleri/verilen-depo-siparisleri/'
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
    final response = await _apiClient.postJsonMap(
      '/api/siparis-islemleri/verilen-depo-siparisleri',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return WarehouseOrderCreateResult.fromJson(response);
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    final normalizedQuery = query?.trim() ?? '';
    final queryParameters = <String, String>{
      'take': '100',
      if (normalizedQuery.isNotEmpty && RegExp(r'^\d+$').hasMatch(normalizedQuery))
        'warehouseNo': normalizedQuery
      else if (normalizedQuery.isNotEmpty)
        'searchText': normalizedQuery,
    };
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/depolar',
      accessToken: accessToken,
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => WarehouseLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    final normalizedQuery = query.trim();
    final isBarcodeQuery =
        RegExp(r'^\d{8,}$').hasMatch(normalizedQuery);
    final isStockCodeQuery =
        !isBarcodeQuery &&
        normalizedQuery.contains(RegExp(r'\d')) &&
        !normalizedQuery.contains(' ');
    final queryParameters = <String, String>{
      'warehouseNo': warehouseNo,
      'take': '20',
      if (isBarcodeQuery)
        'barcode': normalizedQuery
      else if (isStockCodeQuery)
        'stockCode': normalizedQuery
      else
        'stockName': normalizedQuery,
    };
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/urunler',
      accessToken: accessToken,
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => ProductLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }
}
