import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';

abstract class InventoryCountsRepository {
  Future<List<InventoryCountListItem>> fetchCounts({
    required String accessToken,
    required InventoryCountListFilter filter,
  });

  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  });

  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  });

  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  });

  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  });
}

class ApiInventoryCountsRepository implements InventoryCountsRepository {
  const ApiInventoryCountsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<InventoryCountListItem>> fetchCounts({
    required String accessToken,
    required InventoryCountListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/sayim-sonuclari',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => InventoryCountListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/sayim-sonuclari/$documentNo',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'documentDate': _toApiDate(documentDate),
        'warehouseNo': warehouseNo,
      },
    );

    return InventoryCountDetail.fromJson(response);
  }

  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/stok-islemleri/sayim-sonuclari',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return InventoryCountCreateResult.fromJson(response);
  }

  @override
  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/sayim-sonuclari/offline-sync/$clientRequestId',
      accessToken: accessToken,
    );

    return InventoryCountOfflineSyncStatus.fromJson(response);
  }

  @override
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    final normalizedQuery = query.trim();
    final isBarcodeQuery = RegExp(r'^\d{8,}$').hasMatch(normalizedQuery);
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
          (item) => InventoryCountProductLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }
}

String _toApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');

  return '${normalized.year}-$month-$day';
}
