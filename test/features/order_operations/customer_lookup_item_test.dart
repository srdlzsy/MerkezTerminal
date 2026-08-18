import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';

void main() {
  test('CustomerLookupItem reads selectionLabel and distinguishing fields', () {
    final item = CustomerLookupItem.fromJson(<String, dynamic>{
      'customerCode': '120.01.03106',
      'customerName': 'ORNEK MUSTERI',
      'customerTitle': 'ORNEK MUSTERI SUBE',
      'customerDisplayName': 'ORNEK MUSTERI SUBE',
      'taxNumber': '',
      'taxIdentityNo': '1234567890',
      'taxOfficeName': 'BURSA',
      'groupCode': 'MAGAZA',
      'regionCode': 'GUNEY',
      'representativeName': 'Ad Soyad',
      'sameTaxCustomerCount': 3,
      'selectionLabel':
          '120.01.03106 ORNEK MUSTERI SUBE | VKN/TCKN: 1234567890',
      'isEInvoiceCustomer': true,
      'isEDespatchCustomer': true,
    });

    expect(
      item.displayLabel,
      '120.01.03106 ORNEK MUSTERI SUBE | VKN/TCKN: 1234567890',
    );
    expect(item.lookupTitle, '120.01.03106 - ORNEK MUSTERI SUBE');
    expect(item.displayTaxNumber, '1234567890');
    expect(item.lookupDetailLabel, contains('Vergi 1234567890'));
    expect(item.lookupDetailLabel, contains('Grup MAGAZA'));
    expect(item.lookupDetailLabel, contains('Ayni vergi no: 3 cari'));
    expect(item.isEDespatchCustomer, isTrue);
  });
}
