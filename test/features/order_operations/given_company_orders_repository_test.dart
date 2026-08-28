import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchCustomerProducts uses customer products endpoint', () async {
    Uri? requestedUri;
    final repository = ApiGivenCompanyOrdersRepository(
      apiClient: ApiClient(
        baseUrl: 'https://terminal.test',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<Map<String, Object?>>[
              <String, Object?>{
                'warehouseNo': 110,
                'customerCode': '32000999',
                'customerName': 'TEDARIKCI A.S.',
                'stockCode': '010001',
                'stockName': 'Stok Adi',
                'unitName': 'AD',
                'secondaryUnitName': 'KOLI',
                'packageFactor': 12,
                'barcode': '8690000000001',
                'caseBarcode': '18690000000018',
                'quantity': 0,
                'recommendedQuantity': 0,
                'unitPrice': 15.75,
                'minimumPurchaseQuantity': 24,
                'deliveryDay': 2,
                'unitPointer': 2,
              },
            ]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      ),
    );

    final items = await repository.fetchCustomerProducts(
      accessToken: 'token',
      warehouseNo: '110',
      customerCode: '32000999',
      search: 'sut',
      take: 100,
    );

    expect(
      requestedUri?.path,
      '/api/siparis-islemleri/verilen-firma-siparisleri/firma-urunleri',
    );
    expect(requestedUri?.queryParameters['customerCode'], '32000999');
    expect(requestedUri?.queryParameters['warehouseNo'], '110');
    expect(requestedUri?.queryParameters['search'], 'sut');
    expect(requestedUri?.queryParameters['take'], '100');
    expect(items.single.stockCode, '010001');
    expect(items.single.price, 15.75);
    expect(items.single.unitMultiplier, 12);
    expect(items.single.secondaryUnitName, 'KOLI');
    expect(items.single.caseBarcode, '18690000000018');
    expect(items.single.minimumPurchaseQuantity, 24);
    expect(items.single.deliveryDay, 2);
    expect(items.single.unitPointer, 2);
  });
}
