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

  const draftLimit = LocalCreateDraftRepository.maxDraftsPerScope;
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
                    title: drafts.length == 1
                        ? 'Yarim Kalan Form Bulundu'
                        : 'Yarim Kalan Formlar',
                    subtitle:
                        'Bunlar sunucuya gonderilmis evraklar degildir. '
                        'Yalnizca bu cihazda yarim kalan girislerdir.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  const TerminalMessageBlock.info(
                    message:
                        'Mevcut forma devam edebilir veya onu silmeden yeni '
                        'bir form baslatabilirsiniz.',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${drafts.length}/$draftLimit yarim form',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: drafts.length < draftLimit
                        ? () => Navigator.of(
                            sheetContext,
                          ).pop(const CreateDraftLaunch.newDraft())
                        : null,
                    icon: const Icon(Icons.note_add_rounded),
                    label: const Text('Yeni Form Olustur'),
                  ),
                  if (drafts.length >= draftLimit) ...<Widget>[
                    const SizedBox(height: 8),
                    const TerminalMessageBlock.info(
                      message:
                          '5/5 sinirina ulasildi. Yeni form icin bir yarim '
                          'formu tamamlayin veya silin.',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: drafts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final summary = _draftSummary(draft);
                        return Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.edit_note_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      draft.title.isEmpty
                                          ? createTitle
                                          : draft.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Yarim kalan formu sil',
                                    onPressed: () async {
                                      await repository.deleteDraft(draft.id);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      setSheetState(() {
                                        drafts = drafts
                                            .where(
                                              (item) => item.id != draft.id,
                                            )
                                            .toList(growable: false);
                                      });
                                      if (drafts.isEmpty &&
                                          sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop(
                                          const CreateDraftLaunch.newDraft(),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              if (summary.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  summary,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                'Son degisiklik: '
                                '${AppFormatters.dateTime(draft.updatedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => Navigator.of(
                                    sheetContext,
                                  ).pop(CreateDraftLaunch.resume(draft)),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Devam Et'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
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
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Tumunu Sil ve Yeni Basla'),
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

String _draftSummary(CreateDraft draft) {
  final payload = draft.payload;
  final parts = <String>[];
  final warehouse = _firstMap(payload, const <String>[
    'selectedWarehouse',
    'selectedTargetWarehouse',
  ]);
  if (warehouse != null) {
    final warehouseNo = warehouse['warehouseNo']?.toString().trim() ?? '';
    final warehouseName = warehouse['warehouseName']?.toString().trim() ?? '';
    final value = <String>[
      warehouseNo,
      warehouseName,
    ].where((item) => item.isNotEmpty).join(' - ');
    if (value.isNotEmpty) {
      parts.add('Depo: $value');
    }
  }

  final customer = _firstMap(payload, const <String>['selectedCustomer']);
  if (customer != null) {
    final customerCode = customer['customerCode']?.toString().trim() ?? '';
    final customerName =
        <Object?>[
              customer['customerDisplayName'],
              customer['customerName'],
              customer['customerTitle'],
            ]
            .map((item) => item?.toString().trim() ?? '')
            .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final value = <String>[
      customerCode,
      customerName,
    ].where((item) => item.isNotEmpty).join(' - ');
    if (value.isNotEmpty) {
      parts.add('Cari: $value');
    }
  }

  final lineCount = _draftLineCount(payload);
  if (lineCount > 0) {
    parts.add('$lineCount kalem');
  }
  return parts.join(' | ');
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> payload,
  List<String> keys,
) {
  for (final key in keys) {
    final value = payload[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
  }
  return null;
}

int _draftLineCount(Map<String, dynamic> payload) {
  var count = 0;
  for (final key in const <String>[
    'lines',
    'manualLines',
    'linkedLines',
    'items',
  ]) {
    final value = payload[key];
    if (value is List) {
      count += value.length;
    }
  }
  return count;
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
