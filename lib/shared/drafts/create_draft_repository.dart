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
}

class LocalCreateDraftRepository implements CreateDraftRepository {
  LocalCreateDraftRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  static const String _storageKey = 'create_form_drafts_v1';

  final LocalDatabase _database;

  @override
  Future<List<CreateDraft>> fetchDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {
    final drafts = await _readAllDrafts();
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
    await _database.writeTable(
      _storageKey,
      <CreateDraft>[
        draft,
        ...drafts.where((item) => item.id != draft.id),
      ].map((item) => item.toJson()).toList(growable: false),
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

  Future<List<CreateDraft>> _readAllDrafts() async {
    final rows = await _database.readTable(_storageKey);
    return rows
        .map(CreateDraft.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}
