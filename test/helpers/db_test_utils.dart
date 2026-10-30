import 'dart:io';

import 'package:bayan_sunnah/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the bundled `assets/sunnah.db` on the host through the FFI SQLite
/// engine, so tests exercise the real schema, real seed data and the real
/// queries instead of mocks.
Future<DatabaseHelper> openAssetDatabase() async {
  sqfliteFfiInit();
  final path = File('assets/sunnah.db').absolute.path;
  return DatabaseHelper(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}
