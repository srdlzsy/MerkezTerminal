import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  test(
    'stores and filters create drafts by module, user and warehouse',
    () async {
      final repository = LocalCreateDraftRepository(
        database: MemoryLocalDatabase(),
      );
      final first = CreateDraft.empty(
        moduleKey: 'company-shipment',
        userId: '7',
        warehouseNo: '50',
        title: 'Yeni Firma Sevki',
      ).copyWith(payload: <String, dynamic>{'documentNo': 'IRS-1'});
      final otherUser = CreateDraft.empty(
        moduleKey: 'company-shipment',
        userId: '8',
        warehouseNo: '50',
        title: 'Yeni Firma Sevki',
      );

      await repository.saveDraft(first);
      await repository.saveDraft(otherUser);

      final drafts = await repository.fetchDrafts(
        moduleKey: 'company-shipment',
        userId: '7',
        warehouseNo: '50',
      );

      expect(drafts, hasLength(1));
      expect(drafts.single.payload['documentNo'], 'IRS-1');
    },
  );

  test('updates an existing draft and deletes it', () async {
    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    final draft = CreateDraft.empty(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
      title: 'Yeni Iade',
    );

    await repository.saveDraft(draft);
    await repository.saveDraft(
      draft.copyWith(payload: <String, dynamic>{'description': 'Bekliyor'}),
    );

    var drafts = await repository.fetchDrafts(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
    );
    expect(drafts, hasLength(1));
    expect(drafts.single.payload['description'], 'Bekliyor');

    await repository.deleteDraft(draft.id);
    drafts = await repository.fetchDrafts(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
    );
    expect(drafts, isEmpty);
  });

  test('keeps only the newest five drafts for each scope', () async {
    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    final now = DateTime.now();

    for (var index = 0; index < 7; index += 1) {
      final draft = CreateDraft.empty(
        moduleKey: 'company-return',
        userId: '7',
        warehouseNo: '50',
        title: 'Form $index',
      ).copyWith(updatedAt: now.subtract(Duration(minutes: index)));
      await repository.saveDraft(draft);
    }

    final drafts = await repository.fetchDrafts(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
    );

    expect(drafts, hasLength(5));
    expect(drafts.map((draft) => draft.title), <String>[
      'Form 0',
      'Form 1',
      'Form 2',
      'Form 3',
      'Form 4',
    ]);
  });

  test('removes drafts older than thirty days', () async {
    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    final expiredDraft = CreateDraft.empty(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
      title: 'Eski Form',
    ).copyWith(updatedAt: DateTime.now().subtract(const Duration(days: 31)));

    await repository.saveDraft(expiredDraft);

    final drafts = await repository.fetchDrafts(
      moduleKey: 'company-return',
      userId: '7',
      warehouseNo: '50',
    );
    expect(drafts, isEmpty);
  });

  test(
    'deleteDrafts clears only the selected module user and warehouse',
    () async {
      final repository = LocalCreateDraftRepository(
        database: MemoryLocalDatabase(),
      );
      final selectedScope = CreateDraft.empty(
        moduleKey: 'company-return',
        userId: '7',
        warehouseNo: '50',
        title: 'Silinecek',
      );
      final otherWarehouse = CreateDraft.empty(
        moduleKey: 'company-return',
        userId: '7',
        warehouseNo: '56',
        title: 'Kalacak',
      );
      await repository.saveDraft(selectedScope);
      await repository.saveDraft(otherWarehouse);

      await repository.deleteDrafts(
        moduleKey: 'company-return',
        userId: '7',
        warehouseNo: '50',
      );

      expect(
        await repository.fetchDrafts(
          moduleKey: 'company-return',
          userId: '7',
          warehouseNo: '50',
        ),
        isEmpty,
      );
      expect(
        await repository.fetchDrafts(
          moduleKey: 'company-return',
          userId: '7',
          warehouseNo: '56',
        ),
        hasLength(1),
      );
    },
  );
}
