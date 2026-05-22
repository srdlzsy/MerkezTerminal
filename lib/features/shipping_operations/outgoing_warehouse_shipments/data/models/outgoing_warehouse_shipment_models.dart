import 'dart:typed_data';

import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class WarehouseShipmentListFilter {
  const WarehouseShipmentListFilter({
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

class WarehouseShipmentListItem {
  const WarehouseShipmentListItem({
    required this.documentDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    this.isReturn = false,
    required this.sourceWarehouseNo,
    required this.sourceWarehouse,
    required this.targetWarehouseNo,
    required this.targetWarehouse,
    required this.shippingWarehouseNo,
    required this.shippingState,
    required this.plaque,
    required this.driverNameSurname,
    required this.driverTckn,
    required this.descriptionEttn,
    required this.warehouseOrderNo,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final DateTime? documentDate;
  final DateTime? movementDate;
  final String documentNo;
  final String documentSerie;
  final int documentOrderNo;
  final bool isReturn;
  final int sourceWarehouseNo;
  final String sourceWarehouse;
  final int targetWarehouseNo;
  final String targetWarehouse;
  final int shippingWarehouseNo;
  final int shippingState;
  final String plaque;
  final String driverNameSurname;
  final String driverTckn;
  final String descriptionEttn;
  final String warehouseOrderNo;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  bool get hasDocumentNo => documentNo.trim().isNotEmpty;
  bool get canConvertToEDespatch => !hasDocumentNo;

  factory WarehouseShipmentListItem.fromJson(JsonMap json) {
    return WarehouseShipmentListItem(
      documentDate: _readDate(json['documentDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      isReturn: _readBool(json['isReturn']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      sourceWarehouse: _readString(json['sourceWarehouse']),
      targetWarehouseNo: _readInt(json['targetWarehouseNo']),
      targetWarehouse: _readString(json['targetWarehouse']),
      shippingWarehouseNo: _readInt(json['shippingWarehouseNo']),
      shippingState: _readInt(json['shippingState']),
      plaque: _readString(json['plaque']),
      driverNameSurname: _readString(json['driverNameSurname']),
      driverTckn: _readString(json['driverTckn']),
      descriptionEttn: _readString(json['descriptionEttn']),
      warehouseOrderNo: _readString(json['warehouseOrderNo']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class WarehouseShipmentDetail {
  const WarehouseShipmentDetail({required this.header, required this.items});

  final WarehouseShipmentDetailHeader header;
  final List<WarehouseShipmentDetailItem> items;

  factory WarehouseShipmentDetail.fromJson(JsonMap json) {
    return WarehouseShipmentDetail(
      header: WarehouseShipmentDetailHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => WarehouseShipmentDetailItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class WarehouseShipmentDetailHeader {
  const WarehouseShipmentDetailHeader({
    required this.documentDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    this.isReturn = false,
    required this.sourceWarehouseNo,
    required this.sourceWarehouse,
    required this.targetWarehouseNo,
    required this.targetWarehouse,
    required this.shippingWarehouseNo,
    required this.shippingState,
    required this.plaque,
    required this.driverNameSurname,
    required this.driverTckn,
    required this.descriptionEttn,
    required this.warehouseOrderNo,
    required this.warehouseOrderNos,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final DateTime? documentDate;
  final DateTime? movementDate;
  final String documentNo;
  final String documentSerie;
  final int documentOrderNo;
  final bool isReturn;
  final int sourceWarehouseNo;
  final String sourceWarehouse;
  final int targetWarehouseNo;
  final String targetWarehouse;
  final int shippingWarehouseNo;
  final int shippingState;
  final String plaque;
  final String driverNameSurname;
  final String driverTckn;
  final String descriptionEttn;
  final String warehouseOrderNo;
  final List<String> warehouseOrderNos;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  bool get hasDocumentNo => documentNo.trim().isNotEmpty;
  bool get canConvertToEDespatch => !hasDocumentNo;

  factory WarehouseShipmentDetailHeader.fromJson(JsonMap json) {
    return WarehouseShipmentDetailHeader(
      documentDate: _readDate(json['documentDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      isReturn: _readBool(json['isReturn']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      sourceWarehouse: _readString(json['sourceWarehouse']),
      targetWarehouseNo: _readInt(json['targetWarehouseNo']),
      targetWarehouse: _readString(json['targetWarehouse']),
      shippingWarehouseNo: _readInt(json['shippingWarehouseNo']),
      shippingState: _readInt(json['shippingState']),
      plaque: _readString(json['plaque']),
      driverNameSurname: _readString(json['driverNameSurname']),
      driverTckn: _readString(json['driverTckn']),
      descriptionEttn: _readString(json['descriptionEttn']),
      warehouseOrderNo: _readString(json['warehouseOrderNo']),
      warehouseOrderNos: _readStringList(json['warehouseOrderNos']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class WarehouseShipmentDetailItem {
  const WarehouseShipmentDetailItem({
    required this.movementGuid,
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.quantity,
    required this.unitPrice,
    required this.lineAmount,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
    required this.warehouseOrderNo,
  });

  final String movementGuid;
  final int lineNo;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double quantity;
  final double unitPrice;
  final double lineAmount;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;
  final String warehouseOrderNo;

  factory WarehouseShipmentDetailItem.fromJson(JsonMap json) {
    return WarehouseShipmentDetailItem(
      movementGuid: _readString(json['movementGuid']),
      lineNo: _readInt(json['lineNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity: _readDouble(json['quantity']),
      unitPrice: _readDouble(json['unitPrice']),
      lineAmount: _readDouble(json['lineAmount']),
      description: _readString(json['description']),
      partyCode: _readString(json['partyCode']),
      lotNo: _readInt(json['lotNo']),
      projectCode: _readString(json['projectCode']),
      warehouseOrderNo: _readString(json['warehouseOrderNo']),
    );
  }
}

class WarehouseShipmentCreateRequest {
  const WarehouseShipmentCreateRequest({
    required this.targetWarehouseNo,
    required this.transitWarehouseNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.description,
    required this.lines,
  });

  final int targetWarehouseNo;
  final int? transitWarehouseNo;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String description;
  final List<WarehouseShipmentCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'targetWarehouseNo': targetWarehouseNo,
      if (transitWarehouseNo != null) 'transitWarehouseNo': transitWarehouseNo,
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class WarehouseShipmentCreateLine {
  const WarehouseShipmentCreateLine({
    this.warehouseOrderLineGuid,
    required this.stockCode,
    required this.quantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
  });

  final String? warehouseOrderLineGuid;
  final String stockCode;
  final double quantity;
  final double unitPrice;
  final int unitPointer;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;

  JsonMap toJson() {
    return <String, dynamic>{
      if (warehouseOrderLineGuid != null &&
          warehouseOrderLineGuid!.trim().isNotEmpty)
        'warehouseOrderLineGuid': warehouseOrderLineGuid,
      'stockCode': stockCode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
    };
  }
}

class WarehouseShipmentCreateResult {
  const WarehouseShipmentCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.sourceWarehouseNo,
    required this.targetWarehouseNo,
    required this.transitWarehouseNo,
    required this.lineCount,
    required this.linkedWarehouseOrderLineCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.writeConnectionName,
  });

  final String documentSerie;
  final int documentOrderNo;
  final DateTime? movementDate;
  final DateTime? documentDate;
  final String documentNo;
  final int sourceWarehouseNo;
  final int targetWarehouseNo;
  final int transitWarehouseNo;
  final int lineCount;
  final int linkedWarehouseOrderLineCount;
  final double totalQuantity;
  final double totalAmount;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory WarehouseShipmentCreateResult.fromJson(JsonMap json) {
    return WarehouseShipmentCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      targetWarehouseNo: _readInt(json['targetWarehouseNo']),
      transitWarehouseNo: _readInt(json['transitWarehouseNo']),
      lineCount: _readInt(json['lineCount']),
      linkedWarehouseOrderLineCount: _readInt(
        json['linkedWarehouseOrderLineCount'],
      ),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
    );
  }
}

class WarehouseShipmentPdfDocument {
  const WarehouseShipmentPdfDocument({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
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

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}

List<String> _readStringList(Object? value) {
  final items = value as List<dynamic>? ?? const <dynamic>[];
  return items.map((item) => item.toString()).toList(growable: false);
}
