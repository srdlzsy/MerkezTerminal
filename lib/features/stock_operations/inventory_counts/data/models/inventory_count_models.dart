import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class InventoryCountListFilter {
  const InventoryCountListFilter({
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

class InventoryCountCreateRequest {
  const InventoryCountCreateRequest({
    required this.name,
    required this.documentDate,
    required this.lines,
    this.clientRequestId,
  });

  final String name;
  final DateTime documentDate;
  final List<InventoryCountCreateLine> lines;
  final String? clientRequestId;

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'documentDate': _toApiDate(documentDate),
      if (clientRequestId != null && clientRequestId!.trim().isNotEmpty)
        'clientRequestId': clientRequestId!.trim(),
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory InventoryCountCreateRequest.fromJson(JsonMap json) {
    return InventoryCountCreateRequest(
      name: _readString(json['name']),
      documentDate: _readDate(json['documentDate']) ?? DateTime.now(),
      clientRequestId: _readString(json['clientRequestId']).trim().isEmpty
          ? null
          : _readString(json['clientRequestId']),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => InventoryCountCreateLine.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class InventoryCountCreateLine {
  const InventoryCountCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.barcode,
    required this.unitPointer,
  });

  final String stockCode;
  final double quantity;
  final String barcode;
  final int unitPointer;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode.trim(),
      'quantity': quantity,
      if (barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
      'unitPointer': unitPointer,
    };
  }

  factory InventoryCountCreateLine.fromJson(JsonMap json) {
    return InventoryCountCreateLine(
      stockCode: _readString(json['stockCode']),
      quantity: _readDouble(json['quantity']),
      barcode: _readString(json['barcode']),
      unitPointer: _readInt(json['unitPointer']),
    );
  }
}

class InventoryCountCreateResult {
  const InventoryCountCreateResult({
    required this.documentNo,
    required this.documentDate,
    required this.warehouseNo,
    required this.name,
    required this.lineCount,
    required this.totalQuantity,
    required this.writeConnectionName,
  });

  final int documentNo;
  final DateTime? documentDate;
  final int warehouseNo;
  final String name;
  final int lineCount;
  final double totalQuantity;
  final String writeConnectionName;

  factory InventoryCountCreateResult.fromJson(JsonMap json) {
    return InventoryCountCreateResult(
      documentNo: _readInt(json['documentNo']),
      documentDate: _readDate(json['documentDate']),
      warehouseNo: _readInt(json['warehouseNo']),
      name: _readString(json['name']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      writeConnectionName: _readString(json['writeConnectionName']),
    );
  }
}

class InventoryCountOfflineSyncStatus {
  const InventoryCountOfflineSyncStatus({
    required this.clientRequestId,
    required this.operationCode,
    required this.status,
    required this.createdAtUtc,
    required this.completedAtUtc,
    required this.errorMessage,
    required this.result,
  });

  final String clientRequestId;
  final String operationCode;
  final String status;
  final DateTime? createdAtUtc;
  final DateTime? completedAtUtc;
  final String? errorMessage;
  final InventoryCountCreateResult? result;

  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory InventoryCountOfflineSyncStatus.fromJson(JsonMap json) {
    final resultJson = json['result'];
    final mappedResult = resultJson is JsonMap && resultJson.isNotEmpty
        ? InventoryCountCreateResult.fromJson(resultJson)
        : null;

    return InventoryCountOfflineSyncStatus(
      clientRequestId: _readString(json['clientRequestId']),
      operationCode: _readString(json['operationCode']),
      status: _readString(json['status']),
      createdAtUtc: _readDate(json['createdAtUtc']),
      completedAtUtc: _readDate(json['completedAtUtc']),
      errorMessage: _readString(json['errorMessage']).trim().isEmpty
          ? null
          : _readString(json['errorMessage']),
      result: mappedResult,
    );
  }
}

class InventoryCountListItem {
  const InventoryCountListItem({
    required this.documentDate,
    required this.createdAt,
    required this.documentNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.name,
    required this.lineCount,
    required this.totalQuantity,
  });

  final DateTime? documentDate;
  final DateTime? createdAt;
  final int documentNo;
  final int warehouseNo;
  final String warehouseName;
  final String name;
  final int lineCount;
  final double totalQuantity;

  factory InventoryCountListItem.fromJson(JsonMap json) {
    return InventoryCountListItem(
      documentDate: _readDate(json['documentDate']),
      createdAt: _readDate(json['createdAt']),
      documentNo: _readInt(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      name: _readString(json['name']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
    );
  }
}

class InventoryCountDetail {
  const InventoryCountDetail({required this.header, required this.items});

  final InventoryCountHeader header;
  final List<InventoryCountLineItem> items;

  factory InventoryCountDetail.fromJson(JsonMap json) {
    return InventoryCountDetail(
      header: InventoryCountHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => InventoryCountLineItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class InventoryCountHeader {
  const InventoryCountHeader({
    required this.documentDate,
    required this.createdAt,
    required this.documentNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.name,
    required this.lineCount,
    required this.totalQuantity,
  });

  final DateTime? documentDate;
  final DateTime? createdAt;
  final int documentNo;
  final int warehouseNo;
  final String warehouseName;
  final String name;
  final int lineCount;
  final double totalQuantity;

  factory InventoryCountHeader.fromJson(JsonMap json) {
    return InventoryCountHeader(
      documentDate: _readDate(json['documentDate']),
      createdAt: _readDate(json['createdAt']),
      documentNo: _readInt(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      name: _readString(json['name']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
    );
  }
}

class InventoryCountLineItem {
  const InventoryCountLineItem({
    required this.rowNo,
    required this.stockCode,
    required this.stockName,
    required this.barcode,
    required this.unitName,
    required this.unitPointer,
    required this.quantity1,
    required this.quantity2,
    required this.quantity3,
    required this.quantity4,
    required this.quantity5,
  });

  final int rowNo;
  final String stockCode;
  final String stockName;
  final String barcode;
  final String unitName;
  final int unitPointer;
  final double quantity1;
  final double quantity2;
  final double quantity3;
  final double quantity4;
  final double quantity5;

  double get totalQuantity =>
      quantity1 + quantity2 + quantity3 + quantity4 + quantity5;

  factory InventoryCountLineItem.fromJson(JsonMap json) {
    return InventoryCountLineItem(
      rowNo: _readInt(json['rowNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      barcode: _readString(json['barcode']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity1: _readDouble(json['quantity1']),
      quantity2: _readDouble(json['quantity2']),
      quantity3: _readDouble(json['quantity3']),
      quantity4: _readDouble(json['quantity4']),
      quantity5: _readDouble(json['quantity5']),
    );
  }
}

class InventoryCountProductLookupItem {
  const InventoryCountProductLookupItem({
    required this.warehouseNo,
    required this.barcode,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.price,
    required this.isGoodsAcceptanceBlocked,
  });

  final int warehouseNo;
  final String barcode;
  final String stockCode;
  final String stockName;
  final String unitName;
  final double price;
  final bool isGoodsAcceptanceBlocked;

  String get displayLabel => '$stockCode - $stockName';

  factory InventoryCountProductLookupItem.fromJson(JsonMap json) {
    return InventoryCountProductLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      price: _readDouble(json['price']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
    );
  }
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
