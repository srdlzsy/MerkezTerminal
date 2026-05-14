DateTime defaultFilterEndDate([DateTime? now]) {
  final reference = now ?? DateTime.now();
  return DateTime(reference.year, reference.month, reference.day);
}

DateTime defaultFilterStartDate([DateTime? now]) {
  return defaultFilterEndDate(now);
}
