import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('searchStockAvailability uses var yok endpoint for barcode', () async {
    Uri? requestedUri;
    final repository = ApiLegacyToolsRepository(
      apiClient: ApiClient(
        baseUrl: 'https://terminal.test',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<Map<String, Object?>>[
              <String, Object?>{
                'warehouseNo': 110,
                'warehouseName': 'KESTEL 1',
                'barcode': '2700174',
                'stockCode': '015550',
                'stockName': 'MNV SEFTALI KG',
                'unitName': 'KG',
                'currentStockQuantity': 24.75,
                'hasStock': true,
                'price': 99.9,
                'priceTypeCode': 1,
                'secondaryUnitName': 'KOLI',
                'secondaryUnitMultiplier': 12,
                'salesBlockCode': 0,
                'orderBlockCode': 0,
                'goodsAcceptanceBlockCode': 0,
                'isSalesBlocked': false,
                'isOrderBlocked': false,
                'isGoodsAcceptanceBlocked': false,
                'productManagerCode': 'PER001',
                'requestedBarcode': '2700174041103',
                'lookupBarcode': '2700174',
                'isVariableWeightBarcode': true,
                'embeddedQuantity': 4.11,
                'embeddedQuantityUnit': 'KG',
                'isBarcodeCheckDigitValid': true,
              },
            ]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      ),
    );

    final items = await repository.searchStockAvailability(
      accessToken: 'token',
      warehouseNo: '110',
      query: '2700174041103',
    );

    expect(requestedUri?.path, '/api/arama-islemleri/var-yok');
    expect(requestedUri?.queryParameters['warehouseNo'], '110');
    expect(requestedUri?.queryParameters['barcode'], '2700174041103');
    expect(requestedUri?.queryParameters['take'], '20');
    expect(items.single.stockCode, '015550');
    expect(items.single.currentStockQuantity, 24.75);
    expect(items.single.hasStock, isTrue);
    expect(items.single.warehouseName, 'KESTEL 1');
    expect(items.single.lookupBarcode, '2700174');
    expect(items.single.embeddedQuantity, 4.11);
    expect(items.single.isBarcodeCheckDigitValid, isTrue);
  });
}
