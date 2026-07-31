import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';

class WarehouseOrderListFilter {
  const WarehouseOrderListFilter({
    required this.startDate,
    required this.endDate,
    this.warehouseNo,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? warehouseNo;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'StartDate': _toApiDate(startDate),
      'EndDate': _toApiDate(endDate),
      if (warehouseNo != null && warehouseNo!.trim().isNotEmpty)
        'WarehouseNo': warehouseNo!.trim(),
    };
  }
}

class WarehouseOrderCreateRequest {
  const WarehouseOrderCreateRequest({
    required this.outWarehouseNo,
    required this.orderDate,
    required this.deliveryDate,
    required this.description,
    required this.lines,
  });

  final int outWarehouseNo;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String description;
  final List<WarehouseOrderCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'outWarehouseNo': outWarehouseNo,
      'orderDate': _toApiDate(orderDate),
      'deliveryDate': _toApiDate(deliveryDate),
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class WarehouseOrderCreateLine {
  const WarehouseOrderCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.recommendedQuantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description,
    required this.packageCode,
    required this.projectCode,
    required this.responsibilityCenter,
    this.greenGrocerCase,
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
  final WarehouseOrderLineGreenGrocerCase? greenGrocerCase;

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
      if (greenGrocerCase != null)
        'greenGrocerCase': greenGrocerCase!.toCreateJson(),
    };
  }
}

class WarehouseOrderLineGreenGrocerCase {
  const WarehouseOrderLineGreenGrocerCase({
    required this.inputQuantity,
    required this.inputMode,
    required this.conversionMode,
    required this.estimatedQuantity,
    required this.microUnit,
    this.averageKgPerCase,
    this.unitsPerCase,
    required this.averageSource,
    this.averageRecordCount,
    this.averageCaseCount,
    this.coefficientOfVariation,
    required this.confidence,
    this.actualShippedQuantity,
    this.actualShippedCaseCount,
    this.status = '',
  });

  final double inputQuantity;
  final String inputMode;
  final String conversionMode;
  final double estimatedQuantity;
  final String microUnit;
  final double? averageKgPerCase;
  final double? unitsPerCase;
  final String averageSource;
  final int? averageRecordCount;
  final double? averageCaseCount;
  final double? coefficientOfVariation;
  final String confidence;
  final double? actualShippedQuantity;
  final double? actualShippedCaseCount;
  final String status;

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

  JsonMap toCreateJson() {
    return <String, dynamic>{
      'inputQuantity': inputQuantity,
      'inputMode': inputMode,
      'conversionMode': conversionMode,
      'microUnit': microUnit,
      'estimatedQuantity': estimatedQuantity,
      if (averageKgPerCase != null) 'averageKgPerCase': averageKgPerCase,
      if (unitsPerCase != null) 'unitsPerCase': unitsPerCase,
      'averageSource': averageSource,
      if (averageRecordCount != null) 'averageRecordCount': averageRecordCount,
      if (averageCaseCount != null) 'averageCaseCount': averageCaseCount,
      if (coefficientOfVariation != null)
        'coefficientOfVariation': coefficientOfVariation,
      'confidence': confidence,
    };
  }

  JsonMap toJson() {
    return <String, dynamic>{
      ...toCreateJson(),
      if (actualShippedQuantity != null)
        'actualShippedQuantity': actualShippedQuantity,
      if (actualShippedCaseCount != null)
        'actualShippedCaseCount': actualShippedCaseCount,
      if (status.trim().isNotEmpty) 'status': status,
    };
  }

  factory WarehouseOrderLineGreenGrocerCase.fromJson(JsonMap json) {
    return WarehouseOrderLineGreenGrocerCase(
      inputQuantity: _readDouble(json['inputQuantity']),
      inputMode: _readString(json['inputMode']),
      conversionMode: _readString(json['conversionMode']),
      estimatedQuantity: _readDouble(json['estimatedQuantity']),
      microUnit: _readString(json['microUnit']),
      averageKgPerCase: _readNullableDouble(json['averageKgPerCase']),
      unitsPerCase: _readNullableDouble(json['unitsPerCase']),
      averageSource: _readString(json['averageSource']),
      averageRecordCount: _readNullableInt(json['averageRecordCount']),
      averageCaseCount: _readNullableDouble(json['averageCaseCount']),
      coefficientOfVariation: _readNullableDouble(
        json['coefficientOfVariation'],
      ),
      confidence: _readString(json['confidence']),
      actualShippedQuantity: _readNullableDouble(json['actualShippedQuantity']),
      actualShippedCaseCount: _readNullableDouble(
        json['actualShippedCaseCount'],
      ),
      status: _readString(json['status']),
    );
  }
}

class WarehouseOrderCreateResult {
  const WarehouseOrderCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.orderDate,
    required this.deliveryDate,
    required this.inWarehouseNo,
    required this.outWarehouseNo,
    required this.lineCount,
    required this.totalQuantity,
    required this.writeConnectionName,
  });

  final String documentSerie;
  final int documentOrderNo;
  final DateTime? orderDate;
  final DateTime? deliveryDate;
  final int inWarehouseNo;
  final int outWarehouseNo;
  final int lineCount;
  final double totalQuantity;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory WarehouseOrderCreateResult.fromJson(JsonMap json) {
    return WarehouseOrderCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      orderDate: _readDate(json['orderDate']),
      deliveryDate: _readDate(json['deliveryDate']),
      inWarehouseNo: _readInt(json['inWarehouseNo']),
      outWarehouseNo: _readInt(json['outWarehouseNo']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      writeConnectionName: _readString(json['writeConnectionName']),
    );
  }
}

class ProductLookupItem {
  const ProductLookupItem({
    required this.warehouseNo,
    required this.barcode,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.unitName,
    this.unitMultiplier = 1,
    this.modelCode = '',
    required this.isOrderBlocked,
  });

  final int warehouseNo;
  final String barcode;
  final String stockCode;
  final String stockName;
  final double price;
  final String unitName;
  final double unitMultiplier;
  final String modelCode;
  final bool isOrderBlocked;

  String get displayLabel => '$stockCode - $stockName';

  factory ProductLookupItem.fromJson(JsonMap json) {
    return ProductLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      price: _readDouble(json['price']),
      unitName: _readString(json['unitName']),
      unitMultiplier: _readPositiveDouble(json['unitMultiplier']),
      modelCode: _readFirstString(json, const <String>[
        'modelCode',
        'productModelCode',
        'stockModelCode',
      ]),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
    );
  }

  factory ProductLookupItem.fromBarcodeResolution(
    BarcodeResolutionResult resolution,
  ) {
    return ProductLookupItem(
      warehouseNo: resolution.warehouseNo,
      barcode: resolution.effectiveBarcode,
      stockCode: resolution.stockCode,
      stockName: resolution.stockName,
      price: resolution.salesPrice,
      unitName: resolution.matchedUnitName,
      unitMultiplier: resolution.matchedUnitMultiplier,
      modelCode: resolution.productModelCode,
      isOrderBlocked: resolution.isOrderBlocked,
    );
  }
}

class WarehouseLookupItem {
  const WarehouseLookupItem({
    required this.warehouseNo,
    required this.warehouseName,
    required this.address,
    required this.district,
    required this.province,
  });

  final int warehouseNo;
  final String warehouseName;
  final String address;
  final String district;
  final String province;

  String get displayLabel => '$warehouseNo - $warehouseName';

  factory WarehouseLookupItem.fromJson(JsonMap json) {
    return WarehouseLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      address: _readString(json['address']),
      district: _readString(json['district']),
      province: _readString(json['province']),
    );
  }
}

class WarehouseOrderListItem {
  const WarehouseOrderListItem({
    required this.documentKey,
    required this.documentDate,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.documentNumber,
    required this.warehouseNo,
    required this.warehouseName,
    required this.relatedWarehouseNo,
    required this.relatedWarehouseName,
    required this.inWarehouseNo,
    required this.inWarehouseName,
    required this.outWarehouseNo,
    required this.outWarehouseName,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.deliveryDate,
  });

  final String documentKey;
  final DateTime? documentDate;
  final String documentSerie;
  final int documentOrderNo;
  final String documentNumber;
  final int warehouseNo;
  final String warehouseName;
  final int relatedWarehouseNo;
  final String relatedWarehouseName;
  final int inWarehouseNo;
  final String inWarehouseName;
  final int outWarehouseNo;
  final String outWarehouseName;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;
  final DateTime? deliveryDate;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory WarehouseOrderListItem.fromJson(JsonMap json) {
    return WarehouseOrderListItem(
      documentKey: _readString(json['documentKey']),
      documentDate: _readDate(json['documentDate']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      documentNumber: _readString(json['documentNumber']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      relatedWarehouseNo: _readInt(json['relatedWarehouseNo']),
      relatedWarehouseName: _readString(json['relatedWarehouseName']),
      inWarehouseNo: _readInt(json['inWarehouseNo']),
      inWarehouseName: _readString(json['inWarehouseName']),
      outWarehouseNo: _readInt(json['outWarehouseNo']),
      outWarehouseName: _readString(json['outWarehouseName']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      deliveryDate: _readDate(json['deliveryDate']),
    );
  }
}

class WarehouseOrderDetail {
  const WarehouseOrderDetail({required this.header, required this.items});

  final WarehouseOrderDetailHeader header;
  final List<WarehouseOrderDetailItem> items;

  factory WarehouseOrderDetail.fromJson(JsonMap json) {
    return WarehouseOrderDetail(
      header: WarehouseOrderDetailHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => WarehouseOrderDetailItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class WarehouseOrderDetailHeader {
  const WarehouseOrderDetailHeader({
    required this.documentKey,
    required this.documentDate,
    required this.deliveryDate,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.documentNumber,
    required this.warehouseNo,
    required this.warehouseName,
    required this.relatedWarehouseNo,
    required this.relatedWarehouseName,
    required this.inWarehouseNo,
    required this.inWarehouseName,
    required this.outWarehouseNo,
    required this.outWarehouseName,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalDeliveredQuantity,
    required this.totalRemainingQuantity,
    required this.totalAmount,
    required this.isClosed,
  });

  final String documentKey;
  final DateTime? documentDate;
  final DateTime? deliveryDate;
  final String documentSerie;
  final int documentOrderNo;
  final String documentNumber;
  final int warehouseNo;
  final String warehouseName;
  final int relatedWarehouseNo;
  final String relatedWarehouseName;
  final int inWarehouseNo;
  final String inWarehouseName;
  final int outWarehouseNo;
  final String outWarehouseName;
  final int lineCount;
  final double totalQuantity;
  final double totalDeliveredQuantity;
  final double totalRemainingQuantity;
  final double totalAmount;
  final bool isClosed;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory WarehouseOrderDetailHeader.fromJson(JsonMap json) {
    return WarehouseOrderDetailHeader(
      documentKey: _readString(json['documentKey']),
      documentDate: _readDate(json['documentDate']),
      deliveryDate: _readDate(json['deliveryDate']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      documentNumber: _readString(json['documentNumber']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      relatedWarehouseNo: _readInt(json['relatedWarehouseNo']),
      relatedWarehouseName: _readString(json['relatedWarehouseName']),
      inWarehouseNo: _readInt(json['inWarehouseNo']),
      inWarehouseName: _readString(json['inWarehouseName']),
      outWarehouseNo: _readInt(json['outWarehouseNo']),
      outWarehouseName: _readString(json['outWarehouseName']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalDeliveredQuantity: _readDouble(json['totalDeliveredQuantity']),
      totalRemainingQuantity: _readDouble(json['totalRemainingQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      isClosed: _readBool(json['isClosed']),
    );
  }
}

class WarehouseOrderDetailItem {
  const WarehouseOrderDetailItem({
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.quantity,
    required this.deliveredQuantity,
    required this.remainingQuantity,
    required this.unitPrice,
    required this.lineAmount,
    required this.isClosed,
    required this.description,
    required this.packageCode,
    required this.projectCode,
    this.modelCode = '',
    this.lineGuid = '',
    this.greenGrocerCase,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double quantity;
  final double deliveredQuantity;
  final double remainingQuantity;
  final double unitPrice;
  final double lineAmount;
  final bool isClosed;
  final String description;
  final String packageCode;
  final String projectCode;
  final String modelCode;
  final String lineGuid;
  final WarehouseOrderLineGreenGrocerCase? greenGrocerCase;

  factory WarehouseOrderDetailItem.fromJson(JsonMap json) {
    return WarehouseOrderDetailItem(
      lineNo: _readInt(json['lineNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity: _readDouble(json['quantity']),
      deliveredQuantity: _readDouble(json['deliveredQuantity']),
      remainingQuantity: _readDouble(json['remainingQuantity']),
      unitPrice: _readDouble(json['unitPrice']),
      lineAmount: _readDouble(json['lineAmount']),
      isClosed: _readBool(json['isClosed']),
      description: _readString(json['description']),
      packageCode: _readString(json['packageCode']),
      projectCode: _readString(json['projectCode']),
      modelCode: _readFirstString(json, const <String>[
        'modelCode',
        'productModelCode',
        'stockModelCode',
      ]),
      lineGuid: _readString(json['lineGuid']),
      greenGrocerCase: _readGreenGrocerCase(json['greenGrocerCase']),
    );
  }
}

WarehouseOrderLineGreenGrocerCase? _readGreenGrocerCase(Object? value) {
  final map = _readJsonMap(value);
  if (map == null) {
    return null;
  }

  return WarehouseOrderLineGreenGrocerCase.fromJson(map);
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final raw = value?.toString().trim().toLowerCase();

  return raw == 'true' || raw == '1';
}

String _toApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');

  return '${normalized.year}-$month-$day';
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

double _readPositiveDouble(Object? value, {double fallback = 1}) {
  final parsed = _readDouble(value);
  return parsed > 0 ? parsed : fallback;
}

double? _readNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return null;
  }

  return double.tryParse(raw);
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

  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return null;
  }

  return int.tryParse(raw);
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}

String _readFirstString(JsonMap json, List<String> keys) {
  for (final key in keys) {
    final value = _readString(json[key]).trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

JsonMap? _readJsonMap(Object? value) {
  return switch (value) {
    final JsonMap map => map,
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}
