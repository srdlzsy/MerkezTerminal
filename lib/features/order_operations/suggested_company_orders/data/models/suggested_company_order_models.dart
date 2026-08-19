import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class SuggestedCompanyOrderFilter {
  const SuggestedCompanyOrderFilter({
    required this.supplierCode,
    this.warehouseNo,
    this.lookbackDays,
    this.fallbackRecommendedDay,
  });

  final String supplierCode;
  final int? warehouseNo;
  final int? lookbackDays;
  final int? fallbackRecommendedDay;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'SupplierCode': supplierCode.trim(),
      if (warehouseNo != null) 'WarehouseNo': warehouseNo.toString(),
      if (lookbackDays != null) 'LookbackDays': lookbackDays.toString(),
      if (fallbackRecommendedDay != null)
        'FallbackRecommendedDay': fallbackRecommendedDay.toString(),
    };
  }
}

class SuggestedCompanyOrderListItem {
  const SuggestedCompanyOrderListItem({
    required this.supplierCode,
    required this.supplierName,
    required this.stockCode,
    required this.stockName,
    required this.modelCode,
    required this.barcode,
    required this.targetOnHand,
    required this.salesQuantity,
    required this.openCompanyOrderQuantity,
    required this.packageFactor,
    required this.minDay,
    required this.recommendedDay,
    required this.maxDay,
    required this.recommendedStockQuantity,
    required this.needQuantity,
    required this.suggestedOrderQuantity,
    required this.purchasePrice,
    required this.minimumPurchaseQuantity,
    this.deliveryDay,
  });

  final String supplierCode;
  final String supplierName;
  final String stockCode;
  final String stockName;
  final String modelCode;
  final String barcode;
  final double targetOnHand;
  final double salesQuantity;
  final double openCompanyOrderQuantity;
  final double packageFactor;
  final double minDay;
  final double recommendedDay;
  final double maxDay;
  final double recommendedStockQuantity;
  final double needQuantity;
  final double suggestedOrderQuantity;
  final double purchasePrice;
  final double minimumPurchaseQuantity;
  final int? deliveryDay;

  String get identity {
    final stockKey = stockCode.trim();
    if (stockKey.isNotEmpty) {
      return stockKey;
    }
    final barcodeKey = barcode.trim();
    if (barcodeKey.isNotEmpty) {
      return barcodeKey;
    }
    return stockName.trim();
  }

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

  double lineAmount(double quantity) => quantity * purchasePrice;

  factory SuggestedCompanyOrderListItem.fromJson(JsonMap json) {
    return SuggestedCompanyOrderListItem(
      supplierCode: _readString(json['supplierCode']),
      supplierName: _readString(json['supplierName']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      modelCode: _readString(json['modelCode']),
      barcode: _readString(json['barcode']),
      targetOnHand: _readDouble(json['targetOnHand']),
      salesQuantity: _readDouble(json['salesQuantity']),
      openCompanyOrderQuantity: _readDouble(json['openCompanyOrderQuantity']),
      packageFactor: _readPackageFactor(json),
      minDay: _readDouble(json['minDay']),
      recommendedDay: _readDouble(json['recommendedDay']),
      maxDay: _readDouble(json['maxDay']),
      recommendedStockQuantity: _readDouble(json['recommendedStockQuantity']),
      needQuantity: _readDouble(json['needQuantity']),
      suggestedOrderQuantity: _readDouble(json['suggestedOrderQuantity']),
      purchasePrice: _readDouble(json['purchasePrice']),
      minimumPurchaseQuantity: _readDouble(json['minimumPurchaseQuantity']),
      deliveryDay: _readNullableInt(json['deliveryDay']),
    );
  }
}

class SuggestedCompanyOrderConvertRequest {
  const SuggestedCompanyOrderConvertRequest({
    required this.supplierCode,
    required this.orderDate,
    required this.deliveryDate,
    required this.description1,
    required this.description2,
    required this.deliverer,
    required this.receiver,
    required this.lines,
    this.warehouseNo,
  });

  final String supplierCode;
  final int? warehouseNo;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String description1;
  final String description2;
  final String deliverer;
  final String receiver;
  final List<SuggestedCompanyOrderConvertLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'supplierCode': supplierCode.trim(),
      if (warehouseNo != null) 'warehouseNo': warehouseNo,
      'orderDate': _toApiDate(orderDate),
      'deliveryDate': _toApiDate(deliveryDate),
      'description1': description1,
      'description2': description2,
      'deliverer': deliverer,
      'receiver': receiver,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class SuggestedCompanyOrderConvertLine {
  const SuggestedCompanyOrderConvertLine({
    required this.stockCode,
    required this.quantity,
    required this.recommendedQuantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description1,
    required this.description2,
    required this.packageCode,
    required this.projectCode,
    required this.customerResponsibilityCenter,
    required this.productResponsibilityCenter,
  });

  final String stockCode;
  final double quantity;
  final double recommendedQuantity;
  final double unitPrice;
  final int unitPointer;
  final String description1;
  final String description2;
  final String packageCode;
  final String projectCode;
  final String customerResponsibilityCenter;
  final String productResponsibilityCenter;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'quantity': quantity,
      'recommendedQuantity': recommendedQuantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'description1': description1,
      'description2': description2,
      'packageCode': packageCode,
      'projectCode': projectCode,
      'customerResponsibilityCenter': customerResponsibilityCenter,
      'productResponsibilityCenter': productResponsibilityCenter,
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
    final value = _readDouble(json[key]);
    if (value > 0) {
      return value;
    }
  }

  return 0;
}

int? _readNullableInt(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(raw);
}
