import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses company acceptance e-despatch prefill response', () {
    final prefill = CompanyAcceptanceEDespatchPrefill.fromJson(
      <String, dynamic>{
        'isFound': true,
        'warehouseNo': 110,
        'receivingContext': 'firma-mal-kabulleri',
        'ettn': '3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
        'despatchNumber': 'IRS2026000001234',
        'issueDate': '2026-05-06T00:00:00',
        'notes': <String>['Sofor bilgisi kagit irsaliyede ayrica yaziyor.'],
        'sender': <String, dynamic>{
          'title': 'ORNEK TEDARIKCI A.S.',
          'taxNoOrTckn': '1234567890',
          'alias': 'urn:mail:ornek@firma.com',
          'city': 'ISTANBUL',
        },
        'receiver': <String, dynamic>{
          'title': 'FURPA KESTEL 1',
          'taxNoOrTckn': '0987654321',
          'alias': 'urn:mail:kestel1@furpa.com',
          'city': 'BURSA',
        },
        'primaryCustomerSuggestion': <String, dynamic>{
          'customerCode': '120.01.03106',
          'customerName': 'ORNEK TEDARIKCI A.S.',
          'taxNoOrTckn': '1234567890',
          'matchReason': 'vkn-tckn',
          'isPrimarySuggestion': true,
        },
        'totalLineCount': 2,
        'matchedLineCount': 1,
        'unmatchedLineCount': 1,
        'suggestedCustomers': <dynamic>[],
        'lines': <dynamic>[
          <String, dynamic>{
            'lineNo': 1,
            'productName': 'Stok Adi',
            'description': 'Kolili urun',
            'quantity': 12,
            'unitCode': 'C62',
            'buyerItemCode': '015792',
            'sellerItemCode': 'TED-015792',
            'manufacturerItemCode': null,
            'barcode': '8690000000000',
            'internalStockCode': '015792',
            'internalStockName': 'Stok Adi',
            'matchReason': 'buyer-item-code',
            'isMatched': true,
            'isGoodsAcceptanceBlocked': false,
            'canUseForGoodsAcceptance': true,
          },
          <String, dynamic>{
            'lineNo': 2,
            'productName': 'Dis Kaynakli Urun',
            'description': 'Ic stok kodu tutmuyor',
            'quantity': 5,
            'unitCode': 'C62',
            'buyerItemCode': null,
            'sellerItemCode': 'TED-009999',
            'manufacturerItemCode': null,
            'barcode': '9999999999999',
            'internalStockCode': null,
            'internalStockName': null,
            'matchReason': null,
            'isMatched': false,
            'isGoodsAcceptanceBlocked': false,
            'canUseForGoodsAcceptance': false,
          },
        ],
      },
    );

    expect(prefill.isFound, isTrue);
    expect(prefill.despatchNumber, 'IRS2026000001234');
    expect(prefill.issueDate, DateTime(2026, 5, 6));
    expect(prefill.primaryCustomerSuggestion?.customerCode, '120.01.03106');
    expect(prefill.lines.first.hasUsableInternalStock, isTrue);
    expect(prefill.lines.last.hasUsableInternalStock, isFalse);
    expect(prefill.lines.last.externalDisplayLabel, contains('TED-009999'));
  });

  test(
    'requests official document lookup with invoice fallback enabled',
    () async {
      Uri? capturedUri;
      final repository = ApiCompanyAcceptancesRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((request) async {
            capturedUri = request.url;
            return http.Response(
              '''
{
  "isFound": false,
  "warehouseNo": 110,
  "receivingContext": "firma-mal-kabulleri",
  "ettn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "sourceDocumentKind": "auto",
  "sourceDocumentLabel": "E-Belge",
  "warnings": ["Uyumsoft gelen e-irsaliye ve e-fatura kutusunda belge bulunamadi."],
  "totalLineCount": 0,
  "matchedLineCount": 0,
  "unmatchedLineCount": 0,
  "suggestedCustomers": [],
  "lines": []
}
''',
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }),
        ),
      );

      final prefill = await repository.resolveEDespatchByEttn(
        accessToken: 'token',
        warehouseNo: '110',
        ettn: '3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
      );

      expect(
        capturedUri?.path,
        '/api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
      );
      expect(capturedUri?.queryParameters['warehouseNo'], '110');
      expect(capturedUri?.queryParameters['documentKind'], 'auto');
      expect(prefill.effectiveDocumentLabel, 'E-Belge');
      expect(prefill.warnings.single, contains('e-fatura'));
    },
  );

  test('parses invoice fallback prefill response', () {
    final prefill = CompanyAcceptanceEDespatchPrefill.fromJson(
      <String, dynamic>{
        'isFound': true,
        'warehouseNo': 110,
        'receivingContext': 'firma-mal-kabulleri',
        'ettn': '2f2a4fd7-7811-43f2-b5ca-3fd0e4f487a2',
        'sourceDocumentKind': 'e-invoice',
        'sourceDocumentLabel': 'E-Fatura',
        'sourceDocumentNumber': 'FTR2026000000456',
        'despatchNumber': 'FTR2026000000456',
        'issueDate': '2026-05-06T00:00:00',
        'invoiceNumber': 'FTR2026000000456',
        'invoiceDate': '2026-05-07T00:00:00',
        'invoiceTotal': 11800.0,
        'taxExclusiveAmount': 10000.0,
        'taxTotal': 1800.0,
        'currencyCode': 'TRY',
        'despatchReferences': <String>['IRS2026000000123'],
        'warnings': <String>['Belge e-fatura olarak bulundu.'],
        'sender': <String, dynamic>{},
        'receiver': <String, dynamic>{},
        'primaryCustomerSuggestion': null,
        'totalLineCount': 1,
        'matchedLineCount': 1,
        'unmatchedLineCount': 0,
        'suggestedCustomers': <dynamic>[],
        'lines': <dynamic>[
          <String, dynamic>{
            'lineNo': 1,
            'productName': 'Stok Adi',
            'quantity': 10,
            'unitCode': 'KGM',
            'internalStockCode': '015792',
            'internalStockName': 'Stok Adi',
            'isMatched': true,
            'canUseForGoodsAcceptance': true,
            'unitPrice': 1000.0,
            'lineAmount': 10000.0,
            'quantitySource': 'invoice',
          },
        ],
      },
    );

    expect(prefill.isInvoice, isTrue);
    expect(prefill.effectiveDocumentLabel, 'E-Fatura');
    expect(prefill.effectiveDocumentNumber, 'FTR2026000000456');
    expect(prefill.effectiveDocumentDate, DateTime(2026, 5, 7));
    expect(prefill.invoiceTotal, 11800);
    expect(prefill.despatchReferences.single, 'IRS2026000000123');
    expect(prefill.lines.single.quantitySource, 'invoice');
    expect(prefill.lines.single.unitPrice, 1000);
    expect(prefill.lines.single.lineAmount, 10000);
  });
}
