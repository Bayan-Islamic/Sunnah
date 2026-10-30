import '../../../core/database/database_helper.dart';
import '../../../core/models/book.dart';

/// Read access to the bundled collections.
class BooksRepository {
  BooksRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Book>> fetchBooks() => _db.getBooks();
}
