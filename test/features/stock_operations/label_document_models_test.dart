import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/models/label_document_models.dart';

void main() {
  test('LabelPriceChangedProduct reads all active barcodes', () {
    final item = LabelPriceChangedProduct.fromJson(<String, dynamic>{
      'productCode': '2900729',
      'productName': 'DOMATES',
      'pluNo': 729,
      'alternativeUnitName': 'KG',
      'barcode': '2900729',
      'barcodes': <Object?>['2900729', '8690000000012', '', null],
      'isDomestic': 1,
      'oldPrice': 10.5,
      'origin': 'BURSA',
      'price': 12.75,
      'priceChangeDate': '2026-08-18',
      'unitPriceFactor': 1,
      'unitName': 'KG',
    });

    expect(item.barcode, '2900729');
    expect(item.barcodes, <String>['2900729', '8690000000012']);
  });
}
