import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('searchWarehouses uses source warehouse lookup endpoint', () async {
    Uri? requestedUri;
    final repository = ApiGivenWarehouseOrdersRepository(
      apiClient: ApiClient(
        baseUrl: 'https://terminal.test',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<Map<String, Object?>>[
              <String, Object?>{
                'sourceWarehouseNo': 53,
                'sourceWarehouseName': 'ET-SARKUTERI DEPO',
                'modelCodes': <String>['15', '21'],
                'modelNames': <String>['Et', 'Sarkuteri'],
                'displayName': '53 - ET-SARKUTERI DEPO (Et, Sarkuteri)',
              },
            ]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      ),
    );

    final items = await repository.searchWarehouses(
      accessToken: 'token',
      query: '53',
    );

    expect(requestedUri?.path, '/api/arama-islemleri/depolar/kaynaklar');
    expect(requestedUri?.queryParameters['take'], '100');
    expect(requestedUri?.queryParameters['searchText'], '53');
    expect(requestedUri?.queryParameters.containsKey('warehouseNo'), isFalse);
    expect(items.single.warehouseNo, 53);
    expect(items.single.warehouseName, 'ET-SARKUTERI DEPO');
    expect(items.single.displayLabel, '53 - ET-SARKUTERI DEPO (Et, Sarkuteri)');
  });

  test(
    'fetchSourceWarehouseProducts normalizes negative package factor',
    () async {
      Uri? requestedUri;
      final repository = ApiGivenWarehouseOrdersRepository(
        apiClient: ApiClient(
          baseUrl: 'https://terminal.test',
          httpClient: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              jsonEncode(<Map<String, Object?>>[
                <String, Object?>{
                  'sourceWarehouseNo': 53,
                  'sourceWarehouseName': 'ET-SARKUTERI DEPO',
                  'stockCode': '008748',
                  'stockName': 'KARLIDAG 750GR TUZLU TEREYAG',
                  'modelCode': '15',
                  'modelName': '15',
                  'unitName': 'ADET',
                  'secondaryUnitName': 'KOLI',
                  'packageFactor': -6,
                  'barcode': '8693371319721',
                  'caseBarcode': '',
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

      final items = await repository.fetchSourceWarehouseProducts(
        accessToken: 'token',
        sourceWarehouseNo: 53,
      );

      expect(
        requestedUri?.path,
        '/api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri',
      );
      expect(items.single.stockCode, '008748');
      expect(items.single.unitMultiplier, 6);
      expect(items.single.unitName, 'ADET');
    },
  );
}
