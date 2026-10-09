import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchConversionSuggestion uses virman suggestion endpoint', () async {
    Uri? requestedUri;
    final repository = ApiVirmanRepository(
      apiClient: ApiClient(
        baseUrl: 'https://terminal.test',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<String, Object?>{
              'sourceStockCode': '015550',
              'sourceQuantity': 6,
              'targetStockCode': '015733',
              'targetStockName': 'SODA TEKLI',
              'targetUnitName': 'ADET',
              'multiplier': 6,
              'targetQuantity': 36,
              'sampleCount': 500,
              'targetMatchCount': 500,
              'multiplierMatchCount': 492,
              'confidencePercent': 98.4,
              'isReliable': true,
              'suggestionSource': 'VirmanHistory',
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      ),
    );

    final suggestion = await repository.fetchConversionSuggestion(
      accessToken: 'token',
      sourceStockCode: '015550',
      sourceQuantity: 6,
    );

    expect(requestedUri?.path, '/api/stok-islemleri/virmanlar/donusum-onerisi');
    expect(requestedUri?.queryParameters['sourceStockCode'], '015550');
    expect(requestedUri?.queryParameters['sourceQuantity'], '6.0');
    expect(suggestion.hasUsableTarget, isTrue);
    expect(suggestion.targetQuantity, 36);
  });
}
