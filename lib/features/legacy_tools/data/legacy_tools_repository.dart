import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

abstract class LegacyToolsRepository {
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  });

  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  });

  Future<JsonMap> getPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
  });

  Future<JsonMap> addPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
    required String packageBarcode,
  });

  Future<JsonMap> getCurrentProductByBarcode({
    required String accessToken,
    required String barcode,
  });

  Future<JsonMap> updateProductForPiecesInBox({
    required String accessToken,
    required String stockCode,
    required String barcode,
    required int piecesInBox,
  });
}

class ApiLegacyToolsRepository implements LegacyToolsRepository {
  const ApiLegacyToolsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
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

    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/urunler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'warehouseNo': warehouseNo,
        'take': '20',
        if (isBarcodeQuery)
          'barcode': normalizedQuery
        else if (isStockCodeQuery)
          'stockCode': normalizedQuery
        else
          'stockName': normalizedQuery,
      },
    );

    return response
        .map(
          (item) => SearchProductLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/cariler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'searchText': query.trim(),
        'take': '20',
      },
    );

    return response
        .map(
          (item) => CustomerLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<JsonMap> getPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
  }) {
    return _apiClient.getJsonMap(
      '/api/ProductBarcodes/GetPackageBarcodeForProduct',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'barcode': barcode,
        'productCode': productCode,
      },
    );
  }

  @override
  Future<JsonMap> addPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
    required String packageBarcode,
  }) {
    return _apiClient.postJsonMap(
      '/api/ProductBarcodes/AddPackageBarcodeForProduct',
      accessToken: accessToken,
      body: <String, dynamic>{
        'barcode': barcode,
        'productCode': productCode,
        'packageBarcode': packageBarcode,
      },
    );
  }

  @override
  Future<JsonMap> getCurrentProductByBarcode({
    required String accessToken,
    required String barcode,
  }) {
    return _apiClient.getJsonMap(
      '/api/products/GetCurrentByBarcode',
      accessToken: accessToken,
      queryParameters: <String, String>{'barcode': barcode},
    );
  }

  @override
  Future<JsonMap> updateProductForPiecesInBox({
    required String accessToken,
    required String stockCode,
    required String barcode,
    required int piecesInBox,
  }) {
    return _apiClient.postJsonMap(
      '/api/Products/UpdateProductForPiecesInBox',
      accessToken: accessToken,
      body: <String, dynamic>{
        'stockCode': stockCode,
        'barcode': barcode,
        'piecesInBox': piecesInBox,
      },
    );
  }
}
