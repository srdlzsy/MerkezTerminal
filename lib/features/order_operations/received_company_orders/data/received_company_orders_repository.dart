import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/company_orders_repository.dart';

abstract class ReceivedCompanyOrdersRepository
    implements CompanyOrdersRepository {}

class ApiReceivedCompanyOrdersRepository
    implements ReceivedCompanyOrdersRepository {
  const ApiReceivedCompanyOrdersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  bool get supportsCreate => false;

  @override
  Future<List<CompanyOrderListItem>> fetchOrders({
    required String accessToken,
    required CompanyOrderListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/siparis-islemleri/alinan-firma-siparisleri',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => CompanyOrderListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CompanyOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/siparis-islemleri/alinan-firma-siparisleri/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return CompanyOrderDetail.fromJson(response);
  }

  @override
  Future<CompanyOrderCreateResult> createOrder({
    required String accessToken,
    required CompanyOrderCreateRequest request,
  }) async {
    throw UnsupportedError(
      'Alinan firma siparisleri ekraninda create islemi desteklenmiyor.',
    );
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    throw UnsupportedError(
      'Alinan firma siparisleri ekraninda cari arama desteklenmiyor.',
    );
  }

  @override
  Future<List<CompanyOrderProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    required String query,
  }) async {
    throw UnsupportedError(
      'Alinan firma siparisleri ekraninda urun arama desteklenmiyor.',
    );
  }
}
