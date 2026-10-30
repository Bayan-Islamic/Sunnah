import 'package:bayan_sunnah/core/constants/hadith_grade.dart';
import 'package:bayan_sunnah/core/database/database_helper.dart';
import 'package:bayan_sunnah/core/database/hadith_query.dart';
import 'package:bayan_sunnah/features/bookmarks/data/bookmarks_repository.dart';
import 'package:bayan_sunnah/features/hadith_reader/data/hadith_repository.dart';
import 'package:bayan_sunnah/features/hadith_reader/presentation/cubit/hadith_reader_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/db_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper db;
  late HadithRepository hadiths;
  late BookmarksRepository bookmarks;

  setUpAll(() async {
    db = await openAssetDatabase();
    hadiths = HadithRepository(db);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    bookmarks = BookmarksRepository(await SharedPreferences.getInstance());
  });

  tearDownAll(() async {
    await db.close();
  });

  /// The collection that carries real da'if entries (Mishkat al-Masabih).
  Future<int> gradedBookId() async {
    final books = await db.getBooks();
    for (final book in books) {
      final all = await db.getHadiths(HadithQuery(bookId: book.id));
      if (all.any((h) => h.grade == HadithGrade.daif)) {
        return book.id;
      }
    }
    fail('expected at least one collection with da\'if hadiths');
  }

  test('loads hadiths and defaults to the authenticity filter', () async {
    final cubit = HadithReaderCubit(hadiths, bookmarks, bookId: 3);
    await cubit.load();
    expect(cubit.state.status, HadithReaderStatus.success);
    expect(cubit.state.hadiths, isNotEmpty);
    expect(cubit.state.authenticOnly, isTrue);
    await cubit.close();
  });

  test('hides da\'if hadiths while the filter is on', () async {
    final bookId = await gradedBookId();
    final cubit = HadithReaderCubit(hadiths, bookmarks, bookId: bookId);

    await cubit.load(authenticOnly: true);
    final filteredIds = cubit.state.hadiths.map((h) => h.id).toSet();
    expect(
      cubit.state.hadiths.every((h) => h.grade.isAuthentic),
      isTrue,
    );

    await cubit.load(authenticOnly: false);
    final allIds = cubit.state.hadiths.map((h) => h.id).toSet();
    expect(
      cubit.state.hadiths.any((h) => h.grade == HadithGrade.daif),
      isTrue,
    );

    // The filtered view is a strict subset of the unfiltered one.
    expect(allIds.length, greaterThan(filteredIds.length));
    expect(allIds.containsAll(filteredIds), isTrue);
    await cubit.close();
  });

  test('setAuthenticOnly reloads with the requested filter', () async {
    final bookId = await gradedBookId();
    final cubit = HadithReaderCubit(hadiths, bookmarks, bookId: bookId);
    await cubit.load(authenticOnly: true);

    await cubit.setAuthenticOnly(false);
    expect(cubit.state.authenticOnly, isFalse);
    expect(cubit.state.hadiths.any((h) => h.grade == HadithGrade.daif), isTrue);

    await cubit.setAuthenticOnly(true);
    expect(cubit.state.authenticOnly, isTrue);
    expect(cubit.state.hadiths.every((h) => h.grade.isAuthentic), isTrue);
    await cubit.close();
  });

  test('scopes to a single chapter', () async {
    final chapters = await db.getChapters(3);
    final chapter = chapters.first;
    final cubit = HadithReaderCubit(
      hadiths,
      bookmarks,
      bookId: 3,
      chapterId: chapter.id,
    );
    await cubit.load();
    expect(cubit.state.hadiths, isNotEmpty);
    expect(cubit.state.hadiths.every((h) => h.chapterId == chapter.id), isTrue);
    await cubit.close();
  });

  test('bookmarking toggles the flag and persists the id', () async {
    final cubit = HadithReaderCubit(hadiths, bookmarks, bookId: 3);
    await cubit.load();
    final target = cubit.state.hadiths.first;
    expect(target.isBookmarked, isFalse);

    await cubit.toggleBookmark(target);
    expect(
      cubit.state.hadiths.firstWhere((h) => h.id == target.id).isBookmarked,
      isTrue,
    );
    expect(bookmarks.load(), contains(target.id));

    await cubit.toggleBookmark(target);
    expect(
      cubit.state.hadiths.firstWhere((h) => h.id == target.id).isBookmarked,
      isFalse,
    );
    expect(bookmarks.load(), isNot(contains(target.id)));
    await cubit.close();
  });

  test('existing bookmarks are reflected on load', () async {
    final seeded = await bookmarks.toggle(7, const []);
    expect(seeded, contains(7));
    final cubit = HadithReaderCubit(hadiths, bookmarks, bookId: 3);
    await cubit.load(authenticOnly: false);
    final match = cubit.state.hadiths.where((h) => h.id == 7);
    if (match.isNotEmpty) {
      expect(match.first.isBookmarked, isTrue);
    }
    await cubit.close();
  });
}
