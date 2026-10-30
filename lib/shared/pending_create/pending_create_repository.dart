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
    this.completedAt,
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
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

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
    DateTime? completedAt,
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
      completedAt: completedAt ?? this.completedAt,
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
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
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
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
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

  Future<void> complete({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    required String clientRequestId,
  });

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
  static const Duration _completionRetention = Duration(days: 7);
  static const Duration _pendingRetention = Duration(days: 30);
  static const int _maxCompletedPerScope = 50;
  static const Set<String> _closedFailureKinds = <String>{
    'notRetryable',
    'documentIdentityConflict',
    'officialDocumentAlreadyReceived',
    'payloadChanged',
    'multipleDocuments',
    'manualReview',
    'recheckExisting',
    'statusNotFound',
    'cancelled',
  };
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
    if (operations.isEmpty) return null;

    // Reconcile records fairly without polling all of them at once. A record
    // checked on the previous page opening moves behind records that have not
    // been checked yet.
    return operations.reduce((left, right) {
      final leftCheck = left.lastCheckedAt ?? left.updatedAt;
      final rightCheck = right.lastCheckedAt ?? right.updatedAt;
      return leftCheck.isBefore(rightCheck) ? left : right;
    });
  }

  @override
  Future<List<PendingCreateOperation>> readAll({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final expectedScope = _scopeKey(moduleKey, userId, warehouseNo);
    final rows = await _database.readTable(_storageKey);
    final storedOperations = rows
        .map(PendingCreateOperation.fromJson)
        .toList(growable: false);
    final retainedOperations = _pruneStored(storedOperations);
    if (retainedOperations.length != storedOperations.length) {
      await _mutateRows(
        (currentRows) => _pruneStored(
          currentRows.map(PendingCreateOperation.fromJson).toList(),
        ).map((item) => item.toJson()).toList(growable: false),
      );
    }
    final operations =
        retainedOperations
            .where(
              (operation) =>
                  operation.scopeKey == expectedScope && !operation.isCompleted,
            )
            .toList(growable: false)
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return operations;
  }

  @override
  Future<void> save(PendingCreateOperation operation) async {
    await _mutateRows((rows) {
      final operations = _pruneCompleted(rows);
      final alreadyCompleted = operations.any(
        (existing) =>
            existing.operationKey == operation.operationKey &&
            existing.isCompleted,
      );
      if (alreadyCompleted) {
        return operations.map((item) => item.toJson()).toList(growable: false);
      }
      return <Map<String, dynamic>>[
        ...operations
            .where(
              (existing) => existing.operationKey != operation.operationKey,
            )
            .map((item) => item.toJson()),
        operation.toJson(),
      ];
    });
  }

  @override
  Future<void> complete({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    required String clientRequestId,
  }) async {
    final normalizedClientRequestId = clientRequestId.trim();
    if (normalizedClientRequestId.isEmpty) {
      return;
    }
    final completed = PendingCreateOperation(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      payload: <String, dynamic>{'clientRequestId': normalizedClientRequestId},
      updatedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
    await _mutateRows((rows) {
      final operations = _pruneCompleted(rows);
      return <Map<String, dynamic>>[
        ...operations
            .where(
              (existing) => existing.operationKey != completed.operationKey,
            )
            .map((item) => item.toJson()),
        completed.toJson(),
      ];
    });
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
    await _mutateRows((rows) {
      return _pruneCompleted(rows)
          .where((existing) {
            if (existing.scopeKey != expectedScope) {
              return true;
            }
            return normalizedClientRequestId == null ||
                    normalizedClientRequestId.isEmpty
                ? false
                : existing.clientRequestId != normalizedClientRequestId;
          })
          .map((item) => item.toJson())
          .toList(growable: false);
    });
  }

  List<PendingCreateOperation> _pruneCompleted(
    List<Map<String, dynamic>> rows,
  ) => _pruneStored(rows.map(PendingCreateOperation.fromJson).toList());

  List<PendingCreateOperation> _pruneStored(
    List<PendingCreateOperation> operations,
  ) {
    final now = DateTime.now();
    final completionCutoff = now.subtract(_completionRetention);
    final pendingCutoff = now.subtract(_pendingRetention);
    final eligible = operations
        .where(
          (operation) =>
              !_closedFailureKinds.contains(operation.failureKind) &&
              (operation.isCompleted
                  ? !operation.completedAt!.isBefore(completionCutoff)
                  : !operation.updatedAt.isBefore(pendingCutoff)),
        )
        .toList(growable: false);

    final byScope = <String, List<PendingCreateOperation>>{};
    for (final operation in eligible) {
      byScope
          .putIfAbsent(operation.scopeKey, () => <PendingCreateOperation>[])
          .add(operation);
    }

    final retained = <PendingCreateOperation>[];
    for (final scopeOperations in byScope.values) {
      final pending =
          scopeOperations.where((item) => !item.isCompleted).toList()
            ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      final completed =
          scopeOperations.where((item) => item.isCompleted).toList()
            ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      // Unresolved requests carry the immutable body and clientRequestId used
      // to prevent duplicate Mikro documents. Never discard them just because
      // another pending request was created in the same scope.
      retained.addAll(pending);
      retained.addAll(completed.take(_maxCompletedPerScope));
    }

    return retained;
  }

  Future<void> _mutateRows(
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>> rows) mutate,
  ) async {
    final database = _database;
    if (database is AtomicLocalDatabase) {
      await database.mutateTable(_storageKey, mutate);
      return;
    }
    final rows = await database.readTable(_storageKey);
    await database.writeTable(_storageKey, mutate(rows));
  }

  static String _scopeKey(
    String moduleKey,
    String userId,
    String warehouseNo,
  ) => '$moduleKey\u0000$userId\u0000$warehouseNo';
}
