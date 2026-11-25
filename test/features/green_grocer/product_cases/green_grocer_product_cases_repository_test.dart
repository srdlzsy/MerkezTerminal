import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/green_grocer/product_cases/data/green_grocer_product_cases_repository.dart';

void main() {
  test('legacy resolution response uses safe shipment tolerance defaults', () {
    final result = GreenGrocerProductCaseResolutionResult.fromJson(
      const <String, dynamic>{
        'stockCode': '016167',
        'stockName': 'MNV MAYDANOZ ADET',
      },
    );

    expect(result.overDeliveryTolerancePercent, 20);
    expect(result.severeOverDeliveryMultiplier, 1.5);
  });

  test('legacy capabilities response uses safe tolerance defaults', () {
    final capabilities = GreenGrocerProductCaseCapabilities.fromJson(
      const <String, dynamic>{
        'enabled': true,
        'orderLinkingEnabled': true,
        'sourceWarehouseNo': 56,
      },
    );

    expect(capabilities.defaultOverDeliveryTolerancePercent, 20);
    expect(capabilities.severeOverDeliveryMultiplier, 1.5);
    expect(capabilities.modelCodes, <String>['10', '11', '12', '23']);
  });

  test('explicit empty model code list remains authoritative', () {
    final capabilities =
        GreenGrocerProductCaseCapabilities.fromJson(const <String, dynamic>{
          'enabled': true,
          'orderLinkingEnabled': true,
          'sourceWarehouseNo': 56,
          'modelCodes': <String>[],
        });

    expect(capabilities.modelCodes, isEmpty);
  });

  test(
    'explicit zero tolerance remains valid while invalid multiplier falls back',
    () {
      final capabilities = GreenGrocerProductCaseCapabilities.fromJson(
        const <String, dynamic>{
          'enabled': true,
          'orderLinkingEnabled': true,
          'sourceWarehouseNo': 56,
          'modelCodes': <String>['10'],
          'defaultOverDeliveryTolerancePercent': 0,
          'severeOverDeliveryMultiplier': 0,
        },
      );

      expect(capabilities.defaultOverDeliveryTolerancePercent, 0);
      expect(capabilities.severeOverDeliveryMultiplier, 1.5);
    },
  );
}
