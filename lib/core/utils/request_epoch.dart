class RequestEpoch {
  int _current = 0;

  int next() => ++_current;

  void invalidate() {
    _current++;
  }

  bool isCurrent(int value) => value == _current;
}
