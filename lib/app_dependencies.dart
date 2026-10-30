import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_helper.dart';
import 'core/settings/settings_repository.dart';
import 'features/bookmarks/data/bookmarks_repository.dart';
import 'features/books/data/books_repository.dart';
import 'features/chapters/data/chapters_repository.dart';
import 'features/hadith_reader/data/hadith_repository.dart';
import 'features/search/data/search_repository.dart';

/// Single wiring point for the app's repositories.
///
/// The object is created once in `main` and handed to the widget tree, keeping
/// the feature layers free of global singletons and easy to override in tests.
class AppDependencies {
  AppDependencies({
    required this.database,
    required this.preferences,
  })  : books = BooksRepository(database),
        chapters = ChaptersRepository(database),
        hadiths = HadithRepository(database),
        search = SearchRepository(database),
        bookmarks = BookmarksRepository(preferences),
        settings = SettingsRepository(preferences);

  final DatabaseHelper database;
  final SharedPreferences preferences;

  final BooksRepository books;
  final ChaptersRepository chapters;
  final HadithRepository hadiths;
  final SearchRepository search;
  final BookmarksRepository bookmarks;
  final SettingsRepository settings;
}
