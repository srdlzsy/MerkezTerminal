import 'package:furpa_merkez_terminal/core/network/api_client.dart';

const Set<int> suggestedWarehouseOrderSourceProductWarehouseNos = <int>{
  53,
  55,
  56,
  58,
};

bool usesSuggestedWarehouseOrderSourceProducts(int sourceWarehouseNo) {
  return suggestedWarehouseOrderSourceProductWarehouseNos.contains(
    sourceWarehouseNo,
  );
}

class SuggestedWarehouseOrderFilter {
  const SuggestedWarehouseOrderFilter({
    required this.sourceWarehouseNo,
    this.targetWarehouseNo,
    this.lookbackDays,
    this.fallbackRecommendedDay,
    this.useSourceProducts = false,
  });

  final int sourceWarehouseNo;
  final int? targetWarehouseNo;
  final int? lookbackDays;
  final int? fallbackRecommendedDay;
  final bool useSourceProducts;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'SourceWarehouseNo': sourceWarehouseNo.toString(),
      if (targetWarehouseNo != null)
        'TargetWarehouseNo': targetWarehouseNo.toString(),
      if (lookbackDays != null) 'LookbackDays': lookbackDays.toString(),
      if (fallbackRecommendedDay != null)
        'FallbackRecommendedDay': fallbackRecommendedDay.toString(),
    };
  }

  Map<String, String> toSourceProductQueryParameters() {
    return <String, String>{'sourceWarehouseNo': sourceWarehouseNo.toString()};
  }
}

class SuggestedWarehouseOrderListItem {
  const SuggestedWarehouseOrderListItem({
    this.sourceWarehouseNo = 0,
    this.sourceWarehouseName = '',
    required this.stockCode,
    required this.stockName,
    required this.modelCode,
    required this.barcode,
    this.modelName = '',
    this.unitName = '',
    this.secondaryUnitName = '',
    this.caseBarcode = '',
    this.quantity = 0,
    this.recommendedQuantity = 0,
    this.unitPrice = 0,
    this.unitPointer = 1,
    required this.targetOnHand,
    required this.sourceOnHand,
    required this.salesQuantity,
    required this.openIncomingOrderQuantity,
    required this.packageFactor,
    required this.minDay,
    required this.recommendedDay,
    required this.maxDay,
    required this.recommendedStockQuantity,
    required this.needQuantity,
    required this.suggestedOrderQuantity,
  });

  final int sourceWarehouseNo;
  final String sourceWarehouseName;
  final String stockCode;
  final String stockName;
  final String modelCode;
  final String barcode;
  final String modelName;
  final String unitName;
  final String secondaryUnitName;
  final String caseBarcode;
  final double quantity;
  final double recommendedQuantity;
  final double unitPrice;
  final int unitPointer;
  final double targetOnHand;
  final double sourceOnHand;
  final double salesQuantity;
  final double openIncomingOrderQuantity;
  final double packageFactor;
  final double minDay;
  final double recommendedDay;
  final double maxDay;
  final double recommendedStockQuantity;
  final double needQuantity;
  final double suggestedOrderQuantity;

  String get identity => stockCode.trim().isNotEmpty
      ? stockCode.trim()
      : barcode.trim().isNotEmpty
      ? barcode.trim()
      : stockName.trim();

  double get defaultOrderQuantity {
    if (quantity > 0) {
      return quantity;
    }
    if (suggestedOrderQuantity > 0) {
      return suggestedOrderQuantity;
    }
    if (recommendedQuantity > 0) {
      return recommendedQuantity;
    }
    if (needQuantity > 0) {
      return needQuantity;
    }
    return 0;
  }

  bool get needsManualQuantity =>
      defaultOrderQuantity <= 0 &&
      sourceOnHand <= 0 &&
      salesQuantity <= 0 &&
      needQuantity <= 0;

  bool get canBeSelected => stockCode.trim().isNotEmpty;

  bool get canBeAutoSelected =>
      stockCode.trim().isNotEmpty && defaultOrderQuantity > 0;

  String get sourceProductGroupLabel {
    final normalizedModelName = modelName.trim();
    if (normalizedModelName.isNotEmpty) {
      return normalizedModelName;
    }

    final normalizedSourceWarehouseName = sourceWarehouseName.trim();
    if (normalizedSourceWarehouseName.isNotEmpty) {
      return normalizedSourceWarehouseName;
    }

    final normalizedModelCode = modelCode.trim();
    if (normalizedModelCode.isNotEmpty) {
      return 'Model $normalizedModelCode';
    }

    return 'Kaynak urun';
  }

  factory SuggestedWarehouseOrderListItem.fromJson(JsonMap json) {
    return SuggestedWarehouseOrderListItem(
      sourceWarehouseNo: _readPositiveInt(
        json['sourceWarehouseNo'],
        fallback: 0,
      ),
      sourceWarehouseName: _readString(json['sourceWarehouseName']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      modelCode: _readString(json['modelCode']),
      barcode: _readString(json['barcode']),
      modelName: _readString(json['modelName']),
      unitName: _readString(json['unitName']),
      secondaryUnitName: _readString(json['secondaryUnitName']),
      caseBarcode: _readString(json['caseBarcode']),
      quantity: _readDouble(json['quantity']),
      recommendedQuantity: _readDouble(json['recommendedQuantity']),
      unitPrice: _readDouble(json['unitPrice']),
      unitPointer: _readPositiveInt(json['unitPointer'], fallback: 1),
      targetOnHand: _readDouble(json['targetOnHand']),
      sourceOnHand: _readDouble(json['sourceOnHand']),
      salesQuantity: _readDouble(json['salesQuantity']),
      openIncomingOrderQuantity: _readDouble(json['openIncomingOrderQuantity']),
      packageFactor: _readPackageFactor(json),
      minDay: _readDouble(json['minDay']),
      recommendedDay: _readDouble(json['recommendedDay']),
      maxDay: _readDouble(json['maxDay']),
      recommendedStockQuantity: _readDouble(json['recommendedStockQuantity']),
      needQuantity: _readDouble(json['needQuantity']),
      suggestedOrderQuantity: _readDouble(json['suggestedOrderQuantity']),
    );
  }
}

class SuggestedWarehouseOrderConvertRequest {
  const SuggestedWarehouseOrderConvertRequest({
    required this.sourceWarehouseNo,
    required this.orderDate,
    required this.deliveryDate,
    required this.description,
    required this.lines,
    this.targetWarehouseNo,
  });

  final int sourceWarehouseNo;
  final int? targetWarehouseNo;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String description;
  final List<SuggestedWarehouseOrderConvertLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'sourceWarehouseNo': sourceWarehouseNo,
      if (targetWarehouseNo != null) 'targetWarehouseNo': targetWarehouseNo,
      'orderDate': _toApiDate(orderDate),
      'deliveryDate': _toApiDate(deliveryDate),
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class SuggestedWarehouseOrderConvertLine {
  const SuggestedWarehouseOrderConvertLine({
    required this.stockCode,
    required this.quantity,
    required this.recommendedQuantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description,
    required this.packageCode,
    required this.projectCode,
    required this.responsibilityCenter,
  });

  final String stockCode;
  final double quantity;
  final double recommendedQuantity;
  final double unitPrice;
  final int unitPointer;
  final String description;
  final String packageCode;
  final String projectCode;
  final String responsibilityCenter;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'quantity': quantity,
      'recommendedQuantity': recommendedQuantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'description': description,
      'packageCode': packageCode,
      'projectCode': projectCode,
      'responsibilityCenter': responsibilityCenter,
    };
  }
}

String _toApiDate(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

double _readPackageFactor(JsonMap json) {
  for (final key in const <String>[
    'packageFactor',
    'unitsPerCase',
    'matchedUnitsPerCase',
    'packageQuantity',
    'packageQty',
    'unitPerPackage',
    'unitsInPackage',
    'koliIciAdet',
    'koliIciMiktar',
    'koliMiktari',
  ]) {
    final value = _readDouble(json[key]).abs();
    if (value > 0) {
      return value;
    }
  }

  return 0;
}

int _readPositiveInt(Object? value, {required int fallback}) {
  final parsed = value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;
  return parsed > 0 ? parsed : fallback;
}
