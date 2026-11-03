List<T> oldestEntryFirst<T>(Iterable<T> newestEntryFirst) {
  return newestEntryFirst
      .toList(growable: false)
      .reversed
      .toList(growable: false);
}

List<T> sourceLinesThenOldestManualEntry<T>(
  Iterable<T> visibleLines, {
  required bool Function(T line) isSourceLine,
}) {
  final lines = visibleLines.toList(growable: false);
  final sourceLines = lines.where(isSourceLine);
  final manualLines = lines
      .where((line) => !isSourceLine(line))
      .toList()
      .reversed;
  return <T>[...sourceLines, ...manualLines];
}
