import 'package:furpa_merkez_terminal/core/storage/local_json_database.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/models/offline_inventory_count_models.dart';

abstract class OfflineInventoryCountsRepository {
  Future<List<OfflineInventoryCountDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  });
  Future<OfflineInventoryCountDraft?> findDraft(String id);
  Future<void> saveDraft(OfflineInventoryCountDraft draft);
  Future<void> deleteDraft(String id);
}

class SharedPrefsOfflineInventoryCountsRepository
    implements OfflineInventoryCountsRepository {
  SharedPrefsOfflineInventoryCountsRepository({LocalJsonDatabase? database})
    : _database = database ?? LocalJsonDatabase();

  static const String _storageKey = 'offline_inventory_count_drafts_v1';
  final LocalJsonDatabase _database;

  @override
  Future<List<OfflineInventoryCountDraft>> fetchDrafts({
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
  Future<OfflineInventoryCountDraft?> findDraft(String id) async {
    final drafts = await _readAllDrafts();
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }

  @override
  Future<void> saveDraft(OfflineInventoryCountDraft draft) async {
    final drafts = await _readAllDrafts();
    final updated = <OfflineInventoryCountDraft>[
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

  Future<List<OfflineInventoryCountDraft>> _readAllDrafts() async {
    final rows = await _database.readTable(_storageKey);
    return rows
        .map(OfflineInventoryCountDraft.fromJson)
        .toList(growable: false);
  }
}
