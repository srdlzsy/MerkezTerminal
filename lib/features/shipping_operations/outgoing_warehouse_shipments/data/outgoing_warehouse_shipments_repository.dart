import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

abstract class OutgoingWarehouseShipmentsRepository {
  bool get supportsEDespatch;

  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  });

  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  });

  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  });

  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
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

class ApiOutgoingWarehouseShipmentsRepository
    implements OutgoingWarehouseShipmentsRepository {
  const ApiOutgoingWarehouseShipmentsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  bool get supportsEDespatch => true;

  @override
  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => WarehouseShipmentListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return WarehouseShipmentDetail.fromJson(response);
  }

  @override
  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return WarehouseShipmentCreateResult.fromJson(response);
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden/'
      '$documentSerie/$documentOrderNo/e-irsaliye',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
      body: request.toJson(),
    );

    return EDespatchSendResult.fromJson(response);
  }

  @override
  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getBytes(
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden/'
      '$documentSerie/$documentOrderNo/e-irsaliye/pdf',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return WarehouseShipmentPdfDocument(
      fileName: _resolveFileName(
        response,
        fallback: '${documentSerie}_$documentOrderNo-e-irsaliye.pdf',
      ),
      bytes: response.bodyBytes,
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
      if (normalizedQuery.isNotEmpty &&
          RegExp(r'^\d+$').hasMatch(normalizedQuery))
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
          (item) => ProductLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  String _resolveFileName(
    ApiBinaryResponse response, {
    required String fallback,
  }) {
    final disposition = response.contentDisposition ?? '';
    final encodedMatch = RegExp(
      "filename\\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);

    if (encodedMatch != null) {
      return Uri.decodeComponent(encodedMatch.group(1) ?? fallback);
    }

    final quotedMatch = RegExp(
      'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);

    if (quotedMatch != null) {
      return quotedMatch.group(1) ?? fallback;
    }

    final plainMatch = RegExp(
      'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);

    if (plainMatch != null) {
      return plainMatch.group(1)?.trim() ?? fallback;
    }

    return fallback;
  }
}
