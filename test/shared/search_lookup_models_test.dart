import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

void main() {
  test('product lookup reads package factor as unit multiplier', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '008748',
      'stockName': 'KARLIDAG 750GR TUZLU TEREYAG',
      'unitName': 'ADET',
      'packageFactor': -6,
    });

    expect(item.unitMultiplier, 6);
  });

  test('product lookup falls back to secondary unit multiplier', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '008748',
      'stockName': 'KARLIDAG 750GR TUZLU TEREYAG',
      'unitName': 'ADET',
      'secondaryUnitMultiplier': 6,
    });

    expect(item.unitMultiplier, 6);
  });

  test('company acceptance price uses purchase price, not sales price', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '000001',
      'stockName': 'URUN',
      'price': 125,
      'purchasePrice': 75,
    });

    expect(item.price, 125);
    expect(item.purchasePrice, 75);
    expect(item.companyAcceptanceUnitPrice, 75);
  });

  test('company acceptance price stays zero when only sales price exists', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '000001',
      'stockName': 'URUN',
      'price': 125,
    });

    expect(item.price, 125);
    expect(item.companyAcceptanceUnitPrice, 0);
  });

  test('product lookup keeps purchase price from barcode resolution', () {
    final resolution = BarcodeResolutionResult.fromJson(<String, dynamic>{
      'isFound': true,
      'stockCode': '000001',
      'stockName': 'URUN',
      'salesPrice': 125,
      'purchasePrice': 75,
      'purchaseGrossPrice': 90,
      'purchasePriceSource': 'LastPurchase',
      'purchaseSupplierCode': 'C001',
      'matchedUnitName': 'ADET',
      'matchedUnitMultiplier': 1,
      'unitsPerCase': 1,
    });
    final item = SearchProductLookupItem.fromBarcodeResolution(resolution);

    expect(item.price, 125);
    expect(item.purchasePrice, 75);
    expect(item.purchaseGrossPrice, 90);
    expect(item.purchasePriceSource, 'LastPurchase');
    expect(item.purchaseSupplierCode, 'C001');
    expect(item.companyAcceptanceUnitPrice, 75);
  });
}
