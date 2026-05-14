import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

abstract class CompanyMovementsRepository {
  bool get supportsCreate;
  bool get supportsEDespatch;

  Future<List<CompanyMovementListItem>> fetchMovements({
    required String accessToken,
    required CompanyMovementListFilter filter,
  });

  Future<CompanyMovementDetail> fetchMovementDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<CompanyMovementCreateResult> createMovement({
    required String accessToken,
    required CompanyMovementCreateRequest request,
  });

  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  });

  Future<CompanyMovementPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  });

  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    String? customerCode,
  });
}

class ApiCompanyMovementsRepository implements CompanyMovementsRepository {
  const ApiCompanyMovementsRepository({
    required ApiClient apiClient,
    required String listPath,
    required String detailPathPrefix,
    required bool supportsCreate,
    required bool supportsEDespatch,
  }) : _apiClient = apiClient,
       _listPath = listPath,
       _detailPathPrefix = detailPathPrefix,
       _supportsCreate = supportsCreate,
       _supportsEDespatch = supportsEDespatch;

  final ApiClient _apiClient;
  final String _listPath;
  final String _detailPathPrefix;
  final bool _supportsCreate;
  final bool _supportsEDespatch;

  @override
  bool get supportsCreate => _supportsCreate;

  @override
  bool get supportsEDespatch => _supportsEDespatch;

  @override
  Future<List<CompanyMovementListItem>> fetchMovements({
    required String accessToken,
    required CompanyMovementListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      _listPath,
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => CompanyMovementListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CompanyMovementDetail> fetchMovementDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '$_detailPathPrefix/$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return CompanyMovementDetail.fromJson(response);
  }

  @override
  Future<CompanyMovementCreateResult> createMovement({
    required String accessToken,
    required CompanyMovementCreateRequest request,
  }) async {
    if (!_supportsCreate) {
      throw UnsupportedError('Bu ekranda create desteklenmiyor.');
    }

    final response = await _apiClient.postJsonMap(
      _listPath,
      accessToken: accessToken,
      body: request.toJson(),
    );

    return CompanyMovementCreateResult.fromJson(response);
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) async {
    if (!_supportsEDespatch) {
      throw UnsupportedError('Bu ekranda e-irsaliye desteklenmiyor.');
    }

    final response = await _apiClient.postJsonMap(
      '$_detailPathPrefix/$documentSerie/$documentOrderNo/e-irsaliye',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
      body: request.toJson(),
    );

    return EDespatchSendResult.fromJson(response);
  }

  @override
  Future<CompanyMovementPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    if (!_supportsEDespatch) {
      throw UnsupportedError('Bu ekranda PDF desteklenmiyor.');
    }

    final response = await _apiClient.getBytes(
      '$_detailPathPrefix/$documentSerie/$documentOrderNo/e-irsaliye/pdf',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return CompanyMovementPdfDocument(
      fileName: _resolveFileName(
        response,
        fallback: '${documentSerie}_$documentOrderNo-e-irsaliye.pdf',
      ),
      bytes: response.bodyBytes,
    );
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    final normalizedQuery = query.trim();
    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/cariler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'searchText': normalizedQuery,
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
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    String? customerCode,
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
        if (customerCode != null && customerCode.trim().isNotEmpty)
          'companyCode': customerCode.trim(),
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

  String _resolveFileName(ApiBinaryResponse response, {required String fallback}) {
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

    return fallback;
  }
}
