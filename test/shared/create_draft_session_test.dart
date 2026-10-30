import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps one client request id when a draft is reopened', () {
    const savedId = '2a97af50-cc41-49a2-9579-7c02e613906c';
    expect(
      resolveDraftClientRequestId(const <String, dynamic>{
        'clientRequestId': savedId,
      }),
      savedId,
    );
    expect(resolveDraftClientRequestId(const <String, dynamic>{}), isNotEmpty);
  });

  test('failed submit resumes draft persistence', () async {
    final repository = _MemoryDraftRepository();
    var payloadValue = 'ilk';
    final session = CreateDraftSession(
      draft: _draft(),
      repository: repository,
      hasContent: () => true,
      buildPayload: () => <String, dynamic>{'value': payloadValue},
      buildTitle: () => 'Taslak',
    );

    await session.complete();
    session.resumeAfterFailedSubmit();
    payloadValue = 'hata-sonrasi';
    await session.flush();
    session.dispose();

    expect(repository.saved.single.payload['value'], 'hata-sonrasi');
    expect(repository.deletedIds, isEmpty);
  });

  test('closing without save keeps a meaningful draft', () async {
    final repository = _MemoryDraftRepository();
    final session = CreateDraftSession(
      draft: _draft(),
      repository: repository,
      hasContent: () => true,
      buildPayload: () => const <String, dynamic>{'lineCount': 2},
      buildTitle: () => 'Taslak',
    );

    await session.flush();
    session.dispose();

    expect(repository.saved.single.payload['lineCount'], 2);
    expect(repository.deletedIds, isEmpty);
  });
}

CreateDraft _draft() {
  final now = DateTime(2026, 10, 30);
  return CreateDraft(
    id: 'draft-1',
    moduleKey: 'test',
    userId: 'user-1',
    warehouseNo: '157',
    title: 'Taslak',
    createdAt: now,
    updatedAt: now,
    payload: const <String, dynamic>{},
  );
}

class _MemoryDraftRepository implements CreateDraftRepository {
  final List<CreateDraft> saved = <CreateDraft>[];
  final List<String> deletedIds = <String>[];

  @override
  Future<void> deleteDraft(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> deleteDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async {}

  @override
  Future<List<CreateDraft>> fetchDrafts({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) async => saved;

  @override
  Future<void> saveDraft(CreateDraft draft) async {
    saved
      ..clear()
      ..add(draft);
  }
}
