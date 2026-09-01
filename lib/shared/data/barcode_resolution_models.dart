import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class BarcodeResolutionRequest {
  const BarcodeResolutionRequest({
    required this.barcode,
    this.warehouseNo,
    this.operationType,
    this.targetWarehouseNo,
    this.supplierCode,
    this.companyCode,
    this.isRefund,
    this.screenCode,
  });

  final String barcode;
  final String? warehouseNo;
  final String? operationType;
  final String? targetWarehouseNo;
  final String? supplierCode;
  final String? companyCode;
  final bool? isRefund;
  final String? screenCode;

  String get encodedBarcode => Uri.encodeComponent(barcode.trim());

  Map<String, String> toQueryParameters() {
    return <String, String>{
      if ((warehouseNo ?? '').trim().isNotEmpty)
        'warehouseNo': warehouseNo!.trim(),
      if ((operationType ?? '').trim().isNotEmpty)
        'operationType': operationType!.trim(),
      if ((targetWarehouseNo ?? '').trim().isNotEmpty)
        'targetWarehouseNo': targetWarehouseNo!.trim(),
      if ((supplierCode ?? '').trim().isNotEmpty)
        'supplierCode': supplierCode!.trim(),
      if ((companyCode ?? '').trim().isNotEmpty)
        'companyCode': companyCode!.trim(),
      if (isRefund != null) 'isRefund': isRefund!.toString(),
      if ((screenCode ?? '').trim().isNotEmpty)
        'screenCode': screenCode!.trim(),
    };
  }
}

class BarcodeResolutionResult {
  const BarcodeResolutionResult({
    required this.isFound,
    required this.barcode,
    required this.warehouseNo,
    required this.screenCode,
    required this.resolutionSource,
    required this.stockCode,
    required this.stockName,
    required this.matchedBarcode,
    required this.primaryBarcode,
    required this.caseBarcode,
    required this.unitsPerCase,
    required this.matchedUnitPointer,
    required this.matchedUnitName,
    required this.matchedUnitMultiplier,
    required this.isBlocked,
    required this.isSalesBlocked,
    required this.isOrderBlocked,
    required this.isGoodsAcceptanceBlocked,
    required this.isUsableInScreen,
    required this.usabilityReason,
    required this.defaultSupplierCode,
    required this.defaultSupplierName,
    required this.lookupBarcode,
    required this.isVariableWeightBarcode,
    required this.embeddedQuantity,
    required this.embeddedQuantityUnit,
    required this.isBarcodeCheckDigitValid,
    required this.barcodeKind,
    required this.isPrimaryBarcode,
    required this.isCaseBarcode,
    required this.isAlternativeBarcode,
    required this.matchedUnitsPerCase,
    required this.operationType,
    required this.targetWarehouseNo,
    required this.isAllowedForTargetWarehouse,
    required this.targetWarehouseReason,
    required this.productModelCode,
    required this.targetWarehouseModelCodes,
    required this.supplierCode,
    required this.hasPurchaseRequirement,
    required this.purchaseRequirementReason,
    required this.salesPrice,
    required this.priceTypeCode,
    required this.isPassive,
    required this.isUsableInOperation,
    required this.operationDecision,
    required this.warnings,
    required this.errors,
  });

  final bool isFound;
  final String barcode;
  final int warehouseNo;
  final String screenCode;
  final String resolutionSource;
  final String stockCode;
  final String stockName;
  final String matchedBarcode;
  final String primaryBarcode;
  final String caseBarcode;
  final double unitsPerCase;
  final int matchedUnitPointer;
  final String matchedUnitName;
  final double matchedUnitMultiplier;
  final bool isBlocked;
  final bool isSalesBlocked;
  final bool isOrderBlocked;
  final bool isGoodsAcceptanceBlocked;
  final bool isUsableInScreen;
  final String usabilityReason;
  final String defaultSupplierCode;
  final String defaultSupplierName;
  final String lookupBarcode;
  final bool isVariableWeightBarcode;
  final double embeddedQuantity;
  final String embeddedQuantityUnit;
  final bool? isBarcodeCheckDigitValid;
  final String barcodeKind;
  final bool isPrimaryBarcode;
  final bool isCaseBarcode;
  final bool isAlternativeBarcode;
  final double? matchedUnitsPerCase;
  final String operationType;
  final int? targetWarehouseNo;
  final bool? isAllowedForTargetWarehouse;
  final String targetWarehouseReason;
  final String productModelCode;
  final List<String> targetWarehouseModelCodes;
  final String supplierCode;
  final bool? hasPurchaseRequirement;
  final String purchaseRequirementReason;
  final double salesPrice;
  final int priceTypeCode;
  final bool isPassive;
  final bool isUsableInOperation;
  final String operationDecision;
  final List<String> warnings;
  final List<String> errors;

  String get effectiveBarcode {
    final primary = primaryBarcode.trim();
    if (primary.isNotEmpty) {
      return primary;
    }

    final matched = matchedBarcode.trim();
    if (matched.isNotEmpty) {
      return matched;
    }

    final lookup = lookupBarcode.trim();
    if (lookup.isNotEmpty) {
      return lookup;
    }

    return barcode;
  }

  double get suggestedQuantity {
    if (isVariableWeightBarcode && embeddedQuantity > 0) {
      return embeddedQuantity;
    }

    final caseQuantity = matchedUnitsPerCase ?? unitsPerCase;
    if (isCaseBarcode && caseQuantity > 0) {
      return caseQuantity;
    }

    return 1;
  }

  int get effectiveUnitPointer {
    return matchedUnitPointer > 0 ? matchedUnitPointer : 1;
  }

  String get quickErrorMessage {
    if (errors.isNotEmpty) {
      return errors.first;
    }

    if (operationDecision.trim().isNotEmpty) {
      return operationDecision;
    }

    if (!isFound) {
      return 'Urun bulunamadi.';
    }

    return 'Barkod bu islemde kullanilamaz.';
  }

  String get quickWarningMessage {
    if (warnings.isNotEmpty) {
      return warnings.first;
    }

    return '';
  }

  factory BarcodeResolutionResult.fromJson(JsonMap json) {
    return BarcodeResolutionResult(
      isFound: _readBool(json['isFound']),
      barcode: _readString(json['barcode']),
      warehouseNo: _readInt(json['warehouseNo']),
      screenCode: _readString(json['screenCode']),
      resolutionSource: _readString(json['resolutionSource']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      matchedBarcode: _readString(json['matchedBarcode']),
      primaryBarcode: _readString(json['primaryBarcode']),
      caseBarcode: _readString(json['caseBarcode']),
      unitsPerCase: _readDouble(json['unitsPerCase']).abs(),
      matchedUnitPointer: _readInt(json['matchedUnitPointer']),
      matchedUnitName: _readString(json['matchedUnitName']),
      matchedUnitMultiplier: _readPositiveDouble(json['matchedUnitMultiplier']),
      isBlocked: _readBool(json['isBlocked']),
      isSalesBlocked: _readBool(json['isSalesBlocked']),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
      isUsableInScreen: _readBool(json['isUsableInScreen']),
      usabilityReason: _readString(json['usabilityReason']),
      defaultSupplierCode: _readString(json['defaultSupplierCode']),
      defaultSupplierName: _readString(json['defaultSupplierName']),
      lookupBarcode: _readString(json['lookupBarcode']),
      isVariableWeightBarcode: _readBool(json['isVariableWeightBarcode']),
      embeddedQuantity: _readDouble(json['embeddedQuantity']),
      embeddedQuantityUnit: _readString(json['embeddedQuantityUnit']),
      isBarcodeCheckDigitValid: _readNullableBool(
        json['isBarcodeCheckDigitValid'],
      ),
      barcodeKind: _readString(json['barcodeKind']),
      isPrimaryBarcode: _readBool(json['isPrimaryBarcode']),
      isCaseBarcode: _readBool(json['isCaseBarcode']),
      isAlternativeBarcode: _readBool(json['isAlternativeBarcode']),
      matchedUnitsPerCase: _readNullableDouble(
        json['matchedUnitsPerCase'],
      )?.abs(),
      operationType: _readString(json['operationType']),
      targetWarehouseNo: _readNullableInt(json['targetWarehouseNo']),
      isAllowedForTargetWarehouse: _readNullableBool(
        json['isAllowedForTargetWarehouse'],
      ),
      targetWarehouseReason: _readString(json['targetWarehouseReason']),
      productModelCode: _readString(json['productModelCode']),
      targetWarehouseModelCodes: _readStringList(
        json['targetWarehouseModelCodes'],
      ),
      supplierCode: _readString(json['supplierCode']),
      hasPurchaseRequirement: _readNullableBool(json['hasPurchaseRequirement']),
      purchaseRequirementReason: _readString(json['purchaseRequirementReason']),
      salesPrice: _readDouble(json['salesPrice']),
      priceTypeCode: _readInt(json['priceTypeCode']),
      isPassive: _readBool(json['isPassive']),
      isUsableInOperation: _readBool(json['isUsableInOperation']),
      operationDecision: _readString(json['operationDecision']),
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
    );
  }
}

bool looksLikeDirectBarcodeInput(String value) {
  final normalized = value.trim();
  if (normalized.length < 5 || normalized.contains(RegExp(r'\s'))) {
    return false;
  }

  return normalized.contains(RegExp(r'\d'));
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

bool? _readNullableBool(Object? value) {
  if (value == null) {
    return null;
  }

  return _readBool(value);
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _readPositiveDouble(Object? value, {double fallback = 1}) {
  final parsed = _readDouble(value).abs();
  return parsed > 0 ? parsed : fallback;
}

double? _readNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
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
