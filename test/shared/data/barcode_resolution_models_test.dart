import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';

void main() {
  test('adds source warehouse to barcode resolution query', () {
    const request = BarcodeResolutionRequest(
      barcode: '023127',
      warehouseNo: '110',
      sourceWarehouseNo: '53',
      operationType: 'order',
    );

    expect(
      request.toQueryParameters(),
      containsPair('sourceWarehouseNo', '53'),
    );
  });

  test('reads procurement and source warehouse information', () {
    final result = BarcodeResolutionResult.fromJson(<String, dynamic>{
      'isFound': true,
      'procurementType': 'Mixed',
      'sourceWarehouses': <Map<String, dynamic>>[
        <String, dynamic>{'warehouseNo': 53, 'warehouseName': 'ET DEPO'},
      ],
    });

    expect(result.procurementType, 'Mixed');
    expect(result.sourceWarehouses, hasLength(1));
    expect(result.sourceWarehouses.single.warehouseNo, 53);
    expect(result.sourceWarehouses.single.warehouseName, 'ET DEPO');
  });
}
