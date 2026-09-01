import 'package:flutter_test/flutter_test.dart';
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
}
