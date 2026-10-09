import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets('keeps existing drafts when starting a new form', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    await repository.saveDraft(
      _warehouseOrderDraft(
        title: 'Depo Siparisi - MERKEZ DEPO',
        warehouseNo: 50,
        warehouseName: 'MERKEZ DEPO',
      ),
    );
    await repository.saveDraft(
      _warehouseOrderDraft(
        title: 'Depo Siparisi - MANAV DEPO',
        warehouseNo: 56,
        warehouseName: 'MANAV DEPO',
      ),
    );

    CreateDraftLaunch? result;
    await tester.pumpWidget(
      _DraftPickerTestApp(
        repository: repository,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();

    expect(find.text('2/5 yarim form'), findsOneWidget);
    expect(find.text('Depo: 50 - MERKEZ DEPO | 1 kalem'), findsOneWidget);
    expect(find.text('Depo: 56 - MANAV DEPO | 1 kalem'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Devam Et'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilledButton, 'Yeni Form Olustur'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.draft, isNull);
    expect(
      await repository.fetchDrafts(
        moduleKey: _moduleKey,
        userId: _userId,
        warehouseNo: _warehouseNo,
      ),
      hasLength(2),
    );
  });

  testWidgets('resumes the selected single draft explicitly', (tester) async {
    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    final draft = _warehouseOrderDraft(
      title: 'Depo Siparisi - MERKEZ DEPO',
      warehouseNo: 50,
      warehouseName: 'MERKEZ DEPO',
    );
    await repository.saveDraft(draft);

    CreateDraftLaunch? result;
    await tester.pumpWidget(
      _DraftPickerTestApp(
        repository: repository,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();

    expect(find.text('Yarim Kalan Form Bulundu'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Devam Et'));
    await tester.pumpAndSettle();

    expect(result?.draft?.id, draft.id);
  });

  testWidgets('blocks a sixth draft until one is completed or deleted', (
    tester,
  ) async {
    final repository = LocalCreateDraftRepository(
      database: MemoryLocalDatabase(),
    );
    for (var index = 0; index < 5; index += 1) {
      await repository.saveDraft(
        _warehouseOrderDraft(
          title: 'Form $index',
          warehouseNo: 50 + index,
          warehouseName: 'DEPO $index',
        ),
      );
    }

    await tester.pumpWidget(
      _DraftPickerTestApp(repository: repository, onResult: (_) {}),
    );
    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();

    expect(find.text('5/5 yarim form'), findsOneWidget);
    expect(find.textContaining('5/5 sinirina ulasildi'), findsOneWidget);
    final newFormButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Yeni Form Olustur'),
    );
    expect(newFormButton.onPressed, isNull);
  });
}

const _moduleKey = 'siparis-islemleri.verilen-depo-siparisleri';
const _userId = '7';
const _warehouseNo = '120';

CreateDraft _warehouseOrderDraft({
  required String title,
  required int warehouseNo,
  required String warehouseName,
}) {
  return CreateDraft.empty(
    moduleKey: _moduleKey,
    userId: _userId,
    warehouseNo: _warehouseNo,
    title: title,
  ).copyWith(
    payload: <String, dynamic>{
      'selectedWarehouse': <String, dynamic>{
        'warehouseNo': warehouseNo,
        'warehouseName': warehouseName,
      },
      'lines': <Map<String, dynamic>>[
        <String, dynamic>{'stockCode': 'STK-$warehouseNo'},
      ],
    },
  );
}

class _DraftPickerTestApp extends StatelessWidget {
  const _DraftPickerTestApp({required this.repository, required this.onResult});

  final CreateDraftRepository repository;
  final ValueChanged<CreateDraftLaunch?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              onResult(
                await showCreateDraftPicker(
                  context: context,
                  repository: repository,
                  moduleKey: _moduleKey,
                  userId: _userId,
                  warehouseNo: _warehouseNo,
                  createTitle: 'Yeni Verilen Depo Siparisi',
                ),
              );
            },
            child: const Text('Ac'),
          ),
        ),
      ),
    );
  }
}
