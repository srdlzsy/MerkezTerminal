import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_safe_write_recheck.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

abstract class GivenWarehouseOrdersRepository
    implements WarehouseOrdersRepository {}

class ApiGivenWarehouseOrdersRepository
    implements
        GivenWarehouseOrdersRepository,
        BarcodeResolutionRepository,
        SourceWarehouseProductsRepository,
        OfflineSyncStatusProvider<WarehouseOrderCreateResult>,
        OfflineSyncRecheckProvider<WarehouseOrderCreateResult> {
  const ApiGivenWarehouseOrdersRepository({required ApiClient apiClient})
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
    final response = await _apiClient.postCreateJsonMap(
      '/api/siparis-islemleri/verilen-depo-siparisleri',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return WarehouseOrderCreateResult.fromJson(response);
  }

  @override
  Future<OfflineSyncStatus<WarehouseOrderCreateResult>> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/siparis-islemleri/verilen-depo-siparisleri/offline-sync/'
      '$clientRequestId',
      accessToken: accessToken,
    );
    return OfflineSyncStatus<WarehouseOrderCreateResult>.fromJson(
      response,
      resultParser: WarehouseOrderCreateResult.fromJson,
    );
  }

  @override
  Future<OfflineSyncStatus<WarehouseOrderCreateResult>>
  recheckOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
    required String operationCode,
  }) {
    return recheckMobileSafeWrite(
      apiClient: _apiClient,
      accessToken: accessToken,
      clientRequestId: clientRequestId,
      operationCode: operationCode,
      resultParser: WarehouseOrderCreateResult.fromJson,
    );
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    final normalizedQuery = query?.trim() ?? '';
    final queryParameters = <String, String>{
      'take': '100',
      if (normalizedQuery.isNotEmpty) 'searchText': normalizedQuery,
    };
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/depolar/kaynaklar',
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
    int? sourceWarehouseNo,
    bool includeDelisted = true,
  }) async {
    final normalizedQuery = query.trim();
    final isBarcodeQuery = RegExp(r'^\d{7,}$').hasMatch(normalizedQuery);
    final isStockCodeQuery =
        !isBarcodeQuery &&
        normalizedQuery.contains(RegExp(r'\d')) &&
        !normalizedQuery.contains(' ');
    final queryParameters = <String, String>{
      'warehouseNo': warehouseNo,
      if (sourceWarehouseNo != null && sourceWarehouseNo > 0)
        'sourceWarehouseNo': sourceWarehouseNo.toString(),
      'take': '150',
      if (!includeDelisted) 'includeDelisted': 'false',
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

  @override
  Future<List<ProductLookupItem>> fetchSourceWarehouseProducts({
    required String accessToken,
    required int sourceWarehouseNo,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'sourceWarehouseNo': sourceWarehouseNo.toString(),
      },
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
