import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';

abstract class OfflineCompanyAcceptancesRepository {
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  });
  Future<OfflineCompanyAcceptanceDraft?> findDraft(String id);
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft);
  Future<void> completeDraft(String id);
  Future<void> deleteDraft(String id);
}

class LocalOfflineCompanyAcceptancesRepository
    implements OfflineCompanyAcceptancesRepository {
  LocalOfflineCompanyAcceptancesRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  static const String _storageKey = 'offline_company_acceptance_drafts_v1';
  static const String _completionStorageKey =
      'offline_company_acceptance_completed_v1';
  static const Duration _completionRetention = Duration(days: 30);
  final LocalDatabase _database;

  @override
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    final drafts = await _readActiveDrafts();
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
    final drafts = await _readActiveDrafts();
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }

  @override
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft) async {
    if ((await _readCompletedIds()).contains(draft.id)) {
      return;
    }
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
  Future<void> completeDraft(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return;
    }
    await _mutateTable(_completionStorageKey, (rows) {
      final cutoff = DateTime.now().subtract(_completionRetention);
      final retained = rows.where((row) {
        final completedAt = DateTime.tryParse(
          row['completedAt']?.toString() ?? '',
        );
        return row['id']?.toString() != normalizedId &&
            completedAt != null &&
            !completedAt.isBefore(cutoff);
      });
      return <Map<String, dynamic>>[
        ...retained,
        <String, dynamic>{
          'id': normalizedId,
          'completedAt': DateTime.now().toUtc().toIso8601String(),
        },
      ];
    });
    await deleteDraft(normalizedId);
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

  Future<List<OfflineCompanyAcceptanceDraft>> _readActiveDrafts() async {
    final completedIds = await _readCompletedIds();
    final drafts = await _readAllDrafts();
    return drafts
        .where((draft) => !completedIds.contains(draft.id))
        .toList(growable: false);
  }

  Future<Set<String>> _readCompletedIds() async {
    final cutoff = DateTime.now().subtract(_completionRetention);
    final rows = await _database.readTable(_completionStorageKey);
    return rows
        .where((row) {
          final completedAt = DateTime.tryParse(
            row['completedAt']?.toString() ?? '',
          );
          return completedAt != null && !completedAt.isBefore(cutoff);
        })
        .map((row) => row['id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _mutateTable(
    String key,
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>> rows) mutate,
  ) async {
    final database = _database;
    if (database is AtomicLocalDatabase) {
      await database.mutateTable(key, mutate);
      return;
    }
    final rows = await database.readTable(key);
    await database.writeTable(key, mutate(rows));
  }
}
