import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_safe_write_recheck.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

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
    bool includeDelisted = true,
  });

  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  });
}

abstract interface class StockReceiptOfflineSyncStatusProvider {
  Future<OfflineSyncStatus<StockReceiptCreateResult>>
  fetchReceiptOfflineSyncStatus({
    required String accessToken,
    required StockReceiptKind kind,
    required String clientRequestId,
  });
}

class ApiStockReceiptsRepository
    implements
        StockReceiptsRepository,
        StockReceiptOfflineSyncStatusProvider,
        OfflineSyncRecheckProvider<StockReceiptCreateResult> {
  const ApiStockReceiptsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  BarcodeResolutionRepository get _barcodeResolutionRepository =>
      ApiBarcodeResolutionRepository(apiClient: _apiClient);

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
    final response = await _apiClient.postCreateJsonMap(
      '/api/stok-islemleri/${kind.pathSegment}',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return StockReceiptCreateResult.fromJson(response);
  }

  @override
  Future<OfflineSyncStatus<StockReceiptCreateResult>>
  fetchReceiptOfflineSyncStatus({
    required String accessToken,
    required StockReceiptKind kind,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/${kind.pathSegment}/offline-sync/$clientRequestId',
      accessToken: accessToken,
    );
    return OfflineSyncStatus<StockReceiptCreateResult>.fromJson(
      response,
      resultParser: StockReceiptCreateResult.fromJson,
    );
  }

  @override
  Future<OfflineSyncStatus<StockReceiptCreateResult>> recheckOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
    required String operationCode,
  }) {
    return recheckMobileSafeWrite(
      apiClient: _apiClient,
      accessToken: accessToken,
      clientRequestId: clientRequestId,
      operationCode: operationCode,
      resultParser: StockReceiptCreateResult.fromJson,
    );
  }

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    bool includeDelisted = true,
  }) async {
    final normalizedQuery = query.trim();
    final isBarcodeQuery = RegExp(r'^\d{7,}$').hasMatch(normalizedQuery);
    final isStockCodeQuery =
        !isBarcodeQuery &&
        normalizedQuery.contains(RegExp(r'\d')) &&
        !normalizedQuery.contains(' ');

    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/urunler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'warehouseNo': warehouseNo,
        'take': '150',
        if (!includeDelisted) 'includeDelisted': 'false',
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
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) {
    return _barcodeResolutionRepository.resolveBarcode(
      accessToken: accessToken,
      request: request,
    );
  }
}
