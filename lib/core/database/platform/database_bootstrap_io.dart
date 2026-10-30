import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../constants/app_constants.dart';

/// Opens the app database on IO platforms (Android, iOS, desktop, tests).
///
/// When [overridePath] is given the connection is read-only: an injected path
/// points at the bundled asset, which must stay untouched. A version would make
/// sqflite write `PRAGMA user_version`, which a read-only connection cannot do,
/// and the bundled schema is already final, so it is only set for the writable
/// copy.
Future<Database> openAppDatabase({
  DatabaseFactory? overrideFactory,
  String? overridePath,
}) async {
  final factory = overrideFactory ?? databaseFactory;
  final path = overridePath ?? await _copyAssetToDatabasesDirectory();
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      readOnly: overridePath != null,
      version: overridePath == null ? AppConstants.databaseVersion : null,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

/// Copies the bundled asset into the databases directory on first launch.
///
/// Every later read is a plain local query with no network access.
Future<String> _copyAssetToDatabasesDirectory() async {
  final dir = await getDatabasesPath();
  final target = p.join(dir, AppConstants.databaseFileName);
  if (!await File(target).exists()) {
    await Directory(dir).create(recursive: true);
    final bytes = await rootBundle.load(AppConstants.databaseAsset);
    await File(target).writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }
  return target;
}
