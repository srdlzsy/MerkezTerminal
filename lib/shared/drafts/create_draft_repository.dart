import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';

abstract class CreateDraftRepository {
  Future<List<CreateDraft>> fetchDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  });

  Future<void> saveDraft(CreateDraft draft);

  Future<void> deleteDraft(String id);

  Future<void> deleteDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  });
}

class LocalCreateDraftRepository implements CreateDraftRepository {
  LocalCreateDraftRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  static const String _storageKey = 'create_form_drafts_v1';
  static const int maxDraftsPerScope = 5;
  static const Duration draftRetention = Duration(days: 30);

  final LocalDatabase _database;

  @override
  Future<List<CreateDraft>> fetchDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final drafts = await _readAndPruneDrafts();
    return drafts
        .where(
          (draft) =>
              draft.moduleKey == moduleKey &&
              draft.userId == userId &&
              draft.warehouseNo == warehouseNo,
        )
        .toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  @override
  Future<void> saveDraft(CreateDraft draft) async {
    final drafts = await _readAllDrafts();
    final updatedDrafts = _pruneDrafts(<CreateDraft>[
      draft,
      ...drafts.where((item) => item.id != draft.id),
    ]);
    await _database.writeTable(
      _storageKey,
      updatedDrafts.map((item) => item.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> deleteDraft(String id) async {
    final drafts = await _readAllDrafts();
    await _database.writeTable(
      _storageKey,
      drafts
          .where((item) => item.id != id)
          .map((item) => item.toJson())
          .toList(growable: false),
    );
  }

  @override
  Future<void> deleteDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final drafts = await _readAllDrafts();
    await _database.writeTable(
      _storageKey,
      drafts
          .where(
            (draft) =>
                draft.moduleKey != moduleKey ||
                draft.userId != userId ||
                draft.warehouseNo != warehouseNo,
          )
          .map((item) => item.toJson())
          .toList(growable: false),
    );
  }

  Future<List<CreateDraft>> _readAndPruneDrafts() async {
    final drafts = await _readAllDrafts();
    final prunedDrafts = _pruneDrafts(drafts);
    if (prunedDrafts.length != drafts.length) {
      await _database.writeTable(
        _storageKey,
        prunedDrafts.map((item) => item.toJson()).toList(growable: false),
      );
    }
    return prunedDrafts;
  }

  List<CreateDraft> _pruneDrafts(List<CreateDraft> drafts) {
    final expiryDate = DateTime.now().subtract(draftRetention);
    final activeDrafts =
        drafts
            .where((draft) => !draft.updatedAt.isBefore(expiryDate))
            .toList(growable: false)
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final scopeCounts = <String, int>{};

    return activeDrafts
        .where((draft) {
          final scopeKey =
              '${draft.moduleKey}\u0000${draft.userId}\u0000${draft.warehouseNo}';
          final count = scopeCounts[scopeKey] ?? 0;
          if (count >= maxDraftsPerScope) {
            return false;
          }
          scopeCounts[scopeKey] = count + 1;
          return true;
        })
        .toList(growable: false);
  }

  Future<List<CreateDraft>> _readAllDrafts() async {
    final rows = await _database.readTable(_storageKey);
    return rows
        .map(CreateDraft.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}
