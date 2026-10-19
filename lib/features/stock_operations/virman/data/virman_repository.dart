import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_safe_write_recheck.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

abstract class VirmanRepository {
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
  });

  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  });

  Future<VirmanConversionSuggestion> fetchConversionSuggestion({
    required String accessToken,
    required String sourceStockCode,
    required double sourceQuantity,
  });

  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    bool includeDelisted = true,
  });
}

class ApiVirmanRepository
    implements
        VirmanRepository,
        BarcodeResolutionRepository,
        OfflineSyncStatusProvider<VirmanCreateResult>,
        OfflineSyncRecheckProvider<VirmanCreateResult> {
  const ApiVirmanRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  BarcodeResolutionRepository get _barcodeResolutionRepository =>
      ApiBarcodeResolutionRepository(apiClient: _apiClient);

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

  @override
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/virmanlar',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) =>
              VirmanListItem.fromJson(item as JsonMap? ?? <String, dynamic>{}),
        )
        .toList(growable: false);
  }

  @override
  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/virmanlar/$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return VirmanDetail.fromJson(response);
  }

  @override
  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  }) async {
    final response = await _apiClient.postCreateJsonMap(
      '/api/stok-islemleri/virmanlar',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return VirmanCreateResult.fromJson(response);
  }

  @override
  Future<OfflineSyncStatus<VirmanCreateResult>> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/virmanlar/offline-sync/$clientRequestId',
      accessToken: accessToken,
    );
    return OfflineSyncStatus<VirmanCreateResult>.fromJson(
      response,
      resultParser: VirmanCreateResult.fromJson,
    );
  }

  @override
  Future<OfflineSyncStatus<VirmanCreateResult>> recheckOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
    required String operationCode,
  }) {
    return recheckMobileSafeWrite(
      apiClient: _apiClient,
      accessToken: accessToken,
      clientRequestId: clientRequestId,
      operationCode: operationCode,
      resultParser: VirmanCreateResult.fromJson,
    );
  }

  @override
  Future<VirmanConversionSuggestion> fetchConversionSuggestion({
    required String accessToken,
    required String sourceStockCode,
    required double sourceQuantity,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/virmanlar/donusum-onerisi',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'sourceStockCode': sourceStockCode.trim(),
        'sourceQuantity': sourceQuantity.toString(),
      },
    );

    return VirmanConversionSuggestion.fromJson(response);
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
}
