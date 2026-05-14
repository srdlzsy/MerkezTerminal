import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

abstract class StockReceiptsRepository {
  Future<List<StockReceiptListItem>> fetchReceipts({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptListFilter filter,
  });

  Future<StockReceiptDetail> fetchReceiptDetail({
    required String accessToken,
    required StockReceiptKind kind,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<StockReceiptCreateResult> createReceipt({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptCreateRequest request,
  });

  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  });
}

class ApiStockReceiptsRepository implements StockReceiptsRepository {
  const ApiStockReceiptsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<StockReceiptListItem>> fetchReceipts({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/${kind.pathSegment}',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => StockReceiptListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<StockReceiptDetail> fetchReceiptDetail({
    required String accessToken,
    required StockReceiptKind kind,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/${kind.pathSegment}/$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return StockReceiptDetail.fromJson(response);
  }

  @override
  Future<StockReceiptCreateResult> createReceipt({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptCreateRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/stok-islemleri/${kind.pathSegment}',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return StockReceiptCreateResult.fromJson(response);
  }

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
}
