import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';

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
}
