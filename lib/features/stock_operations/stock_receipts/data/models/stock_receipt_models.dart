import 'package:furpa_merkez_terminal/core/network/api_client.dart';

enum StockReceiptKind {
  outage,
  expense,
}

extension StockReceiptKindX on StockReceiptKind {
  String get pathSegment => switch (this) {
    StockReceiptKind.outage => 'zayiat-fisleri',
    StockReceiptKind.expense => 'masraf-fisleri',
  };

  String get pageTitle => switch (this) {
    StockReceiptKind.outage => 'Zayiat Fisleri',
    StockReceiptKind.expense => 'Masraf Fisleri',
  };

  String get createTitle => switch (this) {
    StockReceiptKind.outage => 'Yeni Zayiat Fisi',
    StockReceiptKind.expense => 'Yeni Masraf Fisi',
  };

  String get createButtonLabel => switch (this) {
    StockReceiptKind.outage => 'Yeni Zayiat',
    StockReceiptKind.expense => 'Yeni Masraf',
  };
}

class StockReceiptListFilter {
  const StockReceiptListFilter({
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

class StockReceiptListItem {
  const StockReceiptListItem({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.creator,
    required this.acceptor,
    required this.workOrderExpenseCode,
    required this.documentType,
    required this.movementType,
    required this.movementGenre,
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
  final String creator;
  final String acceptor;
  final String workOrderExpenseCode;
  final int documentType;
  final int movementType;
  final int movementGenre;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory StockReceiptListItem.fromJson(JsonMap json) {
    return StockReceiptListItem(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      creator: _readString(json['creator']),
      acceptor: _readString(json['acceptor']),
      workOrderExpenseCode: _readString(json['workOrderExpenseCode']),
      documentType: _readInt(json['documentType']),
      movementType: _readInt(json['movementType']),
      movementGenre: _readInt(json['movementGenre']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class StockReceiptDetail {
  const StockReceiptDetail({
    required this.header,
    required this.items,
  });

  final StockReceiptHeader header;
  final List<StockReceiptLineItem> items;

  factory StockReceiptDetail.fromJson(JsonMap json) {
    return StockReceiptDetail(
      header: StockReceiptHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => StockReceiptLineItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class StockReceiptHeader {
  const StockReceiptHeader({
    required this.documentDate,
    required this.movementCreateDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.warehouseNo,
    required this.warehouseName,
    required this.creator,
    required this.acceptor,
    required this.workOrderExpenseCode,
    required this.documentType,
    required this.movementType,
    required this.movementGenre,
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
  final String creator;
  final String acceptor;
  final String workOrderExpenseCode;
  final int documentType;
  final int movementType;
  final int movementGenre;
  final String description;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory StockReceiptHeader.fromJson(JsonMap json) {
    return StockReceiptHeader(
      documentDate: _readDate(json['documentDate']),
      movementCreateDate: _readDate(json['movementCreateDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      creator: _readString(json['creator']),
      acceptor: _readString(json['acceptor']),
      workOrderExpenseCode: _readString(json['workOrderExpenseCode']),
      documentType: _readInt(json['documentType']),
      movementType: _readInt(json['movementType']),
      movementGenre: _readInt(json['movementGenre']),
      description: _readString(json['description']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class StockReceiptLineItem {
  const StockReceiptLineItem({
    required this.rowNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
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
  final double quantity;
  final double quantity2;
  final double unitPrice;
  final double lineAmount;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;

  factory StockReceiptLineItem.fromJson(JsonMap json) {
    return StockReceiptLineItem(
      rowNo: _readInt(json['rowNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
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

class StockReceiptCreateRequest {
  const StockReceiptCreateRequest({
    required this.creator,
    required this.acceptor,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.description,
    required this.lines,
  });

  final String creator;
  final String acceptor;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String description;
  final List<StockReceiptCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'creator': creator,
      'acceptor': acceptor,
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class StockReceiptCreateLine {
  const StockReceiptCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.unitPointer,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
  });

  final String stockCode;
  final double quantity;
  final int unitPointer;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'quantity': quantity,
      'unitPointer': unitPointer,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
    };
  }
}

class StockReceiptCreateResult {
  const StockReceiptCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.warehouseNo,
    required this.creator,
    required this.acceptor,
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
  final String creator;
  final String acceptor;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory StockReceiptCreateResult.fromJson(JsonMap json) {
    return StockReceiptCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      creator: _readString(json['creator']),
      acceptor: _readString(json['acceptor']),
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
