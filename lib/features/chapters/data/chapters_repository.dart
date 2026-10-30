import '../../../core/database/database_helper.dart';
import '../../../core/models/chapter.dart';

/// Read access to a collection's chapters.
class ChaptersRepository {
  ChaptersRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Chapter>> fetchChapters(int bookId, {bool authenticOnly = false}) =>
      _db.getChapters(bookId, authenticOnly: authenticOnly);
}
