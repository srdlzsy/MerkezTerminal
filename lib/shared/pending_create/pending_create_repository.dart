import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';

class PendingCreateOperation {
  const PendingCreateOperation({
    required this.moduleKey,
    required this.userId,
    required this.warehouseNo,
    required this.payload,
    required this.updatedAt,
    this.failureKind,
    this.retryNotBefore,
    this.draft,
    this.operationCode,
    this.relatedClientRequestId,
    this.errorCode,
    this.correlationId,
    this.errorMessage,
    this.lastCheckedAt,
  });

  final String moduleKey;
  final String userId;
  final String warehouseNo;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final String? failureKind;
  final DateTime? retryNotBefore;
  final CreateDraft? draft;
  final String? operationCode;
  final String? relatedClientRequestId;
  final String? errorCode;
  final String? correlationId;
  final String? errorMessage;
  final DateTime? lastCheckedAt;

  String get scopeKey => '$moduleKey\u0000$userId\u0000$warehouseNo';

  String get clientRequestId =>
      payload['clientRequestId']?.toString().trim() ?? '';

  String get operationKey => '$scopeKey\u0000$clientRequestId';

  PendingCreateOperation copyWith({
    String? failureKind,
    DateTime? retryNotBefore,
    String? operationCode,
    String? relatedClientRequestId,
    String? errorCode,
    String? correlationId,
    String? errorMessage,
    DateTime? lastCheckedAt,
  }) {
    return PendingCreateOperation(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      payload: payload,
      updatedAt: DateTime.now(),
      failureKind: failureKind,
      retryNotBefore: retryNotBefore ?? this.retryNotBefore,
      draft: draft,
      operationCode: operationCode ?? this.operationCode,
      relatedClientRequestId:
          relatedClientRequestId ?? this.relatedClientRequestId,
      errorCode: errorCode ?? this.errorCode,
      correlationId: correlationId ?? this.correlationId,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'moduleKey': moduleKey,
    'userId': userId,
    'warehouseNo': warehouseNo,
    'payload': payload,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (failureKind != null) 'failureKind': failureKind,
    if (retryNotBefore != null)
      'retryNotBefore': retryNotBefore!.toUtc().toIso8601String(),
    if (draft != null) 'draft': draft!.toJson(),
    if (operationCode != null) 'operationCode': operationCode,
    if (relatedClientRequestId != null)
      'relatedClientRequestId': relatedClientRequestId,
    if (errorCode != null) 'errorCode': errorCode,
    if (correlationId != null) 'correlationId': correlationId,
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (lastCheckedAt != null)
      'lastCheckedAt': lastCheckedAt!.toUtc().toIso8601String(),
  };

  factory PendingCreateOperation.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final rawDraft = json['draft'];
    return PendingCreateOperation(
      moduleKey: json['moduleKey']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      warehouseNo: json['warehouseNo']?.toString() ?? '',
      payload: rawPayload is Map
          ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{},
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      failureKind: json['failureKind']?.toString(),
      retryNotBefore: DateTime.tryParse(
        json['retryNotBefore']?.toString() ?? '',
      )?.toLocal(),
      draft: rawDraft is Map
          ? CreateDraft.fromJson(
              rawDraft.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      operationCode: json['operationCode']?.toString(),
      relatedClientRequestId: json['relatedClientRequestId']?.toString(),
      errorCode: json['errorCode']?.toString(),
      correlationId: json['correlationId']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      lastCheckedAt: DateTime.tryParse(
        json['lastCheckedAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

abstract class PendingCreateRepository {
  Future<List<PendingCreateOperation>> readAll({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  });

  Future<PendingCreateOperation?> read({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  });

  Future<void> save(PendingCreateOperation operation);

  Future<void> remove({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    String? clientRequestId,
  });
}

class LocalPendingCreateRepository implements PendingCreateRepository {
  LocalPendingCreateRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  static const String _storageKey = 'pending_create_operations_v1';
  final LocalDatabase _database;

  @override
  Future<PendingCreateOperation?> read({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final operations = await readAll(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
    );
    return operations.isEmpty ? null : operations.first;
  }

  @override
  Future<List<PendingCreateOperation>> readAll({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final expectedScope = _scopeKey(moduleKey, userId, warehouseNo);
    final rows = await _database.readTable(_storageKey);
    final operations =
        rows
            .map(PendingCreateOperation.fromJson)
            .where((operation) => operation.scopeKey == expectedScope)
            .toList(growable: false)
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return operations;
  }

  @override
  Future<void> save(PendingCreateOperation operation) async {
    final rows = await _database.readTable(_storageKey);
    final retained = rows.where((row) {
      final existing = PendingCreateOperation.fromJson(row);
      return existing.operationKey != operation.operationKey;
    });
    await _database.writeTable(_storageKey, <Map<String, dynamic>>[
      ...retained,
      operation.toJson(),
    ]);
  }

  @override
  Future<void> remove({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    String? clientRequestId,
  }) async {
    final expectedScope = _scopeKey(moduleKey, userId, warehouseNo);
    final normalizedClientRequestId = clientRequestId?.trim();
    final rows = await _database.readTable(_storageKey);
    await _database.writeTable(
      _storageKey,
      rows
          .where((row) {
            final existing = PendingCreateOperation.fromJson(row);
            if (existing.scopeKey != expectedScope) {
              return true;
            }
            return normalizedClientRequestId == null ||
                    normalizedClientRequestId.isEmpty
                ? false
                : existing.clientRequestId != normalizedClientRequestId;
          })
          .toList(growable: false),
    );
  }

  static String _scopeKey(
    String moduleKey,
    String userId,
    String warehouseNo,
  ) => '$moduleKey\u0000$userId\u0000$warehouseNo';
}
