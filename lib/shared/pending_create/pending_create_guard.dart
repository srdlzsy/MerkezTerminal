import 'package:flutter/widgets.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

Future<bool> ensurePendingCreateCapacity({
  required BuildContext context,
  required PendingCreateRepository repository,
  required String moduleKey,
  required String userId,
  required String warehouseNo,
}) async => true;
