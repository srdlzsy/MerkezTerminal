import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'fetchSuggestions uses green grocer endpoint for warehouse 56',
    () async {
      Uri? requestedUri;
      final repository = ApiSuggestedWarehouseOrdersRepository(
        apiClient: ApiClient(
          baseUrl: 'https://terminal.test',
          httpClient: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              jsonEncode(<Map<String, Object?>>[
                <String, Object?>{
                  'stockCode': '016167',
                  'stockName': 'MNV MAYDANOZ ADET',
                  'modelCode': '12',
                  'modelName': 'Yesillik',
                  'unitName': 'ADET',
                  'quantity': 0,
                  'recommendedQuantity': 0,
                  'unitPrice': 0,
                  'unitPointer': 1,
                },
              ]),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }),
        ),
      );

      final items = await repository.fetchSuggestions(
        accessToken: 'token',
        filter: const SuggestedWarehouseOrderFilter(sourceWarehouseNo: 56),
      );

      expect(
        requestedUri?.path,
        '/api/siparis-islemleri/onerilen-depo-siparisleri/manav',
      );
      expect(requestedUri?.query, isEmpty);
      expect(items.single.stockCode, '016167');
      expect(items.single.needsManualQuantity, isTrue);
    },
  );
}
