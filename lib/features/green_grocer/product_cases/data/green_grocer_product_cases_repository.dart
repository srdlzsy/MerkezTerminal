import 'package:furpa_merkez_terminal/core/network/api_client.dart';

abstract class GreenGrocerProductCasesRepository {
  Future<GreenGrocerProductCaseCapabilities> getCapabilities({
    required String accessToken,
  });

  Future<GreenGrocerProductCaseResolutionResult> resolvePreview({
    required String accessToken,
    required GreenGrocerProductCaseResolutionRequest request,
  });
}

class ApiGreenGrocerProductCasesRepository
    implements GreenGrocerProductCasesRepository {
  const ApiGreenGrocerProductCasesRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<GreenGrocerProductCaseCapabilities> getCapabilities({
    required String accessToken,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/green-grocer/product-case-profiles/capabilities',
      accessToken: accessToken,
    );
    return GreenGrocerProductCaseCapabilities.fromJson(response);
  }

  @override
  Future<GreenGrocerProductCaseResolutionResult> resolvePreview({
    required String accessToken,
    required GreenGrocerProductCaseResolutionRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/green-grocer/product-case-profiles/resolution-preview',
      accessToken: accessToken,
      body: request.toJson(),
      verifyWarehouseContext: false,
    );

    return GreenGrocerProductCaseResolutionResult.fromJson(response);
  }
}

class GreenGrocerProductCaseResolutionRequest {
  const GreenGrocerProductCaseResolutionRequest({
    required this.stockCode,
    required this.inputQuantity,
    required this.sourceWarehouseNo,
    required this.targetWarehouseNo,
    required this.orderDate,
  });

  final String stockCode;
  final double inputQuantity;
  final int sourceWarehouseNo;
  final int? targetWarehouseNo;
  final DateTime orderDate;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'inputQuantity': inputQuantity,
      'sourceWarehouseNo': sourceWarehouseNo,
      if (targetWarehouseNo != null) 'targetWarehouseNo': targetWarehouseNo,
      'orderDate': orderDate.toIso8601String(),
    };
  }
}

class GreenGrocerProductCaseResolutionResult {
  const GreenGrocerProductCaseResolutionResult({
    required this.stockCode,
    required this.stockName,
    required this.modelCode,
    required this.modelName,
    required this.unit1,
    required this.unit2,
    required this.unit2Factor,
    required this.inputQuantity,
    required this.inputMode,
    required this.conversionMode,
    required this.microUnit,
    required this.estimatedQuantity,
    required this.averageKgPerCase,
    required this.unitsPerCase,
    required this.averageSource,
    required this.averageRecordCount,
    required this.averageCaseCount,
    required this.coefficientOfVariation,
    required this.latestLabelDate,
    required this.confidence,
    required this.requiresManualApproval,
    required this.isOrderLinkable,
    this.overDeliveryTolerancePercent = 20,
    this.severeOverDeliveryMultiplier = 1.5,
    required this.isUsable,
    required this.warnings,
    required this.errors,
    this.calculationTier,
    this.averageWindowDaysUsed,
    this.labelAgeDays,
    this.priorAverageKgPerCase,
    this.driftPercent,
    this.driftDetected = false,
    this.alternativeAverageKgPerCase,
  });

  final String stockCode;
  final String stockName;
  final String modelCode;
  final String modelName;
  final String unit1;
  final String unit2;
  final double unit2Factor;
  final double inputQuantity;
  final String inputMode;
  final String conversionMode;
  final String microUnit;
  final double estimatedQuantity;
  final double averageKgPerCase;
  final double unitsPerCase;
  final String averageSource;
  final int averageRecordCount;
  final double averageCaseCount;
  final double coefficientOfVariation;
  final DateTime? latestLabelDate;
  final String confidence;
  final bool requiresManualApproval;
  final bool isOrderLinkable;
  final double overDeliveryTolerancePercent;
  final double severeOverDeliveryMultiplier;
  final bool isUsable;
  final List<String> warnings;
  final List<String> errors;
  final String? calculationTier;
  final int? averageWindowDaysUsed;
  final int? labelAgeDays;
  final double? priorAverageKgPerCase;
  final double? driftPercent;
  final bool driftDetected;
  final double? alternativeAverageKgPerCase;

  String get primaryError {
    if (errors.isNotEmpty) {
      return errors.first;
    }

    return 'Manav kasa cozumleme bu satir icin kullanilabilir degil.';
  }

  String get primaryWarning {
    if (warnings.isNotEmpty) {
      return warnings.first;
    }

    if (confidence.trim().toLowerCase() == 'medium') {
      return 'Manav kasa ortalamasi orta guvende.';
    }

    if (requiresManualApproval) {
      return 'Manav kasa cozumleme manuel onay gerektiriyor.';
    }

    return '';
  }

  String get displayInputMode {
    return switch (inputMode.trim().toLowerCase()) {
      'case' => 'kasa',
      'pack' => 'koli',
      'piece' => 'adet',
      'kgdirect' => 'kg',
      'sarf' => 'sarf',
      final value when value.isNotEmpty => value,
      _ => 'kasa',
    };
  }

  String get displayMicroUnit {
    final normalized = microUnit.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    final primaryUnit = unit1.trim();
    if (primaryUnit.isNotEmpty) {
      return primaryUnit;
    }

    return 'MIKTAR';
  }

  factory GreenGrocerProductCaseResolutionResult.fromJson(JsonMap json) {
    final overDeliveryTolerancePercent = _readNullableDouble(
      json['overDeliveryTolerancePercent'],
    );
    final severeOverDeliveryMultiplier = _readNullableDouble(
      json['severeOverDeliveryMultiplier'],
    );

    return GreenGrocerProductCaseResolutionResult(
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      modelCode: _readString(json['modelCode']),
      modelName: _readString(json['modelName']),
      unit1: _readString(json['unit1']),
      unit2: _readString(json['unit2']),
      unit2Factor: _readDouble(json['unit2Factor']),
      inputQuantity: _readDouble(json['inputQuantity']),
      inputMode: _readString(json['inputMode']),
      conversionMode: _readString(json['conversionMode']),
      microUnit: _readString(json['microUnit']),
      estimatedQuantity: _readDouble(json['estimatedQuantity']),
      averageKgPerCase: _readDouble(json['averageKgPerCase']),
      unitsPerCase: _readDouble(json['unitsPerCase']).abs(),
      averageSource: _readString(json['averageSource']),
      averageRecordCount: _readInt(json['averageRecordCount']),
      averageCaseCount: _readDouble(json['averageCaseCount']),
      coefficientOfVariation: _readDouble(json['coefficientOfVariation']),
      latestLabelDate: _readDate(json['latestLabelDate']),
      confidence: _readString(json['confidence']),
      requiresManualApproval: _readBool(json['requiresManualApproval']),
      isOrderLinkable: _readBool(json['isOrderLinkable']),
      overDeliveryTolerancePercent:
          overDeliveryTolerancePercent != null &&
              overDeliveryTolerancePercent >= 0
          ? overDeliveryTolerancePercent
          : 20,
      severeOverDeliveryMultiplier:
          severeOverDeliveryMultiplier != null &&
              severeOverDeliveryMultiplier > 1
          ? severeOverDeliveryMultiplier
          : 1.5,
      isUsable: _readBool(json['isUsable']),
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
      calculationTier: _readString(json['calculationTier']).isEmpty
          ? null
          : _readString(json['calculationTier']),
      averageWindowDaysUsed: json['averageWindowDaysUsed'] == null
          ? null
          : _readInt(json['averageWindowDaysUsed']),
      labelAgeDays: json['labelAgeDays'] == null
          ? null
          : _readInt(json['labelAgeDays']),
      priorAverageKgPerCase: _readNullableDouble(json['priorAverageKgPerCase']),
      driftPercent: _readNullableDouble(json['driftPercent']),
      driftDetected: _readBool(json['driftDetected']),
      alternativeAverageKgPerCase: _readNullableDouble(
        json['alternativeAverageKgPerCase'],
      ),
    );
  }
}

class GreenGrocerProductCaseCapabilities {
  const GreenGrocerProductCaseCapabilities({
    required this.enabled,
    required this.orderLinkingEnabled,
    this.requireOrderUserManualApproval = false,
    this.authDbProfileStorageEnabled = false,
    this.authDbTrackingEnabled = false,
    required this.sourceWarehouseNo,
    required this.modelCodes,
    required this.defaultOverDeliveryTolerancePercent,
    required this.severeOverDeliveryMultiplier,
  });

  final bool enabled;
  final bool orderLinkingEnabled;
  final bool requireOrderUserManualApproval;
  final bool authDbProfileStorageEnabled;
  final bool authDbTrackingEnabled;
  final int sourceWarehouseNo;
  final List<String> modelCodes;
  final double defaultOverDeliveryTolerancePercent;
  final double severeOverDeliveryMultiplier;

  factory GreenGrocerProductCaseCapabilities.fromJson(JsonMap json) {
    final defaultOverDeliveryTolerancePercent = _readNullableDouble(
      json['defaultOverDeliveryTolerancePercent'],
    );
    final severeOverDeliveryMultiplier = _readNullableDouble(
      json['severeOverDeliveryMultiplier'],
    );
    final modelCodes = json.containsKey('modelCodes')
        ? _readStringList(json['modelCodes'])
        : const <String>['10', '11', '12', '23'];

    return GreenGrocerProductCaseCapabilities(
      enabled: _readBool(json['enabled']),
      orderLinkingEnabled: _readBool(json['orderLinkingEnabled']),
      requireOrderUserManualApproval: _readBool(
        json['requireOrderUserManualApproval'],
      ),
      authDbProfileStorageEnabled: _readBool(
        json['authDbProfileStorageEnabled'],
      ),
      authDbTrackingEnabled: _readBool(json['authDbTrackingEnabled']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      modelCodes: modelCodes,
      defaultOverDeliveryTolerancePercent:
          defaultOverDeliveryTolerancePercent != null &&
              defaultOverDeliveryTolerancePercent >= 0
          ? defaultOverDeliveryTolerancePercent
          : 20,
      severeOverDeliveryMultiplier:
          severeOverDeliveryMultiplier != null &&
              severeOverDeliveryMultiplier > 1
          ? severeOverDeliveryMultiplier
          : 1.5,
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final raw = value?.toString().trim().toLowerCase();
  return raw == 'true' || raw == '1';
}

DateTime? _readDate(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  final raw = value?.toString().trim() ?? '';
  return raw.isEmpty ? null : double.tryParse(raw);
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}
