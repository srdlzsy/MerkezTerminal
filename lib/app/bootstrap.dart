import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:furpa_merkez_terminal/app/app.dart';
import 'package:furpa_merkez_terminal/app/dependencies.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = AppDependencies.create();

  runApp(FurpaMerkezApp(dependencies: dependencies));

  unawaited(dependencies.sessionController.restoreSession());
}
