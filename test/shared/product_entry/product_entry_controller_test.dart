import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';

void main() {
  const controller = ProductEntryController();

  test('builds product identity from barcode before stock code', () {
    expect(
      controller.productIdentity(barcode: ' 8691 ', stockCode: 'STK-1'),
      'b:8691',
    );
    expect(
      controller.productIdentity(barcode: '', stockCode: ' STK-1 '),
      's:STK-1',
    );
    expect(controller.productIdentity(barcode: '', stockCode: ''), isNull);
  });

  test('parses and formats terminal quantity values', () {
    expect(controller.readQuantity('12,5', fallback: 0), 12.5);
    expect(controller.readQuantity('x', fallback: 7), 7);
    expect(controller.formatQuantity(12), '12');
    expect(controller.formatQuantity(12.5), '12,5');
    expect(controller.formatQuantity(0.125), '0,125');
  });

  test('uses unit multiplier when quantity input is empty or invalid', () {
    expect(controller.unitMultiplierQuantity(0), 1);
    expect(controller.unitMultiplierQuantity(12), 12);
    expect(controller.quantityInputOrUnitMultiplier('', 12), 12);
    expect(controller.quantityInputOrUnitMultiplier('0', 12), 12);
    expect(controller.quantityInputOrUnitMultiplier('3,5', 12), 3.5);
  });

  test('finds duplicate line using merge policy', () {
    const currentLine = ProductEntryLine(
      barcode: 'new',
      stockCode: 'NEW',
      quantityText: '',
    );
    const duplicate = ProductEntryLine(
      barcode: '8691',
      stockCode: 'STK-1',
      quantityText: '1',
    );
    const blocked = ProductEntryLine(
      barcode: '8691',
      stockCode: 'STK-1',
      quantityText: 'blocked',
    );

    final result = controller.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<ProductEntryLine>(
        currentLine: currentLine,
        targetBarcode: '8691',
        targetStockCode: 'STK-1',
        lines: const <ProductEntryLine>[currentLine, blocked, duplicate],
        lineBarcode: (line) => line.barcode,
        lineStockCode: (line) => line.stockCode,
        canMergeLine: (line) => line.quantityText != 'blocked',
      ),
    );

    expect(result, duplicate);
  });
}
