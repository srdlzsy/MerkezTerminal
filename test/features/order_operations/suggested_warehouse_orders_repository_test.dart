import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('searchWarehouses uses source warehouse lookup endpoint', () async {
    Uri? requestedUri;
    final repository = ApiSuggestedWarehouseOrdersRepository(
      apiClient: ApiClient(
        baseUrl: 'https://terminal.test',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<Map<String, Object?>>[
              <String, Object?>{
                'sourceWarehouseNo': 56,
                'sourceWarehouseName': 'MANAV DEPO',
                'modelCodes': <String>['10', '11', '12', '23'],
                'modelNames': <String>['Meyve', 'Sebze', 'Yesillik'],
                'displayName': '56 - MANAV DEPO (Meyve, Sebze, Yesillik)',
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
      query: 'manav',
    );

    expect(requestedUri?.path, '/api/arama-islemleri/depolar/kaynaklar');
    expect(requestedUri?.queryParameters['take'], '100');
    expect(requestedUri?.queryParameters['searchText'], 'manav');
    expect(requestedUri?.queryParameters.containsKey('warehouseNo'), isFalse);
    expect(items.single.warehouseNo, 56);
    expect(items.single.warehouseName, 'MANAV DEPO');
    expect(
      items.single.displayLabel,
      '56 - MANAV DEPO (Meyve, Sebze, Yesillik)',
    );
    expect(items.single.modelCodes, <String>['10', '11', '12', '23']);
    expect(items.single.modelNames, <String>['Meyve', 'Sebze', 'Yesillik']);
  });

  test('warehouse lookup item keeps legacy response compatibility', () {
    final item = WarehouseLookupItem.fromJson(<String, dynamic>{
      'warehouseNo': 50,
      'warehouseName': 'MERKEZ DEPO',
      'address': 'Adres',
      'district': 'Nilufer',
      'province': 'Bursa',
    });

    expect(item.warehouseNo, 50);
    expect(item.warehouseName, 'MERKEZ DEPO');
    expect(item.displayLabel, '50 - MERKEZ DEPO');
    expect(item.modelCodes, isEmpty);
  });

  test(
    'fetchSuggestions uses source product endpoint for warehouse 56',
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
                  'sourceWarehouseNo': 56,
                  'sourceWarehouseName': 'MANAV DEPO',
                  'stockCode': '016167',
                  'stockName': 'MNV MAYDANOZ ADET',
                  'modelCode': '12',
                  'modelName': 'Yesillik',
                  'unitName': 'ADET',
                  'secondaryUnitName': 'KOLI',
                  'barcode': '2900729',
                  'caseBarcode': '1290072900000',
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
        filter: const SuggestedWarehouseOrderFilter(
          sourceWarehouseNo: 56,
          useSourceProducts: true,
        ),
      );

      expect(
        requestedUri?.path,
        '/api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri',
      );
      expect(requestedUri?.queryParameters['sourceWarehouseNo'], '56');
      expect(items.single.sourceWarehouseNo, 56);
      expect(items.single.sourceWarehouseName, 'MANAV DEPO');
      expect(items.single.stockCode, '016167');
      expect(items.single.barcode, '2900729');
      expect(items.single.secondaryUnitName, 'KOLI');
      expect(items.single.caseBarcode, '1290072900000');
      expect(items.single.needsManualQuantity, isTrue);
    },
  );

  test(
    'fetchSuggestions keeps classic endpoint for normal source warehouse',
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
                  'stockCode': '010001',
                  'stockName': 'DOMATES',
                  'modelCode': '01',
                  'barcode': '8690000000001',
                  'targetOnHand': 2,
                  'sourceOnHand': 120,
                  'salesQuantity': 86,
                  'openIncomingOrderQuantity': 3,
                  'unitsPerCase': 5,
                  'minDay': 0,
                  'recommendedDay': 7,
                  'maxDay': 0,
                  'recommendedStockQuantity': 14,
                  'needQuantity': 9,
                  'suggestedOrderQuantity': 9,
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
        filter: const SuggestedWarehouseOrderFilter(sourceWarehouseNo: 50),
      );

      expect(
        requestedUri?.path,
        '/api/siparis-islemleri/onerilen-depo-siparisleri',
      );
      expect(requestedUri?.queryParameters['SourceWarehouseNo'], '50');
      expect(items.single.stockCode, '010001');
      expect(items.single.packageFactor, 5);
      expect(items.single.needsManualQuantity, isFalse);
    },
  );
}
