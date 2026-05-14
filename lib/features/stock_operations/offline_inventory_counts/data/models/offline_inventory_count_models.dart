import 'dart:convert';

import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';

class OfflineInventoryCountDraft {
  const OfflineInventoryCountDraft({
    required this.id,
    required this.userId,
    required this.warehouseNo,
    required this.name,
    required this.documentDate,
    required this.createdAt,
    required this.status,
    required this.lastSyncAttemptAt,
    required this.lastError,
    required this.lines,
  });

  final String id;
  final String userId;
  final String warehouseNo;
  final String name;
  final DateTime documentDate;
  final DateTime createdAt;
  final OfflineRecordStatus status;
  final DateTime? lastSyncAttemptAt;
  final String? lastError;
  final List<OfflineInventoryCountLine> lines;

  String get clientRequestId => id;

  bool matchesContext({required String userId, required String warehouseNo}) {
    return this.userId == userId && this.warehouseNo == warehouseNo;
  }

  InventoryCountCreateRequest toCreateRequest() {
    return InventoryCountCreateRequest(
      clientRequestId: clientRequestId,
      name: name,
      documentDate: documentDate,
      lines: lines
          .map(
            (item) => InventoryCountCreateLine(
              stockCode: item.stockCode,
              quantity: item.quantity,
              barcode: item.barcode,
              unitPointer: item.unitPointer,
            ),
          )
          .toList(growable: false),
    );
  }

  OfflineInventoryCountDraft copyWith({
    OfflineRecordStatus? status,
    DateTime? lastSyncAttemptAt,
    String? lastError,
  }) {
    return OfflineInventoryCountDraft(
      id: id,
      userId: userId,
      warehouseNo: warehouseNo,
      name: name,
      documentDate: documentDate,
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
      'name': name,
      'documentDate': documentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': encodeOfflineRecordStatus(status),
      'lastSyncAttemptAt': lastSyncAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory OfflineInventoryCountDraft.fromJson(Map<String, dynamic> json) {
    return OfflineInventoryCountDraft(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      warehouseNo: json['warehouseNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      documentDate:
          DateTime.tryParse(json['documentDate']?.toString() ?? '') ??
          DateTime.now(),
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
            (item) => OfflineInventoryCountLine.fromJson(
              item as Map<String, dynamic>? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }

  factory OfflineInventoryCountDraft.fromCreateRequest(
    InventoryCountCreateRequest request, {
    required String userId,
    required String warehouseNo,
    required OfflineRecordStatus status,
    required DateTime? lastSyncAttemptAt,
    String? lastError,
  }) {
    final clientRequestId = request.clientRequestId?.trim();
    return OfflineInventoryCountDraft(
      id: clientRequestId == null || clientRequestId.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : clientRequestId,
      userId: userId,
      warehouseNo: warehouseNo,
      name: request.name,
      documentDate: request.documentDate,
      createdAt: DateTime.now(),
      status: status,
      lastSyncAttemptAt: lastSyncAttemptAt,
      lastError: lastError,
      lines: request.lines
          .map(
            (item) => OfflineInventoryCountLine(
              stockCode: item.stockCode,
              stockName: '',
              barcode: item.barcode,
              quantity: item.quantity,
              unitPointer: item.unitPointer,
            ),
          )
          .toList(growable: false),
    );
  }
}

class OfflineInventoryCountLine {
  const OfflineInventoryCountLine({
    required this.stockCode,
    required this.stockName,
    required this.barcode,
    required this.quantity,
    required this.unitPointer,
  });

  final String stockCode;
  final String stockName;
  final String barcode;
  final double quantity;
  final int unitPointer;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'stockName': stockName,
      'barcode': barcode,
      'quantity': quantity,
      'unitPointer': unitPointer,
    };
  }

  factory OfflineInventoryCountLine.fromJson(Map<String, dynamic> json) {
    return OfflineInventoryCountLine(
      stockCode: json['stockCode']?.toString() ?? '',
      stockName: json['stockName']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPointer: int.tryParse(json['unitPointer']?.toString() ?? '') ?? 1,
    );
  }
}

String encodeDrafts(List<OfflineInventoryCountDraft> drafts) {
  return jsonEncode(
    drafts.map((item) => item.toJson()).toList(growable: false),
  );
}

List<OfflineInventoryCountDraft> decodeDrafts(String raw) {
  if (raw.trim().isEmpty) {
    return const <OfflineInventoryCountDraft>[];
  }

  try {
    final decoded = jsonDecode(raw) as List<dynamic>? ?? const <dynamic>[];
    return decoded
        .map(
          (item) => OfflineInventoryCountDraft.fromJson(
            item as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  } on FormatException {
    return const <OfflineInventoryCountDraft>[];
  }
}
