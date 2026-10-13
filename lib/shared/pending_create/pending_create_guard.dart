import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

const int pendingCreateWarningThreshold = 10;
const int pendingCreateCriticalThreshold = 25;
const int maxPendingCreateOperationsPerScope = 50;

enum PendingCreateCapacityLevel { normal, warning, critical, blocked }

PendingCreateCapacityLevel pendingCreateCapacityLevel(int pendingCount) {
  if (pendingCount >= maxPendingCreateOperationsPerScope) {
    return PendingCreateCapacityLevel.blocked;
  }
  if (pendingCount >= pendingCreateCriticalThreshold) {
    return PendingCreateCapacityLevel.critical;
  }
  if (pendingCount >= pendingCreateWarningThreshold) {
    return PendingCreateCapacityLevel.warning;
  }
  return PendingCreateCapacityLevel.normal;
}

Future<bool> ensurePendingCreateCapacity({
  required BuildContext context,
  required PendingCreateRepository repository,
  required String moduleKey,
  required String userId,
  required String warehouseNo,
}) async {
  try {
    final pending = await repository.readAll(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
    );
    final level = pendingCreateCapacityLevel(pending.length);
    if (level == PendingCreateCapacityLevel.normal) return true;
    if (!context.mounted) return false;

    if (level == PendingCreateCapacityLevel.blocked) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yeni kayit durduruldu'),
          content: Text(
            'Bu ekranda ${pending.length} bekleyen guvenli kayit var. '
            'Mevcut kayitlari Tekrar Dene ile sonuclandirin ve destek '
            'birimine bildirin. Uygulama verisini temizlemeyin.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return false;
    }

    final isCritical = level == PendingCreateCapacityLevel.critical;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCritical
              ? 'Bekleyen kayit birikimi yuksek'
              : 'Bekleyen kayitlar var',
        ),
        content: Text(
          'Bu ekranda ${pending.length} bekleyen guvenli kayit var. '
          '${isCritical ? 'Destek birimine bildirmeniz onerilir. ' : ''}'
          'Yine de farkli ve bagimsiz bir evrak olusturabilirsiniz.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yine de Yeni'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  } on Object {
    if (!context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Bekleyen guvenli kayitlar kontrol edilemedi. Yeni kayit acmadan '
          'once destek birimine bildirin.',
        ),
      ),
    );
    return false;
  }
}
