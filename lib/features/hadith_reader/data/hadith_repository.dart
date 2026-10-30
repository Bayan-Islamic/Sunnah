import '../../../core/database/database_helper.dart';
import '../../../core/database/hadith_query.dart';
import '../../../core/models/hadith.dart';

/// Read access to hadith records.
class HadithRepository {
  HadithRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Hadith>> fetchHadiths({
    int? bookId,
    int? chapterId,
    bool authenticOnly = false,
  }) =>
      _db.getHadiths(
        HadithQuery(
          bookId: bookId,
          chapterId: chapterId,
          authenticOnly: authenticOnly,
        ),
      );

  Future<List<Hadith>> fetchByIds(List<int> ids) => _db.getHadithsByIds(ids);

  Future<int> countInBook(int bookId, {bool authenticOnly = false}) =>
      _db.countHadiths(bookId, authenticOnly: authenticOnly);
}
