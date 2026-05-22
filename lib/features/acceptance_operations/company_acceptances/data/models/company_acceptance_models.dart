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
    this.autoCreateReturnForPartialAcceptance = true,
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
  final bool autoCreateReturnForPartialAcceptance;
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
      'autoCreateReturnForPartialAcceptance':
          autoCreateReturnForPartialAcceptance,
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
      autoCreateReturnForPartialAcceptance:
          json.containsKey('autoCreateReturnForPartialAcceptance')
          ? _readBool(json['autoCreateReturnForPartialAcceptance'])
          : true,
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
    required this.dispatchQuantity,
    required this.acceptedQuantity,
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
  final double dispatchQuantity;
  final double acceptedQuantity;
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
      'dispatchQuantity': dispatchQuantity,
      'acceptedQuantity': acceptedQuantity,
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
    final legacyQuantity = _readNullableDouble(json['quantity']);
    final dispatchQuantity =
        _readNullableDouble(json['dispatchQuantity']) ??
        legacyQuantity ??
        _readNullableDouble(json['acceptedQuantity']) ??
        0;
    final acceptedQuantity =
        _readNullableDouble(json['acceptedQuantity']) ??
        legacyQuantity ??
        dispatchQuantity;

    return CompanyAcceptanceCreateLine(
      stockCode: _readString(json['stockCode']),
      dispatchQuantity: dispatchQuantity,
      acceptedQuantity: acceptedQuantity,
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
    required this.totalDispatchQuantity,
    required this.totalNetAcceptedQuantity,
    required this.totalReturnedQuantity,
    required this.autoCreatedReturnLineCount,
    required this.autoCreatedReturnDocumentSerie,
    required this.autoCreatedReturnDocumentOrderNo,
    required this.returnEDespatchStatus,
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
  final double totalDispatchQuantity;
  final double totalNetAcceptedQuantity;
  final double totalReturnedQuantity;
  final int autoCreatedReturnLineCount;
  final String? autoCreatedReturnDocumentSerie;
  final int? autoCreatedReturnDocumentOrderNo;
  final String returnEDespatchStatus;
  final List<CompanyAcceptanceCreateLineResult> lines;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  String? get autoCreatedReturnDocumentNoLabel {
    final serie = autoCreatedReturnDocumentSerie?.trim() ?? '';
    final orderNo = autoCreatedReturnDocumentOrderNo;
    if (serie.isEmpty || orderNo == null || autoCreatedReturnLineCount <= 0) {
      return null;
    }

    return '$serie.$orderNo';
  }

  factory CompanyAcceptanceCreateResult.fromJson(JsonMap json) {
    final totalReceivedQuantity = _readDouble(json['totalReceivedQuantity']);
    return CompanyAcceptanceCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      movementDate: _readDate(json['movementDate']),
      documentDate: _readDate(json['documentDate']),
      documentNo: _readString(json['documentNo']),
      warehouseNo: _readInt(json['warehouseNo']),
      customerCode: _readString(json['customerCode']),
      lineCount: _readInt(json['lineCount']),
      totalReceivedQuantity: totalReceivedQuantity,
      totalOrderLinkedQuantity: _readDouble(json['totalOrderLinkedQuantity']),
      totalOrderlessQuantity: _readDouble(json['totalOrderlessQuantity']),
      totalOrderOverReceivedQuantity: _readDouble(
        json['totalOrderOverReceivedQuantity'],
      ),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
      totalDispatchQuantity:
          _readNullableDouble(json['totalDispatchQuantity']) ??
          totalReceivedQuantity,
      totalNetAcceptedQuantity:
          _readNullableDouble(json['totalNetAcceptedQuantity']) ??
          totalReceivedQuantity,
      totalReturnedQuantity: _readDouble(json['totalReturnedQuantity']),
      autoCreatedReturnLineCount: _readInt(json['autoCreatedReturnLineCount']),
      autoCreatedReturnDocumentSerie: _readNullableString(
        json['autoCreatedReturnDocumentSerie'],
      ),
      autoCreatedReturnDocumentOrderNo: _readNullableInt(
        json['autoCreatedReturnDocumentOrderNo'],
      ),
      returnEDespatchStatus:
          _readString(json['returnEDespatchStatus']).trim().isEmpty
          ? 'Yok'
          : _readString(json['returnEDespatchStatus']),
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

class CompanyAcceptanceEDespatchPrefill {
  const CompanyAcceptanceEDespatchPrefill({
    required this.isFound,
    required this.warehouseNo,
    required this.receivingContext,
    required this.ettn,
    required this.despatchNumber,
    required this.issueDate,
    required this.actualDespatchDate,
    required this.profileId,
    required this.despatchAdviceTypeCode,
    required this.notes,
    required this.sender,
    required this.receiver,
    required this.primaryCustomerSuggestion,
    required this.totalLineCount,
    required this.matchedLineCount,
    required this.unmatchedLineCount,
    required this.suggestedCustomers,
    required this.lines,
  });

  final bool isFound;
  final int warehouseNo;
  final String receivingContext;
  final String ettn;
  final String despatchNumber;
  final DateTime? issueDate;
  final DateTime? actualDespatchDate;
  final String profileId;
  final String despatchAdviceTypeCode;
  final List<String> notes;
  final CompanyAcceptanceEDespatchParty sender;
  final CompanyAcceptanceEDespatchParty receiver;
  final CompanyAcceptanceCustomerSuggestion? primaryCustomerSuggestion;
  final int totalLineCount;
  final int matchedLineCount;
  final int unmatchedLineCount;
  final List<CompanyAcceptanceCustomerSuggestion> suggestedCustomers;
  final List<CompanyAcceptanceEDespatchLine> lines;

  factory CompanyAcceptanceEDespatchPrefill.fromJson(JsonMap json) {
    final primaryCustomerSuggestionJson = json['primaryCustomerSuggestion'];

    return CompanyAcceptanceEDespatchPrefill(
      isFound: _readBool(json['isFound']),
      warehouseNo: _readInt(json['warehouseNo']),
      receivingContext: _readString(json['receivingContext']),
      ettn: _readString(json['ettn']),
      despatchNumber: _readString(json['despatchNumber']),
      issueDate: _readDate(json['issueDate']),
      actualDespatchDate: _readDate(json['actualDespatchDate']),
      profileId: _readString(json['profileId']),
      despatchAdviceTypeCode: _readString(json['despatchAdviceTypeCode']),
      notes: _readStringList(json['notes']),
      sender: CompanyAcceptanceEDespatchParty.fromJson(
        json['sender'] as JsonMap? ?? <String, dynamic>{},
      ),
      receiver: CompanyAcceptanceEDespatchParty.fromJson(
        json['receiver'] as JsonMap? ?? <String, dynamic>{},
      ),
      primaryCustomerSuggestion: primaryCustomerSuggestionJson is JsonMap
          ? CompanyAcceptanceCustomerSuggestion.fromJson(
              primaryCustomerSuggestionJson,
            )
          : null,
      totalLineCount: _readInt(json['totalLineCount']),
      matchedLineCount: _readInt(json['matchedLineCount']),
      unmatchedLineCount: _readInt(json['unmatchedLineCount']),
      suggestedCustomers:
          (json['suggestedCustomers'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => CompanyAcceptanceCustomerSuggestion.fromJson(
                  item as JsonMap? ?? <String, dynamic>{},
                ),
              )
              .toList(growable: false),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CompanyAcceptanceEDespatchLine.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class CompanyAcceptanceEDespatchParty {
  const CompanyAcceptanceEDespatchParty({
    required this.title,
    required this.taxNoOrTckn,
    required this.alias,
    required this.city,
  });

  final String title;
  final String taxNoOrTckn;
  final String alias;
  final String city;

  factory CompanyAcceptanceEDespatchParty.fromJson(JsonMap json) {
    return CompanyAcceptanceEDespatchParty(
      title: _readString(json['title']),
      taxNoOrTckn: _readString(json['taxNoOrTckn']),
      alias: _readString(json['alias']),
      city: _readString(json['city']),
    );
  }
}

class CompanyAcceptanceCustomerSuggestion {
  const CompanyAcceptanceCustomerSuggestion({
    required this.customerCode,
    required this.customerName,
    required this.taxNoOrTckn,
    required this.matchReason,
    required this.isPrimarySuggestion,
  });

  final String customerCode;
  final String customerName;
  final String taxNoOrTckn;
  final String matchReason;
  final bool isPrimarySuggestion;

  String get displayLabel {
    final normalizedName = customerName.trim();
    if (normalizedName.isEmpty) {
      return customerCode;
    }

    return '$customerCode - $normalizedName';
  }

  factory CompanyAcceptanceCustomerSuggestion.fromJson(JsonMap json) {
    return CompanyAcceptanceCustomerSuggestion(
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      taxNoOrTckn: _readString(json['taxNoOrTckn']),
      matchReason: _readString(json['matchReason']),
      isPrimarySuggestion: _readBool(json['isPrimarySuggestion']),
    );
  }
}

class CompanyAcceptanceEDespatchLine {
  const CompanyAcceptanceEDespatchLine({
    required this.lineNo,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitCode,
    required this.buyerItemCode,
    required this.sellerItemCode,
    required this.manufacturerItemCode,
    required this.barcode,
    required this.internalStockCode,
    required this.internalStockName,
    required this.matchReason,
    required this.isMatched,
    required this.isGoodsAcceptanceBlocked,
    required this.canUseForGoodsAcceptance,
  });

  final int lineNo;
  final String productName;
  final String description;
  final double quantity;
  final String unitCode;
  final String buyerItemCode;
  final String sellerItemCode;
  final String manufacturerItemCode;
  final String barcode;
  final String internalStockCode;
  final String internalStockName;
  final String matchReason;
  final bool isMatched;
  final bool isGoodsAcceptanceBlocked;
  final bool canUseForGoodsAcceptance;

  bool get hasUsableInternalStock =>
      canUseForGoodsAcceptance && internalStockCode.trim().isNotEmpty;

  String get externalDisplayLabel {
    final code = buyerItemCode.trim().isNotEmpty
        ? buyerItemCode
        : sellerItemCode.trim().isNotEmpty
        ? sellerItemCode
        : barcode;

    final normalizedProductName = productName.trim();
    if (code.trim().isEmpty) {
      return normalizedProductName;
    }

    if (normalizedProductName.isEmpty) {
      return code;
    }

    return '$code - $normalizedProductName';
  }

  factory CompanyAcceptanceEDespatchLine.fromJson(JsonMap json) {
    return CompanyAcceptanceEDespatchLine(
      lineNo: _readInt(json['lineNo']),
      productName: _readString(json['productName']),
      description: _readString(json['description']),
      quantity: _readDouble(json['quantity']),
      unitCode: _readString(json['unitCode']),
      buyerItemCode: _readString(json['buyerItemCode']),
      sellerItemCode: _readString(json['sellerItemCode']),
      manufacturerItemCode: _readString(json['manufacturerItemCode']),
      barcode: _readString(json['barcode']),
      internalStockCode: _readString(json['internalStockCode']),
      internalStockName: _readString(json['internalStockName']),
      matchReason: _readString(json['matchReason']),
      isMatched: _readBool(json['isMatched']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
      canUseForGoodsAcceptance: _readBool(json['canUseForGoodsAcceptance']),
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
    required this.dispatchQuantity,
    required this.physicalAcceptedQuantity,
    required this.returnQuantity,
    required this.returnStatus,
    required this.returnMovementGuid,
    required this.returnDocumentSerie,
    required this.returnDocumentOrderNo,
    required this.returnEDespatchStatus,
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
  final double dispatchQuantity;
  final double physicalAcceptedQuantity;
  final double returnQuantity;
  final String returnStatus;
  final String? returnMovementGuid;
  final String? returnDocumentSerie;
  final int? returnDocumentOrderNo;
  final String returnEDespatchStatus;

  String? get returnDocumentNoLabel {
    final serie = returnDocumentSerie?.trim() ?? '';
    final orderNo = returnDocumentOrderNo;
    if (serie.isEmpty || orderNo == null || returnQuantity <= 0) {
      return null;
    }

    return '$serie.$orderNo';
  }

  factory CompanyAcceptanceCreateLineResult.fromJson(JsonMap json) {
    final requestedQuantity = _readDouble(json['requestedQuantity']);
    final acceptedQuantity = _readDouble(json['acceptedQuantity']);
    final dispatchQuantity =
        _readNullableDouble(json['dispatchQuantity']) ?? requestedQuantity;
    final physicalAcceptedQuantity =
        _readNullableDouble(json['physicalAcceptedQuantity']) ??
        acceptedQuantity;

    return CompanyAcceptanceCreateLineResult(
      movementGuid: _readString(json['movementGuid']),
      sourceLineNo: _readInt(json['sourceLineNo']),
      movementLineNo: _readInt(json['movementLineNo']),
      stockCode: _readString(json['stockCode']),
      orderGuid: _readString(json['orderGuid']),
      isOrderLinked: _readBool(json['isOrderLinked']),
      receivingMode: _readString(json['receivingMode']),
      requestedQuantity: requestedQuantity,
      acceptedQuantity: acceptedQuantity,
      orderLinkedQuantity: _readDouble(json['orderLinkedQuantity']),
      orderlessQuantity: _readDouble(json['orderlessQuantity']),
      orderRemainingBefore: _readDouble(json['orderRemainingBefore']),
      orderRemainingAfter: _readDouble(json['orderRemainingAfter']),
      dispatchQuantity: dispatchQuantity,
      physicalAcceptedQuantity: physicalAcceptedQuantity,
      returnQuantity: _readDouble(json['returnQuantity']),
      returnStatus: _readString(json['returnStatus']).trim().isEmpty
          ? 'Yok'
          : _readString(json['returnStatus']),
      returnMovementGuid: _readNullableString(json['returnMovementGuid']),
      returnDocumentSerie: _readNullableString(json['returnDocumentSerie']),
      returnDocumentOrderNo: _readNullableInt(json['returnDocumentOrderNo']),
      returnEDespatchStatus:
          _readString(json['returnEDespatchStatus']).trim().isEmpty
          ? 'Yok'
          : _readString(json['returnEDespatchStatus']),
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

List<String> _readStringList(Object? value) {
  if (value is! List) {
    final singleValue = _readString(value).trim();
    return singleValue.isEmpty ? const <String>[] : <String>[singleValue];
  }

  return value
      .map((item) => _readString(item).trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
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

String? _readNullableString(Object? value) {
  final raw = _readString(value).trim();
  return raw.isEmpty ? null : raw;
}
