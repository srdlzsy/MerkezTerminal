import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';

void main() {
  test('warehouse order product exposes source information labels', () {
    final item = ProductLookupItem.fromJson(<String, dynamic>{
      'warehouseNo': 120,
      'stockCode': '010416',
      'stockName': 'DOMATES',
      'modelCode': '10',
      'procurementType': 'Warehouse',
      'hasPurchaseRequirement': false,
      'sourceWarehouses': <Map<String, dynamic>>[
        <String, dynamic>{'warehouseNo': 56, 'warehouseName': 'MANAV DEPO'},
      ],
    });

    expect(item.procurementTypeLabel, 'Depo Urunu');
    expect(item.sourceInformationLabels, <String>[
      'Model 10',
      'MANAV DEPO 56',
      'Depo Urunu',
    ]);
  });
}
