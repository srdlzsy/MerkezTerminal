import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('safe write repositories use documented offline-sync routes', () async {
    final requestedPaths = <String>[];
    final apiClient = ApiClient(
      baseUrl: 'https://terminal.test',
      httpClient: MockClient((request) async {
        requestedPaths.add(request.url.path);
        return http.Response(
          jsonEncode(<String, Object?>{
            'clientRequestId': 'request-1',
            'operationCode': 'test.create',
            'status': 'Failed',
            'errorCode': 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
            'retryable': true,
            'retryAfterSeconds': 5,
            'result': null,
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    await ApiOutgoingWarehouseShipmentsRepository(
      apiClient: apiClient,
    ).fetchOfflineSyncStatus(
      accessToken: 'token',
      clientRequestId: 'request-1',
    );
    await ApiWarehouseReturnsRepository(
      apiClient: apiClient,
    ).fetchOfflineSyncStatus(
      accessToken: 'token',
      clientRequestId: 'request-1',
    );
    await ApiCompanyMovementsRepository(
      apiClient: apiClient,
      listPath: '/api/sevk-islemleri/firma-sevkleri/giden',
      detailPathPrefix: '/api/sevk-islemleri/firma-sevkleri/giden',
      supportsCreate: true,
      supportsEDespatch: true,
    ).fetchOfflineSyncStatus(
      accessToken: 'token',
      clientRequestId: 'request-1',
    );
    await ApiCompanyMovementsRepository(
      apiClient: apiClient,
      listPath: '/api/iade-islemleri/firma-iadeleri',
      detailPathPrefix: '/api/iade-islemleri/firma-iadeleri',
      supportsCreate: true,
      supportsEDespatch: true,
    ).fetchOfflineSyncStatus(
      accessToken: 'token',
      clientRequestId: 'request-1',
    );
    final stockReceipts = ApiStockReceiptsRepository(apiClient: apiClient);
    await stockReceipts.fetchReceiptOfflineSyncStatus(
      accessToken: 'token',
      kind: StockReceiptKind.outage,
      clientRequestId: 'request-1',
    );
    await stockReceipts.fetchReceiptOfflineSyncStatus(
      accessToken: 'token',
      kind: StockReceiptKind.expense,
      clientRequestId: 'request-1',
    );
    await ApiVirmanRepository(apiClient: apiClient).fetchOfflineSyncStatus(
      accessToken: 'token',
      clientRequestId: 'request-1',
    );

    expect(requestedPaths, <String>[
      '/api/sevk-islemleri/depolar-arasi-sevkler/giden/offline-sync/request-1',
      '/api/iade-islemleri/depo-iadeleri/giden/offline-sync/request-1',
      '/api/sevk-islemleri/firma-sevkleri/giden/offline-sync/request-1',
      '/api/iade-islemleri/firma-iadeleri/offline-sync/request-1',
      '/api/stok-islemleri/zayiat-fisleri/offline-sync/request-1',
      '/api/stok-islemleri/masraf-fisleri/offline-sync/request-1',
      '/api/stok-islemleri/virmanlar/offline-sync/request-1',
    ]);
  });
}
