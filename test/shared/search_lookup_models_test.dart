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

  test('barcode resolution keeps package and variable weight metadata', () {
    final resolution = BarcodeResolutionResult.fromJson(<String, dynamic>{
      'isFound': true,
      'barcode': '2700174041103',
      'lookupBarcode': '2700174',
      'stockCode': '015550',
      'stockName': 'SEFTALI KG',
      'matchedUnitName': 'KG',
      'matchedUnitMultiplier': 1,
      'unitsPerCase': 12,
      'isVariableWeightBarcode': true,
      'embeddedQuantity': 4.11,
      'embeddedQuantityUnit': 'KG',
      'isBarcodeCheckDigitValid': true,
    });

    final item = SearchProductLookupItem.fromBarcodeResolution(resolution);

    expect(item.unitMultiplier, 12);
    expect(item.secondaryUnitName, 'KOLI');
    expect(item.secondaryUnitMultiplier, 12);
    expect(item.requestedBarcode, '2700174041103');
    expect(item.lookupBarcode, '2700174');
    expect(item.isVariableWeightBarcode, isTrue);
    expect(item.embeddedQuantity, 4.11);
    expect(item.embeddedQuantityUnit, 'KG');
  });

  test('product lookup reads passive and delisted status', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '000001',
      'stockName': 'URUN',
      'isPassive': true,
      'isDelisted': true,
      'delistReason': 'DLS/99',
    });

    expect(item.isPassive, isTrue);
    expect(item.isDelisted, isTrue);
    expect(item.delistReason, 'DLS/99');
    expect(item.needsStatusAttention, isTrue);
    expect(item.statusWarningLabel, 'Pasif / DLS');
  });

  test('product lookup reads source and procurement information', () {
    final item = SearchProductLookupItem.fromJson(<String, dynamic>{
      'stockCode': '010416',
      'stockName': 'DOMATES',
      'modelCode': '10',
      'procurementType': 'Mixed',
      'hasPurchaseRequirement': true,
      'sourceWarehouses': <Map<String, dynamic>>[
        <String, dynamic>{'warehouseNo': 56, 'warehouseName': 'MANAV DEPO'},
      ],
    });

    expect(item.modelCode, '10');
    expect(item.procurementTypeLabel, 'Karisik Kaynak');
    expect(item.sourceWarehouses.single.warehouseNo, 56);
    expect(item.sourceInformationLabels, <String>[
      'Model 10',
      'MANAV DEPO 56',
      'Karisik Kaynak',
      'Alis Ihtiyaci Var',
    ]);
  });
}
