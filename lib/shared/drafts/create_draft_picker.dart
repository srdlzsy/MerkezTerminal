import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CreateDraftLaunch {
  const CreateDraftLaunch.newDraft() : draft = null;

  const CreateDraftLaunch.resume(this.draft);

  final CreateDraft? draft;
}

Future<CreateDraftLaunch?> showCreateDraftPicker({
  required BuildContext context,
  required CreateDraftRepository repository,
  required String moduleKey,
  required String userId,
  required String warehouseNo,
  required String createTitle,
}) async {
  var drafts = await repository.fetchDrafts(
    moduleKey: moduleKey,
    userId: userId,
    warehouseNo: warehouseNo,
  );

  if (!context.mounted) {
    return null;
  }

  if (drafts.isEmpty) {
    return const CreateDraftLaunch.newDraft();
  }

  return showModalBottomSheet<CreateDraftLaunch>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TerminalSheetHeader(
                    title: 'Taslaklar',
                    subtitle:
                        'Yarim kalan islemi surdurun veya yeni bir $createTitle acin.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop(const CreateDraftLaunch.newDraft()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni Belge'),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: drafts.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_note_rounded),
                          title: Text(
                            draft.title.isEmpty ? createTitle : draft.title,
                          ),
                          subtitle: Text(
                            'Son kayit ${AppFormatters.dateTime(draft.updatedAt)}',
                          ),
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop(CreateDraftLaunch.resume(draft)),
                          trailing: IconButton(
                            tooltip: 'Taslagi sil',
                            onPressed: () async {
                              await repository.deleteDraft(draft.id);
                              if (!context.mounted) {
                                return;
                              }
                              setSheetState(() {
                                drafts = drafts
                                    .where((item) => item.id != draft.id)
                                    .toList(growable: false);
                              });
                              if (drafts.isEmpty && sheetContext.mounted) {
                                Navigator.of(
                                  sheetContext,
                                ).pop(const CreateDraftLaunch.newDraft());
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
