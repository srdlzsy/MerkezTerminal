import 'dart:typed_data';

import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class CompanyMovementListFilter {
  const CompanyMovementListFilter({
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

class CompanyMovementListItem {
  const CompanyMovementListItem({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.customerCode,
    required this.customerName,
    required this.customerTitle,
    required this.customerDisplayName,
    required this.warehouseNo,
    required this.warehouseName,
    required this.inputWarehouseNo,
    required this.inputWarehouseName,
    required this.outputWarehouseNo,
    required this.outputWarehouseName,
    required this.documentType,
    required this.movementType,
    required this.returnType,
    required this.description,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final DateTime? documentDate;
  final DateTime? movementCreateDate;
  final DateTime? movementDate;
  final String documentNo;
  final String documentSerie;
  final int documentOrderNo;
  final String customerCode;
  final String customerName;
  final String customerTitle;
  final String customerDisplayName;
  final int warehouseNo;
  final String warehouseName;
  final int inputWarehouseNo;
  final String inputWarehouseName;
  final int outputWarehouseNo;
  final String outputWarehouseName;
  final int documentType;
  final int movementType;
  final int returnType;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  bool get hasDocumentNo => documentNo.trim().isNotEmpty;
  bool get canConvertToEDespatch => !hasDocumentNo;

  factory CompanyMovementListItem.fromJson(JsonMap json) {
    return CompanyMovementListItem(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      customerTitle: _readString(json['customerTitle']),
      customerDisplayName: _readString(json['customerDisplayName']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      inputWarehouseNo: _readInt(json['inputWarehouseNo']),
      inputWarehouseName: _readString(json['inputWarehouseName']),
      outputWarehouseNo: _readInt(json['outputWarehouseNo']),
      outputWarehouseName: _readString(json['outputWarehouseName']),
      documentType: _readInt(json['documentType']),
      movementType: _readInt(json['movementType']),
      returnType: _readInt(json['returnType']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class CompanyMovementDetail {
  const CompanyMovementDetail({required this.header, required this.items});

  final CompanyMovementHeader header;
  final List<CompanyMovementLineItem> items;

  factory CompanyMovementDetail.fromJson(JsonMap json) {
    return CompanyMovementDetail(
      header: CompanyMovementHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CompanyMovementLineItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class CompanyMovementHeader {
  const CompanyMovementHeader({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.customerCode,
    required this.customerName,
    required this.customerTitle,
    required this.customerDisplayName,
    required this.customerAddress,
    required this.warehouseNo,
    required this.warehouseName,
    required this.inputWarehouseNo,
    required this.inputWarehouseName,
    required this.outputWarehouseNo,
    required this.outputWarehouseName,
    required this.documentType,
    required this.movementType,
    required this.returnType,
    required this.description,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final DateTime? documentDate;
  final DateTime? movementCreateDate;
  final DateTime? movementDate;
  final String documentNo;
  final String documentSerie;
  final int documentOrderNo;
  final String customerCode;
  final String customerName;
  final String customerTitle;
  final String customerDisplayName;
  final String customerAddress;
  final int warehouseNo;
  final String warehouseName;
  final int inputWarehouseNo;
  final String inputWarehouseName;
  final int outputWarehouseNo;
  final String outputWarehouseName;
  final int documentType;
  final int movementType;
  final int returnType;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  bool get hasDocumentNo => documentNo.trim().isNotEmpty;
  bool get canConvertToEDespatch => !hasDocumentNo;

  factory CompanyMovementHeader.fromJson(JsonMap json) {
    return CompanyMovementHeader(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      customerTitle: _readString(json['customerTitle']),
      customerDisplayName: _readString(json['customerDisplayName']),
      customerAddress: _readString(json['customerAddress']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      inputWarehouseNo: _readInt(json['inputWarehouseNo']),
      inputWarehouseName: _readString(json['inputWarehouseName']),
      outputWarehouseNo: _readInt(json['outputWarehouseNo']),
      outputWarehouseName: _readString(json['outputWarehouseName']),
      documentType: _readInt(json['documentType']),
      movementType: _readInt(json['movementType']),
      returnType: _readInt(json['returnType']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class CompanyMovementLineItem {
  const CompanyMovementLineItem({
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.quantity,
    required this.secondaryQuantity,
    required this.unitPrice,
    required this.lineAmount,
    required this.discountAmount,
    required this.expenseAmount,
    required this.taxAmount,
    required this.netWeight,
    required this.grossWeight,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
    required this.orderGuid,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double quantity;
  final double secondaryQuantity;
  final double unitPrice;
  final double lineAmount;
  final double discountAmount;
  final double expenseAmount;
  final double taxAmount;
  final double netWeight;
  final double grossWeight;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;
  final String orderGuid;

  factory CompanyMovementLineItem.fromJson(JsonMap json) {
    return CompanyMovementLineItem(
      lineNo: _readInt(json['lineNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity: _readDouble(json['quantity']),
      secondaryQuantity: _readDouble(json['secondaryQuantity']),
      unitPrice: _readDouble(json['unitPrice']),
      lineAmount: _readDouble(json['lineAmount']),
      discountAmount: _readDouble(json['discountAmount']),
      expenseAmount: _readDouble(json['expenseAmount']),
      taxAmount: _readDouble(json['taxAmount']),
      netWeight: _readDouble(json['netWeight']),
      grossWeight: _readDouble(json['grossWeight']),
      description: _readString(json['description']),
      partyCode: _readString(json['partyCode']),
      lotNo: _readInt(json['lotNo']),
      projectCode: _readString(json['projectCode']),
      orderGuid: _readString(json['orderGuid']),
    );
  }
}

class CompanyMovementCreateRequest {
  const CompanyMovementCreateRequest({
    required this.customerCode,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.description,
    required this.lines,
  });

  final String customerCode;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String description;
  final List<CompanyMovementCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'customerCode': customerCode,
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class CompanyMovementCreateLine {
  const CompanyMovementCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
    required this.customerResponsibilityCenter,
    required this.productResponsibilityCenter,
  });

  final String stockCode;
  final double quantity;
  final double unitPrice;
  final int unitPointer;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;
  final String customerResponsibilityCenter;
  final String productResponsibilityCenter;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
      'customerResponsibilityCenter': customerResponsibilityCenter,
      'productResponsibilityCenter': productResponsibilityCenter,
    };
  }
}

class CompanyMovementCreateResult {
  const CompanyMovementCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.warehouseNo,
    required this.customerCode,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.writeConnectionName,
  });

  final String documentSerie;
  final int documentOrderNo;
  final DateTime? movementDate;
  final DateTime? documentDate;
  final String documentNo;
  final int warehouseNo;
  final String customerCode;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory CompanyMovementCreateResult.fromJson(JsonMap json) {
    return CompanyMovementCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      customerCode: _readString(json['customerCode']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
    );
  }
}

class CompanyMovementPdfDocument {
  const CompanyMovementPdfDocument({
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}
