/// Platform-specific database bootstrap.
///
/// `sqflite` ships no web implementation, so how the database is opened and how
/// the bundled asset is materialised differ per platform. Everything else in
/// `DatabaseHelper` stays shared.
library;

export 'database_bootstrap_io.dart'
    if (dart.library.js_interop) 'database_bootstrap_web.dart';
