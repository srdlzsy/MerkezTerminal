import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

class PendingCreateStatusCard extends StatelessWidget {
  const PendingCreateStatusCard({
    super.key,
    required this.operation,
    required this.failureKind,
    required this.isBusy,
    this.showDetails = true,
  });

  final PendingCreateOperation operation;
  final SafeCreateFailureKind failureKind;
  final bool isBusy;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final needsSupport =
        failureKind == SafeCreateFailureKind.manualReview ||
        failureKind == SafeCreateFailureKind.recheckExisting ||
        failureKind == SafeCreateFailureKind.multipleDocuments ||
        failureKind == SafeCreateFailureKind.statusNotFound;
    final color = needsSupport ? colorScheme.error : colorScheme.tertiary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  needsSupport
                      ? Icons.support_agent_rounded
                      : Icons.sync_problem_rounded,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    needsSupport ? 'Destek gerekli' : 'Bekleyen guvenli kayit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showDetails)
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => showPendingCreateDetailsDialog(
                            context: context,
                            operation: operation,
                            failureKind: failureKind,
                          ),
                    child: const Text('Detay'),
                  ),
              ],
            ),
            Text(
              operation.errorMessage?.trim().isNotEmpty == true
                  ? operation.errorMessage!.trim()
                  : _failureMessage(failureKind),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPendingCreateDetailsDialog({
  required BuildContext context,
  required PendingCreateOperation operation,
  required SafeCreateFailureKind failureKind,
}) {
  final details = _detailsText(operation, failureKind);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Guvenli kayit detayi'),
      content: SingleChildScrollView(child: SelectableText(details)),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: details));
            if (dialogContext.mounted) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('Destek bilgileri kopyalandi.')),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Kopyala'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Kapat'),
        ),
      ],
    ),
  );
}

String _detailsText(
  PendingCreateOperation operation,
  SafeCreateFailureKind failureKind,
) {
  final lines = <String>[
    'Durum: ${safeCreatePendingActionLabel(failureKind)}',
    'Islem: ${operation.operationCode ?? operation.moduleKey}',
    'Depo: ${operation.warehouseNo}',
    'Istek kimligi: ${operation.clientRequestId}',
    if (operation.relatedClientRequestId?.trim().isNotEmpty == true)
      'Iliskili istek: ${operation.relatedClientRequestId}',
    if (operation.errorCode?.trim().isNotEmpty == true)
      'Hata kodu: ${operation.errorCode}',
    if (operation.correlationId?.trim().isNotEmpty == true)
      'Destek kodu: ${operation.correlationId}',
    'Son kontrol: ${_formatDateTime(operation.lastCheckedAt ?? operation.updatedAt)}',
    if (operation.errorMessage?.trim().isNotEmpty == true)
      'Aciklama: ${operation.errorMessage}',
  ];
  return lines.join('\n');
}

String _failureMessage(SafeCreateFailureKind kind) {
  return switch (kind) {
    SafeCreateFailureKind.processing =>
      'Kayit Mikro tarafinda isleniyor. Sonuc otomatik kontrol edilecek.',
    SafeCreateFailureKind.queueBusy =>
      'Onceki islem suruyor. Bildirilen sure dolunca ayni kayitla tekrar deneyin.',
    SafeCreateFailureKind.uncertain =>
      'Kaydin sonucu kesinlesmedi. Bilgiler korunuyor; sonuc otomatik kontrol edilecek.',
    SafeCreateFailureKind.waitAndCheck =>
      'Kayit sonucu kontrol ediliyor. Kullanici islemi gerekmiyor.',
    SafeCreateFailureKind.retrySameRequest =>
      'Belgenin olusmadigi dogrulandi. Saklanan ayni kayit guvenle yeniden gonderilebilir.',
    SafeCreateFailureKind.documentIdentityConflict =>
      'Bu seri ve sira Mikro tarafinda kullaniliyor. Formdaki seri veya sirayi duzeltip yeniden kaydedin.',
    SafeCreateFailureKind.officialDocumentAlreadyReceived =>
      'Bu resmi belge daha once teslim alinmis. Ikinci evrak olusturmayin; listeyi yenileyin.',
    SafeCreateFailureKind.recheckExisting =>
      'Mikro kaydini salt-okuma olarak yeniden dogrulayin; yeni evrak gondermeyin.',
    SafeCreateFailureKind.payloadChanged =>
      'Saklanan istek ile gonderilen bilgiler uyusmuyor. Destek incelemesi gerekir.',
    SafeCreateFailureKind.multipleDocuments =>
      'Ayni kayit iziyle birden fazla evrak bulundu. Tekrar gondermeyin.',
    SafeCreateFailureKind.manualReview =>
      'Evrak icerigi eslesmedi. Tekrar gondermeden destek birimine bildirin.',
    SafeCreateFailureKind.statusNotFound =>
      'Sunucuda bu kaydin durum izi bulunamadi. Yeni kimlik uretmeyin.',
    SafeCreateFailureKind.notRetryable =>
      'Kayit tekrar gonderilemez. Hata detayini kontrol edin.',
    SafeCreateFailureKind.cancelled =>
      'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
