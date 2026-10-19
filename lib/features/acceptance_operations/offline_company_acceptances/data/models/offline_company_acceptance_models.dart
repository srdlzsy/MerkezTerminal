import 'dart:convert';

import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';

class OfflineCompanyAcceptanceDraft {
  const OfflineCompanyAcceptanceDraft({
    required this.id,
    required this.userId,
    required this.warehouseNo,
    required this.customerCode,
    required this.customerDisplayName,
    required this.movementDate,
    required this.documentDate,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.officialDocumentKind,
    required this.officialDocumentNo,
    required this.officialDocumentDate,
    required this.officialDocumentEttn,
    required this.deliverer,
    required this.receiver,
    required this.description,
    required this.allowOrderOverReceiving,
    required this.autoCreateReturnForPartialAcceptance,
    required this.createdAt,
    required this.status,
    required this.lastSyncAttemptAt,
    required this.lastError,
    required this.lines,
    this.hasBeenSubmitted = false,
    this.operationCode,
    this.errorCode,
    this.retryable,
    this.retryAfterSeconds,
    this.retryNotBefore,
    this.correlationId,
    this.relatedClientRequestId,
    this.lastCheckedAt,
    this.statusCheckCount = 0,
    this.recoveryState,
    this.recommendedAction,
  });

  final String id;
  final String userId;
  final String warehouseNo;
  final String customerCode;
  final String customerDisplayName;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentSerie;
  final int documentOrderNo;
  final String? officialDocumentKind;
  final String? officialDocumentNo;
  final DateTime? officialDocumentDate;
  final String? officialDocumentEttn;
  final String deliverer;
  final String receiver;
  final String description;
  final bool allowOrderOverReceiving;
  final bool autoCreateReturnForPartialAcceptance;
  final DateTime createdAt;
  final OfflineRecordStatus status;
  final DateTime? lastSyncAttemptAt;
  final String? lastError;
  final List<OfflineCompanyAcceptanceLine> lines;
  final bool hasBeenSubmitted;
  final String? operationCode;
  final String? errorCode;
  final bool? retryable;
  final int? retryAfterSeconds;
  final DateTime? retryNotBefore;
  final String? correlationId;
  final String? relatedClientRequestId;
  final DateTime? lastCheckedAt;
  final int statusCheckCount;
  final String? recoveryState;
  final String? recommendedAction;

  String get clientRequestId => id;

  String get effectiveClientRequestId {
    final related = relatedClientRequestId?.trim() ?? '';
    return related.isEmpty ? clientRequestId : related;
  }

  String get documentLabel {
    final serie = documentSerie.trim();
    return serie.isEmpty || documentOrderNo <= 0
        ? ''
        : '$serie.$documentOrderNo';
  }

  bool matchesContext({required String userId, required String warehouseNo}) {
    return this.userId == userId && this.warehouseNo == warehouseNo;
  }

  bool matchesDocumentIdentity(CompanyAcceptanceCreateRequest request) {
    final storedEttn = _normalizeDocumentToken(officialDocumentEttn);
    final requestedEttn = _normalizeDocumentToken(request.officialDocumentEttn);
    if (storedEttn.isNotEmpty &&
        requestedEttn.isNotEmpty &&
        storedEttn == requestedEttn) {
      return true;
    }

    final storedSerie = documentSerie.trim().toUpperCase();
    final requestedSerie = request.documentSerie.trim().toUpperCase();
    return storedSerie.isNotEmpty &&
        requestedSerie.isNotEmpty &&
        storedSerie == requestedSerie &&
        documentOrderNo > 0 &&
        documentOrderNo == request.documentOrderNo;
  }

  CompanyAcceptanceCreateRequest toCreateRequest() {
    return CompanyAcceptanceCreateRequest(
      customerCode: customerCode,
      movementDate: movementDate,
      documentDate: documentDate,
      documentSerie: documentSerie,
      documentOrderNo: documentOrderNo,
      officialDocumentKind: officialDocumentKind,
      officialDocumentNo: officialDocumentNo,
      officialDocumentDate: officialDocumentDate,
      officialDocumentEttn: officialDocumentEttn,
      deliverer: deliverer,
      receiver: receiver,
      description: description,
      allowOrderOverReceiving: allowOrderOverReceiving,
      autoCreateReturnForPartialAcceptance:
          autoCreateReturnForPartialAcceptance,
      clientRequestId: effectiveClientRequestId,
      lines: lines
          .map(
            (item) => CompanyAcceptanceCreateLine(
              stockCode: item.stockCode,
              dispatchQuantity: item.dispatchQuantity,
              acceptedQuantity: item.acceptedQuantity,
              unitPrice: item.unitPrice,
              unitPointer: item.unitPointer,
              lastConsumingDate: item.lastConsumingDate,
              orderGuid: item.orderGuid,
              description: item.description,
              partyCode: item.partyCode,
              lotNo: item.lotNo,
              projectCode: item.projectCode,
              customerResponsibilityCenter: item.customerResponsibilityCenter,
              productResponsibilityCenter: item.productResponsibilityCenter,
            ),
          )
          .toList(growable: false),
    );
  }

  OfflineCompanyAcceptanceDraft copyWith({
    OfflineRecordStatus? status,
    DateTime? lastSyncAttemptAt,
    String? lastError,
    bool? hasBeenSubmitted,
    String? operationCode,
    String? errorCode,
    bool? retryable,
    int? retryAfterSeconds,
    DateTime? retryNotBefore,
    String? correlationId,
    String? relatedClientRequestId,
    DateTime? lastCheckedAt,
    int? statusCheckCount,
    String? recoveryState,
    String? recommendedAction,
    bool clearSyncMetadata = false,
  }) {
    return OfflineCompanyAcceptanceDraft(
      id: id,
      userId: userId,
      warehouseNo: warehouseNo,
      customerCode: customerCode,
      customerDisplayName: customerDisplayName,
      movementDate: movementDate,
      documentDate: documentDate,
      documentSerie: documentSerie,
      documentOrderNo: documentOrderNo,
      officialDocumentKind: officialDocumentKind,
      officialDocumentNo: officialDocumentNo,
      officialDocumentDate: officialDocumentDate,
      officialDocumentEttn: officialDocumentEttn,
      deliverer: deliverer,
      receiver: receiver,
      description: description,
      allowOrderOverReceiving: allowOrderOverReceiving,
      autoCreateReturnForPartialAcceptance:
          autoCreateReturnForPartialAcceptance,
      createdAt: createdAt,
      status: status ?? this.status,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      lastError: lastError,
      lines: lines,
      hasBeenSubmitted: hasBeenSubmitted ?? this.hasBeenSubmitted,
      operationCode: clearSyncMetadata
          ? null
          : operationCode ?? this.operationCode,
      errorCode: clearSyncMetadata ? null : errorCode ?? this.errorCode,
      retryable: clearSyncMetadata ? null : retryable ?? this.retryable,
      retryAfterSeconds: clearSyncMetadata
          ? null
          : retryAfterSeconds ?? this.retryAfterSeconds,
      retryNotBefore: clearSyncMetadata
          ? null
          : retryNotBefore ?? this.retryNotBefore,
      correlationId: clearSyncMetadata
          ? null
          : correlationId ?? this.correlationId,
      relatedClientRequestId: clearSyncMetadata
          ? null
          : relatedClientRequestId ?? this.relatedClientRequestId,
      lastCheckedAt: clearSyncMetadata
          ? null
          : lastCheckedAt ?? this.lastCheckedAt,
      statusCheckCount: clearSyncMetadata
          ? 0
          : statusCheckCount ?? this.statusCheckCount,
      recoveryState: clearSyncMetadata
          ? null
          : recoveryState ?? this.recoveryState,
      recommendedAction: clearSyncMetadata
          ? null
          : recommendedAction ?? this.recommendedAction,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'warehouseNo': warehouseNo,
      'customerCode': customerCode,
      'customerDisplayName': customerDisplayName,
      'movementDate': movementDate.toIso8601String(),
      'documentDate': documentDate.toIso8601String(),
      'documentSerie': documentSerie,
      'documentOrderNo': documentOrderNo,
      'officialDocumentKind': officialDocumentKind,
      'officialDocumentNo': officialDocumentNo,
      'officialDocumentDate': officialDocumentDate?.toIso8601String(),
      'officialDocumentEttn': officialDocumentEttn,
      'deliverer': deliverer,
      'receiver': receiver,
      'description': description,
      'allowOrderOverReceiving': allowOrderOverReceiving,
      'autoCreateReturnForPartialAcceptance':
          autoCreateReturnForPartialAcceptance,
      'createdAt': createdAt.toIso8601String(),
      'status': encodeOfflineRecordStatus(status),
      'lastSyncAttemptAt': lastSyncAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'hasBeenSubmitted': hasBeenSubmitted,
      'operationCode': operationCode,
      'errorCode': errorCode,
      'retryable': retryable,
      'retryAfterSeconds': retryAfterSeconds,
      'retryNotBefore': retryNotBefore?.toIso8601String(),
      'correlationId': correlationId,
      'relatedClientRequestId': relatedClientRequestId,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'statusCheckCount': statusCheckCount,
      'recoveryState': recoveryState,
      'recommendedAction': recommendedAction,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory OfflineCompanyAcceptanceDraft.fromJson(Map<String, dynamic> json) {
    final legacyDocumentIdentity = parseCompanyAcceptanceDocumentIdentity(
      json['documentNo']?.toString() ?? '',
    );
    final documentSerie = json['documentSerie']?.toString().trim() ?? '';
    final parsedDocumentOrderNo =
        int.tryParse(json['documentOrderNo']?.toString() ?? '') ?? 0;
    final status = decodeOfflineRecordStatus(json['status']);
    final lastSyncAttemptAt = DateTime.tryParse(
      json['lastSyncAttemptAt']?.toString() ?? '',
    );
    final savedHasBeenSubmitted = json['hasBeenSubmitted'];
    final hasBeenSubmitted = savedHasBeenSubmitted is bool
        ? savedHasBeenSubmitted
        : lastSyncAttemptAt != null ||
              status == OfflineRecordStatus.syncing ||
              status == OfflineRecordStatus.failed;
    return OfflineCompanyAcceptanceDraft(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      warehouseNo: json['warehouseNo']?.toString() ?? '',
      customerCode: json['customerCode']?.toString() ?? '',
      customerDisplayName: json['customerDisplayName']?.toString() ?? '',
      movementDate:
          DateTime.tryParse(json['movementDate']?.toString() ?? '') ??
          DateTime.now(),
      documentDate:
          DateTime.tryParse(json['documentDate']?.toString() ?? '') ??
          DateTime.now(),
      documentSerie: documentSerie.isNotEmpty
          ? documentSerie
          : legacyDocumentIdentity?.serie ?? '',
      documentOrderNo: parsedDocumentOrderNo > 0
          ? parsedDocumentOrderNo
          : legacyDocumentIdentity?.orderNo ?? 0,
      officialDocumentKind: _readNullableString(json['officialDocumentKind']),
      officialDocumentNo: _readNullableString(json['officialDocumentNo']),
      officialDocumentDate: DateTime.tryParse(
        json['officialDocumentDate']?.toString() ?? '',
      ),
      officialDocumentEttn: _readNullableString(json['officialDocumentEttn']),
      deliverer: json['deliverer']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      allowOrderOverReceiving:
          json['allowOrderOverReceiving'] as bool? ?? false,
      autoCreateReturnForPartialAcceptance:
          json['autoCreateReturnForPartialAcceptance'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
      lastSyncAttemptAt: lastSyncAttemptAt,
      lastError: json['lastError']?.toString().trim().isEmpty ?? true
          ? null
          : json['lastError']?.toString(),
      hasBeenSubmitted: hasBeenSubmitted,
      operationCode: _readNullableString(json['operationCode']),
      errorCode: _readNullableString(json['errorCode']),
      retryable: json['retryable'] as bool?,
      retryAfterSeconds: int.tryParse(
        json['retryAfterSeconds']?.toString() ?? '',
      ),
      retryNotBefore: DateTime.tryParse(
        json['retryNotBefore']?.toString() ?? '',
      ),
      correlationId: _readNullableString(json['correlationId']),
      relatedClientRequestId: _readNullableString(
        json['relatedClientRequestId'],
      ),
      lastCheckedAt: DateTime.tryParse(json['lastCheckedAt']?.toString() ?? ''),
      statusCheckCount:
          int.tryParse(json['statusCheckCount']?.toString() ?? '') ?? 0,
      recoveryState: _readNullableString(json['recoveryState']),
      recommendedAction: _readNullableString(json['recommendedAction']),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => OfflineCompanyAcceptanceLine.fromJson(
              item as Map<String, dynamic>? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }

  factory OfflineCompanyAcceptanceDraft.fromCreateRequest(
    CompanyAcceptanceCreateRequest request, {
    required String userId,
    required String warehouseNo,
    required String customerDisplayName,
    required DateTime createdAt,
    required OfflineRecordStatus status,
    required DateTime? lastSyncAttemptAt,
    String? lastError,
    bool hasBeenSubmitted = false,
    String? operationCode,
    String? errorCode,
    bool? retryable,
    int? retryAfterSeconds,
    DateTime? retryNotBefore,
    String? correlationId,
    String? relatedClientRequestId,
    DateTime? lastCheckedAt,
    int statusCheckCount = 0,
    String? recoveryState,
    String? recommendedAction,
  }) {
    final clientRequestId = request.clientRequestId?.trim();
    return OfflineCompanyAcceptanceDraft(
      id: clientRequestId == null || clientRequestId.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : clientRequestId,
      userId: userId,
      warehouseNo: warehouseNo,
      customerCode: request.customerCode,
      customerDisplayName: customerDisplayName,
      movementDate: request.movementDate,
      documentDate: request.documentDate,
      documentSerie: request.documentSerie,
      documentOrderNo: request.documentOrderNo,
      officialDocumentKind: request.officialDocumentKind,
      officialDocumentNo: request.officialDocumentNo,
      officialDocumentDate: request.officialDocumentDate,
      officialDocumentEttn: request.officialDocumentEttn,
      deliverer: request.deliverer,
      receiver: request.receiver,
      description: request.description,
      allowOrderOverReceiving: request.allowOrderOverReceiving,
      autoCreateReturnForPartialAcceptance:
          request.autoCreateReturnForPartialAcceptance,
      createdAt: createdAt,
      status: status,
      lastSyncAttemptAt: lastSyncAttemptAt,
      lastError: lastError,
      hasBeenSubmitted: hasBeenSubmitted,
      operationCode: operationCode,
      errorCode: errorCode,
      retryable: retryable,
      retryAfterSeconds: retryAfterSeconds,
      retryNotBefore: retryNotBefore,
      correlationId: correlationId,
      relatedClientRequestId: relatedClientRequestId,
      lastCheckedAt: lastCheckedAt,
      statusCheckCount: statusCheckCount,
      recoveryState: recoveryState,
      recommendedAction: recommendedAction,
      lines: request.lines
          .map(
            (item) => OfflineCompanyAcceptanceLine(
              stockCode: item.stockCode,
              stockName: '',
              barcode: '',
              dispatchQuantity: item.dispatchQuantity,
              acceptedQuantity: item.acceptedQuantity,
              unitPrice: item.unitPrice,
              unitPointer: item.unitPointer,
              lastConsumingDate: item.lastConsumingDate,
              orderGuid: item.orderGuid,
              description: item.description,
              partyCode: item.partyCode,
              lotNo: item.lotNo,
              projectCode: item.projectCode,
              customerResponsibilityCenter: item.customerResponsibilityCenter,
              productResponsibilityCenter: item.productResponsibilityCenter,
            ),
          )
          .toList(growable: false),
    );
  }
}

String _normalizeDocumentToken(String? value) {
  return (value ?? '').trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]'),
    '',
  );
}

class OfflineCompanyAcceptanceLine {
  const OfflineCompanyAcceptanceLine({
    required this.stockCode,
    required this.stockName,
    required this.barcode,
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
  final String stockName;
  final String barcode;
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

  double get quantity => dispatchQuantity;
  double get returnQuantity {
    final value = dispatchQuantity - acceptedQuantity;
    return value > 0 ? value : 0;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'stockName': stockName,
      'barcode': barcode,
      'dispatchQuantity': dispatchQuantity,
      'acceptedQuantity': acceptedQuantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'lastConsumingDate': lastConsumingDate?.toIso8601String(),
      'orderGuid': orderGuid,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
      'customerResponsibilityCenter': customerResponsibilityCenter,
      'productResponsibilityCenter': productResponsibilityCenter,
    };
  }

  factory OfflineCompanyAcceptanceLine.fromJson(Map<String, dynamic> json) {
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

    return OfflineCompanyAcceptanceLine(
      stockCode: json['stockCode']?.toString() ?? '',
      stockName: json['stockName']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      dispatchQuantity: dispatchQuantity,
      acceptedQuantity: acceptedQuantity,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      unitPointer: int.tryParse(json['unitPointer']?.toString() ?? '') ?? 1,
      lastConsumingDate: DateTime.tryParse(
        json['lastConsumingDate']?.toString() ?? '',
      ),
      orderGuid: json['orderGuid']?.toString(),
      description: json['description']?.toString() ?? '',
      partyCode: json['partyCode']?.toString() ?? '',
      lotNo: int.tryParse(json['lotNo']?.toString() ?? '') ?? 0,
      projectCode: json['projectCode']?.toString() ?? '',
      customerResponsibilityCenter:
          json['customerResponsibilityCenter']?.toString() ?? '',
      productResponsibilityCenter:
          json['productResponsibilityCenter']?.toString() ?? '',
    );
  }
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

String? _readNullableString(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return raw;
}

String encodeOfflineCompanyAcceptanceDrafts(
  List<OfflineCompanyAcceptanceDraft> drafts,
) {
  return jsonEncode(
    drafts.map((item) => item.toJson()).toList(growable: false),
  );
}

List<OfflineCompanyAcceptanceDraft> decodeOfflineCompanyAcceptanceDrafts(
  String raw,
) {
  if (raw.trim().isEmpty) {
    return const <OfflineCompanyAcceptanceDraft>[];
  }

  try {
    final decoded = jsonDecode(raw) as List<dynamic>? ?? const <dynamic>[];
    return decoded
        .map(
          (item) => OfflineCompanyAcceptanceDraft.fromJson(
            item as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  } on FormatException {
    return const <OfflineCompanyAcceptanceDraft>[];
  }
}
