import 'package:furpa_merkez_terminal/core/storage/local_json_database.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';

abstract class OfflineCompanyAcceptancesRepository {
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  });
  Future<OfflineCompanyAcceptanceDraft?> findDraft(String id);
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft);
  Future<void> deleteDraft(String id);
}

class SharedPrefsOfflineCompanyAcceptancesRepository
    implements OfflineCompanyAcceptancesRepository {
  SharedPrefsOfflineCompanyAcceptancesRepository({LocalJsonDatabase? database})
    : _database = database ?? LocalJsonDatabase();

  static const String _storageKey = 'offline_company_acceptance_drafts_v1';
  final LocalJsonDatabase _database;

  @override
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    final drafts = await _readAllDrafts();
    return drafts
        .where(
          (item) =>
              item.matchesContext(userId: userId, warehouseNo: warehouseNo),
        )
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<OfflineCompanyAcceptanceDraft?> findDraft(String id) async {
    final drafts = await _readAllDrafts();
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }

  @override
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft) async {
    final drafts = await _readAllDrafts();
    final updated = <OfflineCompanyAcceptanceDraft>[
      draft,
      ...drafts.where((item) => item.id != draft.id),
    ];
    await _database.writeTable(
      _storageKey,
      updated.map((item) => item.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> deleteDraft(String id) async {
    final drafts = await _readAllDrafts();
    final updated = drafts
        .where((item) => item.id != id)
        .toList(growable: false);
    await _database.writeTable(
      _storageKey,
      updated.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<List<OfflineCompanyAcceptanceDraft>> _readAllDrafts() async {
    final rows = await _database.readTable(_storageKey);
    return rows
        .map(OfflineCompanyAcceptanceDraft.fromJson)
        .toList(growable: false);
  }
}
