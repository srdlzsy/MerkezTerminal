import 'package:flutter/foundation.dart';

mixin SafeChangeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  @protected
  void notifySafely() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
