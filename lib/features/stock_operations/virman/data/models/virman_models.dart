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
    this.incomingLineCount = 0,
    this.outgoingLineCount = 0,
    this.incomingQuantity = 0,
    this.outgoingQuantity = 0,
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
  final int incomingLineCount;
  final int outgoingLineCount;
  final double incomingQuantity;
  final double outgoingQuantity;

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
      incomingLineCount: _readInt(json['incomingLineCount']),
      outgoingLineCount: _readInt(json['outgoingLineCount']),
      incomingQuantity: _readDouble(json['incomingQuantity']),
      outgoingQuantity: _readDouble(json['outgoingQuantity']),
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
            (item) => VirmanLineItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
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
    this.incomingLineCount = 0,
    this.outgoingLineCount = 0,
    this.incomingQuantity = 0,
    this.outgoingQuantity = 0,
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
  final int incomingLineCount;
  final int outgoingLineCount;
  final double incomingQuantity;
  final double outgoingQuantity;

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
      incomingLineCount: _readInt(json['incomingLineCount']),
      outgoingLineCount: _readInt(json['outgoingLineCount']),
      incomingQuantity: _readDouble(json['incomingQuantity']),
      outgoingQuantity: _readDouble(json['outgoingQuantity']),
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

class VirmanConversionSuggestion {
  const VirmanConversionSuggestion({
    required this.sourceStockCode,
    required this.sourceStockName,
    required this.sourceUnitName,
    required this.sourceQuantity,
    required this.targetStockCode,
    required this.targetStockName,
    required this.targetUnitName,
    required this.multiplier,
    required this.targetQuantity,
    required this.sampleCount,
    required this.targetMatchCount,
    required this.multiplierMatchCount,
    required this.targetConfidencePercent,
    required this.multiplierConfidencePercent,
    required this.confidencePercent,
    required this.isReliable,
    required this.suggestionSource,
    required this.lookbackStartDate,
    required this.lookbackEndDate,
    required this.minimumSampleCount,
    required this.maximumSampleCount,
    required this.minimumConfidencePercent,
    required this.warning,
  });

  final String sourceStockCode;
  final String sourceStockName;
  final String sourceUnitName;
  final double sourceQuantity;
  final String? targetStockCode;
  final String? targetStockName;
  final String? targetUnitName;
  final double? multiplier;
  final double? targetQuantity;
  final int sampleCount;
  final int targetMatchCount;
  final int multiplierMatchCount;
  final double targetConfidencePercent;
  final double multiplierConfidencePercent;
  final double confidencePercent;
  final bool isReliable;
  final String suggestionSource;
  final DateTime? lookbackStartDate;
  final DateTime? lookbackEndDate;
  final int minimumSampleCount;
  final int maximumSampleCount;
  final double minimumConfidencePercent;
  final String? warning;

  bool get hasUsableTarget =>
      isReliable &&
      (targetStockCode?.trim().isNotEmpty ?? false) &&
      (multiplier ?? 0) > 0 &&
      (targetQuantity ?? 0) > 0;

  factory VirmanConversionSuggestion.fromJson(JsonMap json) {
    return VirmanConversionSuggestion(
      sourceStockCode: _readString(json['sourceStockCode']),
      sourceStockName: _readString(json['sourceStockName']),
      sourceUnitName: _readString(json['sourceUnitName']),
      sourceQuantity: _readDouble(json['sourceQuantity']),
      targetStockCode: _readNullableString(json['targetStockCode']),
      targetStockName: _readNullableString(json['targetStockName']),
      targetUnitName: _readNullableString(json['targetUnitName']),
      multiplier: _readNullableDouble(json['multiplier']),
      targetQuantity: _readNullableDouble(json['targetQuantity']),
      sampleCount: _readInt(json['sampleCount']),
      targetMatchCount: _readInt(json['targetMatchCount']),
      multiplierMatchCount: _readInt(json['multiplierMatchCount']),
      targetConfidencePercent: _readDouble(json['targetConfidencePercent']),
      multiplierConfidencePercent: _readDouble(
        json['multiplierConfidencePercent'],
      ),
      confidencePercent: _readDouble(json['confidencePercent']),
      isReliable: _readBool(json['isReliable']),
      suggestionSource: _readString(json['suggestionSource']),
      lookbackStartDate: _readDate(json['lookbackStartDate']),
      lookbackEndDate: _readDate(json['lookbackEndDate']),
      minimumSampleCount: _readInt(json['minimumSampleCount']),
      maximumSampleCount: _readInt(json['maximumSampleCount']),
      minimumConfidencePercent: _readDouble(json['minimumConfidencePercent']),
      warning: _readNullableString(json['warning']),
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
    this.clientRequestId,
  });

  final String? clientRequestId;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String description;
  final List<VirmanCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      if (clientRequestId != null && clientRequestId!.trim().isNotEmpty)
        'clientRequestId': clientRequestId!.trim(),
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      'description': description,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory VirmanCreateRequest.fromJson(JsonMap json) {
    final rawLines = json['lines'];
    return VirmanCreateRequest(
      clientRequestId: _readString(json['clientRequestId']),
      movementDate: _readDate(json['movementDate']) ?? DateTime.now(),
      documentDate: _readDate(json['documentDate']) ?? DateTime.now(),
      documentNo: _readString(json['documentNo']),
      description: _readString(json['description']),
      lines: rawLines is List
          ? rawLines
                .whereType<Map>()
                .map(
                  (item) => VirmanCreateLine.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <VirmanCreateLine>[],
    );
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

  factory VirmanCreateLine.fromJson(JsonMap json) {
    return VirmanCreateLine(
      stockCode: _readString(json['stockCode']),
      movementType: _readInt(json['movementType']),
      quantity: _readDouble(json['quantity']),
      unitPointer: _readInt(json['unitPointer']),
      description: _readString(json['description']),
      partyCode: _readString(json['partyCode']),
      lotNo: _readInt(json['lotNo']),
      projectCode: _readString(json['projectCode']),
    );
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
    this.incomingLineCount = 0,
    this.outgoingLineCount = 0,
    this.incomingQuantity = 0,
    this.outgoingQuantity = 0,
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
  final int incomingLineCount;
  final int outgoingLineCount;
  final double incomingQuantity;
  final double outgoingQuantity;

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
      incomingLineCount: _readInt(json['incomingLineCount']),
      outgoingLineCount: _readInt(json['outgoingLineCount']),
      incomingQuantity: _readDouble(json['incomingQuantity']),
      outgoingQuantity: _readDouble(json['outgoingQuantity']),
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}

String? _readNullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
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

List<int> _readIntList(Object? value) {
  final items = value as List<dynamic>? ?? const <dynamic>[];
  return items.map((item) => _readInt(item)).toList(growable: false);
}
