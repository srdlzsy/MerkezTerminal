import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void configureSqliteDatabaseFactory() {
  if (!Platform.isWindows && !Platform.isLinux) {
    return;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
