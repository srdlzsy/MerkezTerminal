import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';

abstract class SuggestedCompanyOrdersRepository {
  Future<List<SuggestedCompanyOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedCompanyOrderFilter filter,
  });

  Future<CompanyOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedCompanyOrderConvertRequest request,
  });

  Future<List<CustomerLookupItem>> searchSuppliers({
    required String accessToken,
    required String query,
  });
}

class ApiSuggestedCompanyOrdersRepository
    implements SuggestedCompanyOrdersRepository {
  const ApiSuggestedCompanyOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<SuggestedCompanyOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedCompanyOrderFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/onerilen-firma-siparisleri',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => SuggestedCompanyOrderListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CompanyOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedCompanyOrderConvertRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return CompanyOrderCreateResult.fromJson(response);
  }

  @override
  Future<List<CustomerLookupItem>> searchSuppliers({
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
}
