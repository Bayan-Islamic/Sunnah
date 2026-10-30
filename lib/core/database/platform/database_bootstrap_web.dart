import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../constants/app_constants.dart';

/// Opens the app database on the web.
///
/// `sqflite` has no web implementation, so the FFI web factory is used instead:
/// sqlite3 (wasm) runs in a shared worker over a virtual file system persisted
/// to IndexedDB. The bundled asset bytes are written into that file system on
/// first run, then opened. [overridePath] is ignored because the web factory has
/// no path-based override; the signature keeps the two platforms interchangeable.
Future<Database> openAppDatabase({
  DatabaseFactory? overrideFactory,
  String? overridePath,
}) async {
  final factory = overrideFactory ?? databaseFactoryFfiWeb;
  final path = '/${AppConstants.databaseFileName}';
  if (!await factory.databaseExists(path)) {
    final bytes = await rootBundle.load(AppConstants.databaseAsset);
    await factory.writeDatabaseBytes(
      path,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}
