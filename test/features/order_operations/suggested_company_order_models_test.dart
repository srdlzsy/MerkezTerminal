import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';

void main() {
  test('suggested company order reads package factor aliases', () {
    final item = SuggestedCompanyOrderListItem.fromJson(<String, Object?>{
      'supplierCode': '320001',
      'supplierName': 'TEDARIKCI',
      'stockCode': '010001',
      'stockName': 'DOMATES',
      'modelCode': '01',
      'barcode': '8690000000001',
      'targetOnHand': 4,
      'salesQuantity': 10,
      'openCompanyOrderQuantity': 0,
      'unitsPerCase': 12,
      'minDay': 0,
      'recommendedDay': 7,
      'maxDay': 0,
      'recommendedStockQuantity': 18,
      'needQuantity': 14,
      'suggestedOrderQuantity': 24,
      'purchasePrice': 10,
      'minimumPurchaseQuantity': 1,
    });

    expect(item.packageFactor, 12);
  });
}
