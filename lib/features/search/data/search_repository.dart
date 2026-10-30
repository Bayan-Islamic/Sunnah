import '../../../core/database/database_helper.dart';
import '../../../core/models/hadith.dart';

/// Full-text search over the normalised Arabic text.
class SearchRepository {
  SearchRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Hadith>> search(
    String query, {
    int? bookId,
    bool authenticOnly = false,
  }) =>
      _db.search(query, bookId: bookId, authenticOnly: authenticOnly);
}
