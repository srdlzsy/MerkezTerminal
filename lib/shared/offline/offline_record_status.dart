enum OfflineRecordStatus { pending, syncing, failed }

String encodeOfflineRecordStatus(OfflineRecordStatus status) {
  return switch (status) {
    OfflineRecordStatus.pending => 'pending',
    OfflineRecordStatus.syncing => 'syncing',
    OfflineRecordStatus.failed => 'failed',
  };
}

OfflineRecordStatus decodeOfflineRecordStatus(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'syncing' => OfflineRecordStatus.syncing,
    'failed' => OfflineRecordStatus.failed,
    _ => OfflineRecordStatus.pending,
  };
}

String offlineRecordStatusLabel(OfflineRecordStatus status) {
  return switch (status) {
    OfflineRecordStatus.pending => 'Bekliyor',
    OfflineRecordStatus.syncing => 'Senkronize Ediliyor',
    OfflineRecordStatus.failed => 'Hata',
  };
}
