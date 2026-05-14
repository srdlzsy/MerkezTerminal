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
    required this.documentNo,
    required this.deliverer,
    required this.receiver,
    required this.description,
    required this.allowOrderOverReceiving,
    required this.createdAt,
    required this.status,
    required this.lastSyncAttemptAt,
    required this.lastError,
    required this.lines,
  });

  final String id;
  final String userId;
  final String warehouseNo;
  final String customerCode;
  final String customerDisplayName;
  final DateTime movementDate;
  final DateTime documentDate;
  final String documentNo;
  final String deliverer;
  final String receiver;
  final String description;
  final bool allowOrderOverReceiving;
  final DateTime createdAt;
  final OfflineRecordStatus status;
  final DateTime? lastSyncAttemptAt;
  final String? lastError;
  final List<OfflineCompanyAcceptanceLine> lines;

  String get clientRequestId => id;

  bool matchesContext({required String userId, required String warehouseNo}) {
    return this.userId == userId && this.warehouseNo == warehouseNo;
  }

  CompanyAcceptanceCreateRequest toCreateRequest() {
    return CompanyAcceptanceCreateRequest(
      customerCode: customerCode,
      movementDate: movementDate,
      documentDate: documentDate,
      documentNo: documentNo,
      deliverer: deliverer,
      receiver: receiver,
      description: description,
      allowOrderOverReceiving: allowOrderOverReceiving,
      clientRequestId: clientRequestId,
      lines: lines
          .map(
            (item) => CompanyAcceptanceCreateLine(
              stockCode: item.stockCode,
              quantity: item.quantity,
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
  }) {
    return OfflineCompanyAcceptanceDraft(
      id: id,
      userId: userId,
      warehouseNo: warehouseNo,
      customerCode: customerCode,
      customerDisplayName: customerDisplayName,
      movementDate: movementDate,
      documentDate: documentDate,
      documentNo: documentNo,
      deliverer: deliverer,
      receiver: receiver,
      description: description,
      allowOrderOverReceiving: allowOrderOverReceiving,
      createdAt: createdAt,
      status: status ?? this.status,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      lastError: lastError,
      lines: lines,
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
      'documentNo': documentNo,
      'deliverer': deliverer,
      'receiver': receiver,
      'description': description,
      'allowOrderOverReceiving': allowOrderOverReceiving,
      'createdAt': createdAt.toIso8601String(),
      'status': encodeOfflineRecordStatus(status),
      'lastSyncAttemptAt': lastSyncAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory OfflineCompanyAcceptanceDraft.fromJson(Map<String, dynamic> json) {
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
      documentNo: json['documentNo']?.toString() ?? '',
      deliverer: json['deliverer']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      allowOrderOverReceiving:
          json['allowOrderOverReceiving'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: decodeOfflineRecordStatus(json['status']),
      lastSyncAttemptAt: DateTime.tryParse(
        json['lastSyncAttemptAt']?.toString() ?? '',
      ),
      lastError: json['lastError']?.toString().trim().isEmpty ?? true
          ? null
          : json['lastError']?.toString(),
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
      documentNo: request.documentNo,
      deliverer: request.deliverer,
      receiver: request.receiver,
      description: request.description,
      allowOrderOverReceiving: request.allowOrderOverReceiving,
      createdAt: createdAt,
      status: status,
      lastSyncAttemptAt: lastSyncAttemptAt,
      lastError: lastError,
      lines: request.lines
          .map(
            (item) => OfflineCompanyAcceptanceLine(
              stockCode: item.stockCode,
              stockName: '',
              barcode: '',
              quantity: item.quantity,
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

class OfflineCompanyAcceptanceLine {
  const OfflineCompanyAcceptanceLine({
    required this.stockCode,
    required this.stockName,
    required this.barcode,
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
  final String stockName;
  final String barcode;
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'stockName': stockName,
      'barcode': barcode,
      'quantity': quantity,
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
    return OfflineCompanyAcceptanceLine(
      stockCode: json['stockCode']?.toString() ?? '',
      stockName: json['stockName']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
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
