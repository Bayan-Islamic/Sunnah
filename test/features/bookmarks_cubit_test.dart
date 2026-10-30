import 'package:bayan_sunnah/core/database/database_helper.dart';
import 'package:bayan_sunnah/features/bookmarks/data/bookmarks_repository.dart';
import 'package:bayan_sunnah/features/bookmarks/presentation/cubit/bookmarks_cubit.dart';
import 'package:bayan_sunnah/features/hadith_reader/data/hadith_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/db_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper db;
  late BookmarksRepository repository;
  late BookmarksCubit cubit;

  setUpAll(() async {
    db = await openAssetDatabase();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = BookmarksRepository(await SharedPreferences.getInstance());
    cubit = BookmarksCubit(repository, HadithRepository(db));
  });

  tearDownAll(() async {
    await db.close();
  });

  test('loads an empty list initially', () async {
    await cubit.load();
    expect(cubit.state.status, BookmarksStatus.success);
    expect(cubit.state.isEmpty, isTrue);
  });

  test('loads saved hadiths from preferences', () async {
    await repository.save([1, 2, 3]);
    await cubit.load();
    expect(cubit.state.hadiths.map((h) => h.id).toList(), [1, 2, 3]);
    expect(cubit.state.hadiths.every((h) => h.isBookmarked), isTrue);
  });

  test('remove drops the hadith from the list and preferences', () async {
    await repository.save([1, 2, 3]);
    await cubit.load();
    await cubit.remove(cubit.state.hadiths.first);
    expect(cubit.state.ids, [2, 3]);
    expect(repository.load(), [2, 3]);
  });

  test('ignores ids that no longer exist in the database', () async {
    await repository.save([1, 999999]);
    await cubit.load();
    expect(cubit.state.hadiths.map((h) => h.id), [1]);
  });
}
