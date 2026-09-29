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
                    title: 'Yarim Kalan Formlar',
                    subtitle:
                        'Bunlar sunucuya gonderilmis evraklar degildir. '
                        'Yalnizca bu cihazda yarim kalan girislerdir.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  const TerminalMessageBlock.info(
                    message:
                        'Islemi daha once tamamlayip gonderdiyseniz bu formu '
                        'silebilirsiniz. Son 5 form tutulur; 30 gunden eski '
                        'formlar otomatik temizlenir.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      final shouldDelete = await _confirmDeleteAll(
                        context,
                        drafts.length,
                      );
                      if (!shouldDelete) {
                        return;
                      }
                      await repository.deleteDrafts(
                        moduleKey: moduleKey,
                        userId: userId,
                        warehouseNo: warehouseNo,
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(
                          sheetContext,
                        ).pop(const CreateDraftLaunch.newDraft());
                      }
                    },
                    icon: const Icon(Icons.note_add_rounded),
                    label: const Text('Yarim Formlari Sil ve Yeni Basla'),
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
                            'Cihazda yarim kaldi: '
                            '${AppFormatters.dateTime(draft.updatedAt)}\n'
                            'Devam etmek icin satira dokunun.',
                          ),
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop(CreateDraftLaunch.resume(draft)),
                          trailing: IconButton(
                            tooltip: 'Yarim kalan formu sil',
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

Future<bool> _confirmDeleteAll(BuildContext context, int count) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yarim Formlari Temizle'),
          content: Text(
            '$count yarim kalan form bu cihazdan silinecek. '
            'Bu islem sunucudaki evraklari etkilemez.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Temizle'),
            ),
          ],
        ),
      ) ??
      false;
}
