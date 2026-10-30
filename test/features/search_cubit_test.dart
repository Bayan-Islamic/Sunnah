import 'package:bayan_sunnah/core/database/database_helper.dart';
import 'package:bayan_sunnah/features/bookmarks/data/bookmarks_repository.dart';
import 'package:bayan_sunnah/features/search/data/search_repository.dart';
import 'package:bayan_sunnah/features/search/presentation/cubit/search_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/db_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper db;
  late SearchCubit cubit;

  setUpAll(() async {
    db = await openAssetDatabase();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    cubit = SearchCubit(
      SearchRepository(db),
      BookmarksRepository(prefs),
    );
  });

  tearDownAll(() async {
    await db.close();
  });

  test('starts in the initial state', () {
    expect(cubit.state.status, SearchStatus.initial);
    expect(cubit.state.results, isEmpty);
  });

  test('finds results for a corpus word', () async {
    await cubit.search('الصلاة');
    expect(cubit.state.status, SearchStatus.success);
    expect(cubit.state.results, isNotEmpty);
  });

  test('normalises the query, matching across diacritics', () async {
    await cubit.search('الأَعْمَال');
    final withDiacritics = cubit.state.results.map((h) => h.id).toSet();
    await cubit.search('الاعمال');
    final plain = cubit.state.results.map((h) => h.id).toSet();
    expect(withDiacritics, plain);
    expect(plain, isNotEmpty);
  });

  test('clears back to the initial state for a blank query', () async {
    await cubit.search('الصلاة');
    await cubit.search('   ');
    expect(cubit.state.status, SearchStatus.initial);
    expect(cubit.state.results, isEmpty);
  });

  test('reports an empty result distinctly from an idle state', () async {
    await cubit.search('ززززززززز');
    expect(cubit.state.isEmptyResult, isTrue);
  });

  test('honours the authenticity filter', () async {
    await cubit.search('الصلاة', authenticOnly: true);
    expect(
      cubit.state.results.every((h) => h.grade.isAuthentic),
      isTrue,
    );
  });

  test('toggleBookmark updates the matching result', () async {
    await cubit.search('الصلاة');
    final target = cubit.state.results.first;
    await cubit.toggleBookmark(target);
    expect(
      cubit.state.results.firstWhere((h) => h.id == target.id).isBookmarked,
      isTrue,
    );
  });
}
