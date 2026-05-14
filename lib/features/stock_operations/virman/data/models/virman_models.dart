import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class VirmanListFilter {
  const VirmanListFilter({
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

class VirmanListItem {
  const VirmanListItem({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.documentType,
    required this.movementGenre,
    required this.movementTypes,
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
  final int warehouseNo;
  final String warehouseName;
  final int documentType;
  final int movementGenre;
  final List<int> movementTypes;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory VirmanListItem.fromJson(JsonMap json) {
    return VirmanListItem(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      documentType: _readInt(json['documentType']),
      movementGenre: _readInt(json['movementGenre']),
      movementTypes: _readIntList(json['movementTypes']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class VirmanDetail {
  const VirmanDetail({required this.header, required this.items});

  final VirmanHeader header;
  final List<VirmanLineItem> items;

  factory VirmanDetail.fromJson(JsonMap json) {
    return VirmanDetail(
      header: VirmanHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                VirmanLineItem.fromJson(item as JsonMap? ?? <String, dynamic>{}),
          )
          .toList(growable: false),
    );
  }
}

class VirmanHeader {
  const VirmanHeader({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.documentType,
    required this.movementGenre,
    required this.movementTypes,
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
  final int warehouseNo;
  final String warehouseName;
  final int documentType;
  final int movementGenre;
  final List<int> movementTypes;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory VirmanHeader.fromJson(JsonMap json) {
    return VirmanHeader(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      documentType: _readInt(json['documentType']),
      movementGenre: _readInt(json['movementGenre']),
      movementTypes: _readIntList(json['movementTypes']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class VirmanLineItem {
  const VirmanLineItem({
    required this.rowNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.movementType,
    required this.quantity,
    required this.quantity2,
    required this.unitPrice,
    required this.lineAmount,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
  });

  final int rowNo;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final int movementType;
  final double quantity;
  final double quantity2;
  final double unitPrice;
  final double lineAmount;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;

  factory VirmanLineItem.fromJson(JsonMap json) {
    return VirmanLineItem(
      rowNo: _readInt(json['rowNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      movementType: _readInt(json['movementType']),
      quantity: _readDouble(json['quantity']),
      quantity2: _readDouble(json['quantity2']),
      unitPrice: _readDouble(json['unitPrice']),
      lineAmount: _readDouble(json['lineAmount']),
      description: _readString(json['description']),
      partyCode: _readString(json['partyCode']),
      lotNo: _readInt(json['lotNo']),
      projectCode: _readString(json['projectCode']),
    );
  }
}

class VirmanCreateRequest {
  const VirmanCreateRequest({
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.description,
    required this.lines,
  });

  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String description;
  final List<VirmanCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class VirmanCreateLine {
  const VirmanCreateLine({
    required this.stockCode,
    required this.movementType,
    required this.quantity,
    required this.unitPointer,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
  });

  final String stockCode;
  final int movementType;
  final double quantity;
  final int unitPointer;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'movementType': movementType,
      'quantity': quantity,
      'unitPointer': unitPointer,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
    };
  }
}

class VirmanCreateResult {
  const VirmanCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.warehouseNo,
    required this.movementTypes,
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
  final List<int> movementTypes;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory VirmanCreateResult.fromJson(JsonMap json) {
    return VirmanCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      movementTypes: _readIntList(json['movementTypes']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}

List<int> _readIntList(Object? value) {
  final items = value as List<dynamic>? ?? const <dynamic>[];
  return items.map((item) => _readInt(item)).toList(growable: false);
}
