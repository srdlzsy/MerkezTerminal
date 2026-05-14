import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

abstract class CompanyAcceptancesRepository {
  Future<List<CompanyMovementListItem>> fetchAcceptances({
    required String accessToken,
    required CompanyMovementListFilter filter,
  });

  Future<CompanyMovementDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<CompanyAcceptanceCreateResult> createAcceptance({
    required String accessToken,
    required CompanyAcceptanceCreateRequest request,
  });

  Future<CompanyAcceptanceOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
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

class ApiCompanyAcceptancesRepository implements CompanyAcceptancesRepository {
  const ApiCompanyAcceptancesRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CompanyMovementListItem>> fetchAcceptances({
    required String accessToken,
    required CompanyMovementListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/mal-kabul-islemleri/firma-mal-kabulleri',
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
  Future<CompanyMovementDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/mal-kabul-islemleri/firma-mal-kabulleri/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return CompanyMovementDetail.fromJson(response);
  }

  @override
  Future<CompanyAcceptanceCreateResult> createAcceptance({
    required String accessToken,
    required CompanyAcceptanceCreateRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/mal-kabul-islemleri/firma-mal-kabulleri',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return CompanyAcceptanceCreateResult.fromJson(response);
  }

  @override
  Future<CompanyAcceptanceOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/'
      '$clientRequestId',
      accessToken: accessToken,
    );

    return CompanyAcceptanceOfflineSyncStatus.fromJson(response);
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
}
