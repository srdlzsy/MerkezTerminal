import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class SuggestedWarehouseOrderFilter {
  const SuggestedWarehouseOrderFilter({
    required this.sourceWarehouseNo,
    this.targetWarehouseNo,
    this.lookbackDays,
    this.fallbackRecommendedDay,
  });

  final int sourceWarehouseNo;
  final int? targetWarehouseNo;
  final int? lookbackDays;
  final int? fallbackRecommendedDay;

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
}

class SuggestedWarehouseOrderListItem {
  const SuggestedWarehouseOrderListItem({
    required this.stockCode,
    required this.stockName,
    required this.modelCode,
    required this.barcode,
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

  final String stockCode;
  final String stockName;
  final String modelCode;
  final String barcode;
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
    if (suggestedOrderQuantity > 0) {
      return suggestedOrderQuantity;
    }
    if (needQuantity > 0) {
      return needQuantity;
    }
    return 0;
  }

  bool get canBeSelected =>
      stockCode.trim().isNotEmpty && defaultOrderQuantity > 0;

  factory SuggestedWarehouseOrderListItem.fromJson(JsonMap json) {
    return SuggestedWarehouseOrderListItem(
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      modelCode: _readString(json['modelCode']),
      barcode: _readString(json['barcode']),
      targetOnHand: _readDouble(json['targetOnHand']),
      sourceOnHand: _readDouble(json['sourceOnHand']),
      salesQuantity: _readDouble(json['salesQuantity']),
      openIncomingOrderQuantity: _readDouble(json['openIncomingOrderQuantity']),
      packageFactor: _readDouble(json['packageFactor']),
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
