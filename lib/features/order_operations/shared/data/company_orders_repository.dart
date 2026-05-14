import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';

abstract class CompanyOrdersRepository {
  bool get supportsCreate;

  Future<List<CompanyOrderListItem>> fetchOrders({
    required String accessToken,
    required CompanyOrderListFilter filter,
  });

  Future<CompanyOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<CompanyOrderCreateResult> createOrder({
    required String accessToken,
    required CompanyOrderCreateRequest request,
  });

  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  });

  Future<List<CompanyOrderProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    required String query,
  });
}
