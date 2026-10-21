import 'package:flutter/foundation.dart';

Future<void> refreshAfterSuccessfulCreate(
  Future<void> Function() refresh,
) async {
  try {
    await refresh();
  } on Object catch (error, stackTrace) {
    debugPrint('Create succeeded but list refresh failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
