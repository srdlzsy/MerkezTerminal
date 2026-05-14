import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class CompanyAcceptanceCreateRequest {
  const CompanyAcceptanceCreateRequest({
    required this.customerCode,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.deliverer,
    required this.receiver,
    required this.description,
    required this.allowOrderOverReceiving,
    required this.lines,
    this.clientRequestId,
  });

  final String customerCode;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String deliverer;
  final String receiver;
  final String description;
  final bool allowOrderOverReceiving;
  final List<CompanyAcceptanceCreateLine> lines;
  final String? clientRequestId;

  JsonMap toJson() {
    return <String, dynamic>{
      'customerCode': customerCode,
      'movementDate': _toApiDate(movementDate),
      'documentDate': _toApiDate(documentDate),
      'documentNo': documentNo,
      if (clientRequestId != null && clientRequestId!.trim().isNotEmpty)
        'clientRequestId': clientRequestId!.trim(),
      'deliverer': deliverer,
      'receiver': receiver,
      'description': description,
      'allowOrderOverReceiving': allowOrderOverReceiving,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory CompanyAcceptanceCreateRequest.fromJson(JsonMap json) {
    return CompanyAcceptanceCreateRequest(
      customerCode: _readString(json['customerCode']),
      movementDate: _readDate(json['movementDate']) ?? DateTime.now(),
      documentDate: _readDate(json['documentDate']) ?? DateTime.now(),
      documentNo: _readString(json['documentNo']),
      deliverer: _readString(json['deliverer']),
      receiver: _readString(json['receiver']),
      description: _readString(json['description']),
      allowOrderOverReceiving: _readBool(json['allowOrderOverReceiving']),
      clientRequestId: _readString(json['clientRequestId']).trim().isEmpty
          ? null
          : _readString(json['clientRequestId']),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CompanyAcceptanceCreateLine.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class CompanyAcceptanceCreateLine {
  const CompanyAcceptanceCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.lastConsumingDate,
    required this.orderGuid,
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
  final DateTime? lastConsumingDate;
  final String? orderGuid;
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
      if (lastConsumingDate != null)
        'lastConsumingDate': _toApiDate(lastConsumingDate!),
      'orderGuid': orderGuid,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
      'customerResponsibilityCenter': customerResponsibilityCenter,
      'productResponsibilityCenter': productResponsibilityCenter,
    };
  }

  factory CompanyAcceptanceCreateLine.fromJson(JsonMap json) {
    return CompanyAcceptanceCreateLine(
      stockCode: _readString(json['stockCode']),
      quantity: _readDouble(json['quantity']),
      unitPrice: _readDouble(json['unitPrice']),
      unitPointer: _readInt(json['unitPointer']),
      lastConsumingDate: _readDate(json['lastConsumingDate']),
      orderGuid: _readString(json['orderGuid']).trim().isEmpty
          ? null
          : _readString(json['orderGuid']),
      description: _readString(json['description']),
      partyCode: _readString(json['partyCode']),
      lotNo: _readInt(json['lotNo']),
      projectCode: _readString(json['projectCode']),
      customerResponsibilityCenter: _readString(
        json['customerResponsibilityCenter'],
      ),
      productResponsibilityCenter: _readString(
        json['productResponsibilityCenter'],
      ),
    );
  }
}

class CompanyAcceptanceCreateResult {
  const CompanyAcceptanceCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.movementDate,
    required this.documentDate,
    required this.documentNo,
    required this.warehouseNo,
    required this.customerCode,
    required this.lineCount,
    required this.totalReceivedQuantity,
    required this.totalOrderLinkedQuantity,
    required this.totalOrderlessQuantity,
    required this.totalOrderOverReceivedQuantity,
    required this.totalAmount,
    required this.writeConnectionName,
    required this.lines,
  });

  final String documentSerie;
  final int documentOrderNo;
  final DateTime? movementDate;
  final DateTime? documentDate;
  final String documentNo;
  final int warehouseNo;
  final String customerCode;
  final int lineCount;
  final double totalReceivedQuantity;
  final double totalOrderLinkedQuantity;
  final double totalOrderlessQuantity;
  final double totalOrderOverReceivedQuantity;
  final double totalAmount;
  final String writeConnectionName;
  final List<CompanyAcceptanceCreateLineResult> lines;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory CompanyAcceptanceCreateResult.fromJson(JsonMap json) {
    return CompanyAcceptanceCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      customerCode: _readString(json['customerCode']),
      lineCount: _readInt(json['lineCount']),
      totalReceivedQuantity: _readDouble(json['totalReceivedQuantity']),
      totalOrderLinkedQuantity: _readDouble(json['totalOrderLinkedQuantity']),
      totalOrderlessQuantity: _readDouble(json['totalOrderlessQuantity']),
      totalOrderOverReceivedQuantity: _readDouble(
        json['totalOrderOverReceivedQuantity'],
      ),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CompanyAcceptanceCreateLineResult.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class CompanyAcceptanceOfflineSyncStatus {
  const CompanyAcceptanceOfflineSyncStatus({
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
  final CompanyAcceptanceCreateResult? result;

  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory CompanyAcceptanceOfflineSyncStatus.fromJson(JsonMap json) {
    final resultJson = json['result'];
    final mappedResult = resultJson is JsonMap && resultJson.isNotEmpty
        ? CompanyAcceptanceCreateResult.fromJson(resultJson)
        : null;

    return CompanyAcceptanceOfflineSyncStatus(
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

class CompanyAcceptanceCreateLineResult {
  const CompanyAcceptanceCreateLineResult({
    required this.movementGuid,
    required this.sourceLineNo,
    required this.movementLineNo,
    required this.stockCode,
    required this.orderGuid,
    required this.isOrderLinked,
    required this.receivingMode,
    required this.requestedQuantity,
    required this.acceptedQuantity,
    required this.orderLinkedQuantity,
    required this.orderlessQuantity,
    required this.orderRemainingBefore,
    required this.orderRemainingAfter,
  });

  final String movementGuid;
  final int sourceLineNo;
  final int movementLineNo;
  final String stockCode;
  final String orderGuid;
  final bool isOrderLinked;
  final String receivingMode;
  final double requestedQuantity;
  final double acceptedQuantity;
  final double orderLinkedQuantity;
  final double orderlessQuantity;
  final double orderRemainingBefore;
  final double orderRemainingAfter;

  factory CompanyAcceptanceCreateLineResult.fromJson(JsonMap json) {
    return CompanyAcceptanceCreateLineResult(
      movementGuid: _readString(json['movementGuid']),
      sourceLineNo: _readInt(json['sourceLineNo']),
      movementLineNo: _readInt(json['movementLineNo']),
      stockCode: _readString(json['stockCode']),
      orderGuid: _readString(json['orderGuid']),
      isOrderLinked: _readBool(json['isOrderLinked']),
      receivingMode: _readString(json['receivingMode']),
      requestedQuantity: _readDouble(json['requestedQuantity']),
      acceptedQuantity: _readDouble(json['acceptedQuantity']),
      orderLinkedQuantity: _readDouble(json['orderLinkedQuantity']),
      orderlessQuantity: _readDouble(json['orderlessQuantity']),
      orderRemainingBefore: _readDouble(json['orderRemainingBefore']),
      orderRemainingAfter: _readDouble(json['orderRemainingAfter']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
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

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}
