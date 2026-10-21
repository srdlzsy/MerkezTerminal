import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/models/offline_inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';

import '../../support/memory_local_database.dart';

void main() {
  test('completed inventory draft cannot be saved or restored again', () async {
    final repository = LocalOfflineInventoryCountsRepository(
      database: MemoryLocalDatabase(),
    );
    final draft = OfflineInventoryCountDraft.fromCreateRequest(
      InventoryCountCreateRequest(
        clientRequestId: 'count-1',
        name: 'Test sayim',
        documentDate: DateTime(2026, 10, 21),
        lines: const <InventoryCountCreateLine>[
          InventoryCountCreateLine(
            stockCode: '000001',
            quantity: 2,
            barcode: '8690000000001',
            unitPointer: 1,
          ),
        ],
      ),
      userId: 'user-1',
      warehouseNo: '110',
      status: OfflineRecordStatus.pending,
      lastSyncAttemptAt: null,
    );

    await repository.saveDraft(draft);
    await repository.completeDraft(draft.id);
    await repository.saveDraft(draft);

    expect(await repository.findDraft(draft.id), isNull);
    expect(
      await repository.fetchDrafts(userId: 'user-1', warehouseNo: '110'),
      isEmpty,
    );
  });
}
