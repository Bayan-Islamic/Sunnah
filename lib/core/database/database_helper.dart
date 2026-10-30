import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/hadith.dart';
import '../utils/arabic_normalizer.dart';
import 'hadith_query.dart';

/// Owns the bundled offline SQLite database.
///
/// On a device the pre-populated asset is copied into the databases directory
/// on first launch, so every later read is a plain local query with no network
/// access. Tests inject [databasePath] (and, on the host, the FFI factory) to
/// open the asset database read-only.
class DatabaseHelper {
  DatabaseHelper({DatabaseFactory? databaseFactory, String? databasePath})
      : _factory = databaseFactory,
        _overridePath = databasePath;

  static final DatabaseHelper instance = DatabaseHelper();

  final DatabaseFactory? _factory;
  final String? _overridePath;

  Database? _db;
  Completer<Database>? _opening;

  /// Opens the database, reusing an in-flight open so concurrent callers do
  /// not race to copy the asset.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final pending = _opening;
    if (pending != null) {
      return pending.future;
    }
    final completer = Completer<Database>();
    _opening = completer;
    try {
      final db = await _open();
      _db = db;
      completer.complete(db);
      return db;
    } catch (error, stack) {
      completer.completeError(error, stack);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _overridePath ?? await _resolveDatabasePath();
    final readOnly = _overridePath != null;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        readOnly: readOnly,
        // A version would make sqflite write `PRAGMA user_version`, which the
        // read-only asset connection cannot do. The bundled schema is already
        // final, so no migration hooks are needed.
        version: readOnly ? null : AppConstants.databaseVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  /// Copies the bundled asset to the databases directory when absent.
  Future<String> _resolveDatabasePath() async {
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

  /// All collections, ordered for display.
  Future<List<Book>> getBooks() async {
    final db = await database;
    final rows = await db.query('books', orderBy: 'id ASC');
    return rows.map(Book.fromMap).toList(growable: false);
  }

  /// Chapters of [bookId] with the hadith count under [authenticOnly].
  Future<List<Chapter>> getChapters(
    int bookId, {
    bool authenticOnly = false,
  }) async {
    final db = await database;
    final filter = HadithQuery(bookId: bookId, authenticOnly: authenticOnly);
    final rows = await db.rawQuery(
      'SELECT c.id, c.book_id, c.chapter_number, c.title_ar, c.title_en, '
      'COUNT(h.id) AS hadith_count '
      'FROM chapters c '
      'LEFT JOIN hadiths h ON h.chapter_id = c.id '
      '  AND h.book_id = c.book_id '
      '  ${authenticOnly ? _gradeClause : ''} '
      'WHERE c.book_id = ? '
      'GROUP BY c.id '
      'ORDER BY c.chapter_number ASC',
      <Object?>[
        if (authenticOnly) ...HadithQuery.authenticGrades,
        bookId,
      ],
    );
    // `filter` documents the same constraints; keep the two in step.
    assert(filter.bookId == bookId);
    return rows.map(Chapter.fromMap).toList(growable: false);
  }

  /// Hadiths matching [query].
  Future<List<Hadith>> getHadiths(HadithQuery query) async {
    final db = await database;
    final where = query.whereClause;
    final rows = await db.rawQuery(
      'SELECT h.*, b.name_ar AS book_name_ar, b.name_en AS book_name_en, '
      'c.title_ar AS chapter_title_ar '
      'FROM hadiths h '
      'JOIN books b ON b.id = h.book_id '
      'JOIN chapters c ON c.id = h.chapter_id '
      '${where.isEmpty ? '' : 'WHERE $where'} '
      'ORDER BY h.hadith_number ASC, h.id ASC',
      query.whereArgs,
    );
    return rows.map(Hadith.fromMap).toList(growable: false);
  }

  /// Full-text search over `matn_ar`, optionally scoped to one collection.
  ///
  /// The query is normalised with [ArabicNormalizer] so diacritics and letter
  /// variants are ignored. A query with no searchable content returns nothing.
  Future<List<Hadith>> search(
    String rawQuery, {
    int? bookId,
    bool authenticOnly = false,
  }) async {
    final normalized = ArabicNormalizer.normalizeQuery(rawQuery);
    if (normalized == null) {
      return const <Hadith>[];
    }
    return getHadiths(
      HadithQuery(
        bookId: bookId,
        authenticOnly: authenticOnly,
        normalizedText: normalized,
      ),
    );
  }

  /// Hadiths by primary key, preserving the order of [ids].
  Future<List<Hadith>> getHadithsByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return const <Hadith>[];
    }
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT h.*, b.name_ar AS book_name_ar, b.name_en AS book_name_en, '
      'c.title_ar AS chapter_title_ar '
      'FROM hadiths h '
      'JOIN books b ON b.id = h.book_id '
      'JOIN chapters c ON c.id = h.chapter_id '
      'WHERE h.id IN ($placeholders)',
      ids,
    );
    final byId = <int, Hadith>{
      for (final row in rows) (row['id'] as int): Hadith.fromMap(row),
    };
    return <Hadith>[
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  /// Number of hadiths in a book, respecting [authenticOnly].
  Future<int> countHadiths(int bookId, {bool authenticOnly = false}) async {
    final db = await database;
    final query = HadithQuery(bookId: bookId, authenticOnly: authenticOnly);
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM hadiths h '
      '${query.whereClause.isEmpty ? '' : 'WHERE ${query.whereClause}'}',
      query.whereArgs,
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Total number of rows in `hadiths`.
  Future<int> totalHadithCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM hadiths');
    return (result.first['c'] as int?) ?? 0;
  }

  static String get _gradeClause =>
      'AND h.grade IN (${List.filled(HadithQuery.authenticGrades.length, '?').join(', ')})';

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
