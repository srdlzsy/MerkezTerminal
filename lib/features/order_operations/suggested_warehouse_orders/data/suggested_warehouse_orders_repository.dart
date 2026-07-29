import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';

abstract class SuggestedWarehouseOrdersRepository {
  Future<List<SuggestedWarehouseOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedWarehouseOrderFilter filter,
  });

  Future<WarehouseOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedWarehouseOrderConvertRequest request,
  });

  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  });
}

class ApiSuggestedWarehouseOrdersRepository
    implements SuggestedWarehouseOrdersRepository {
  const ApiSuggestedWarehouseOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<SuggestedWarehouseOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedWarehouseOrderFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/onerilen-depo-siparisleri',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => SuggestedWarehouseOrderListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WarehouseOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedWarehouseOrderConvertRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order',
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
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/depolar',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'take': '100',
        if (normalizedQuery.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(normalizedQuery))
          'warehouseNo': normalizedQuery
        else if (normalizedQuery.isNotEmpty)
          'searchText': normalizedQuery,
      },
    );

    return response
        .map(
          (item) => WarehouseLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }
}
