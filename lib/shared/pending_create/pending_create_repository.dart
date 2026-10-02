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
    this.draft,
  });

  final String moduleKey;
  final String userId;
  final String warehouseNo;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final String? failureKind;
  final CreateDraft? draft;

  String get scopeKey => '$moduleKey\u0000$userId\u0000$warehouseNo';

  String get clientRequestId =>
      payload['clientRequestId']?.toString().trim() ?? '';

  String get operationKey => '$scopeKey\u0000$clientRequestId';

  PendingCreateOperation copyWith({String? failureKind}) {
    return PendingCreateOperation(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      payload: payload,
      updatedAt: DateTime.now(),
      failureKind: failureKind,
      draft: draft,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'moduleKey': moduleKey,
    'userId': userId,
    'warehouseNo': warehouseNo,
    'payload': payload,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (failureKind != null) 'failureKind': failureKind,
    if (draft != null) 'draft': draft!.toJson(),
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
      draft: rawDraft is Map
          ? CreateDraft.fromJson(
              rawDraft.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
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
