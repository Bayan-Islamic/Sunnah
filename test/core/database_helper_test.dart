import 'package:bayan_sunnah/core/constants/hadith_grade.dart';
import 'package:bayan_sunnah/core/database/database_helper.dart';
import 'package:bayan_sunnah/core/database/hadith_query.dart';
import 'package:bayan_sunnah/core/utils/arabic_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/db_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper db;

  setUpAll(() async {
    db = await openAssetDatabase();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('schema and seeding', () {
    test('exposes the four specified collections plus the graded sample', () async {
      final books = await db.getBooks();
      expect(books.length, greaterThanOrEqualTo(4));
      expect(books.map((b) => b.nameEn), containsAll(<String>[
        'Sahih al-Bukhari',
        'Sahih Muslim',
        '40 Hadith Nawawi',
        'Riyad as-Salihin',
      ]));
    });

    test('every book reports a positive hadith total', () async {
      final books = await db.getBooks();
      for (final book in books) {
        expect(book.totalHadiths, greaterThan(0), reason: book.nameEn);
      }
    });

    test('Nawawi is seeded with the complete forty-two narrations', () async {
      final nawawi = (await db.getBooks())
          .firstWhere((b) => b.nameEn == '40 Hadith Nawawi');
      final hadiths = await db.getHadiths(HadithQuery(bookId: nawawi.id));
      expect(hadiths.length, 42);
      expect(
        hadiths.map((h) => h.hadithNumber).toSet().length,
        42,
        reason: 'hadith numbers must be unique',
      );
    });

    test('chapters are ordered and carry the collection id', () async {
      final chapters = await db.getChapters(3);
      expect(chapters, isNotEmpty);
      for (var i = 0; i < chapters.length; i++) {
        expect(chapters[i].bookId, 3);
        if (i > 0) {
          expect(
            chapters[i].chapterNumber,
            greaterThan(chapters[i - 1].chapterNumber),
          );
        }
      }
    });

    test('a hadith carries Arabic matn, a grade and a source', () async {
      final hadiths = await db.getHadiths(const HadithQuery(bookId: 3));
      final first = hadiths.first;
      expect(first.matnAr.trim(), isNotEmpty);
      expect(first.bookNameEn, '40 Hadith Nawawi');
      expect(first.grade, isNot(HadithGrade.unknown));
      expect(first.gradeSource, isNotNull);
    });

    test('the corpus contains sahih, hasan and daif grades', () async {
      final all = await db.getHadiths(const HadithQuery());
      final grades = all.map((h) => h.grade).toSet();
      expect(grades, contains(HadithGrade.sahih));
      expect(grades, contains(HadithGrade.hasan));
      expect(
        grades,
        contains(HadithGrade.daif),
        reason: 'the da\'if badge and filter need real weak narrations',
      );
    });
  });

  group('authenticity filter', () {
    test('hides daif and unclassified hadiths when active', () async {
      final all = await db.getHadiths(const HadithQuery());
      final authentic =
          await db.getHadiths(const HadithQuery(authenticOnly: true));

      expect(authentic.length, lessThan(all.length));
      for (final hadith in authentic) {
        expect(
          hadith.grade.isAuthentic,
          isTrue,
          reason: '${hadith.reference} leaked a ${hadith.grade.id} hadith',
        );
      }
      expect(
        authentic.any((h) => h.grade == HadithGrade.daif),
        isFalse,
      );
    });

    test('returns every hadith when the filter is off', () async {
      final all = await db.getHadiths(const HadithQuery());
      expect(all.any((h) => h.grade == HadithGrade.daif), isTrue);
    });

    test('counts per chapter drop under the filter', () async {
      final book = (await db.getBooks()).first;
      final unfiltered = await db.getChapters(book.id);
      final filtered = await db.getChapters(book.id, authenticOnly: true);
      final unfilteredTotal =
          unfiltered.fold<int>(0, (sum, c) => sum + c.hadithCount);
      final filteredTotal =
          filtered.fold<int>(0, (sum, c) => sum + c.hadithCount);
      expect(filteredTotal, lessThanOrEqualTo(unfilteredTotal));
      expect(await db.countHadiths(book.id), unfilteredTotal);
      expect(
        await db.countHadiths(book.id, authenticOnly: true),
        filteredTotal,
      );
    });

    test('never returns a weak hadith across every collection', () async {
      final books = await db.getBooks();
      for (final book in books) {
        final authentic = await db.getHadiths(
          HadithQuery(bookId: book.id, authenticOnly: true),
        );
        for (final hadith in authentic) {
          expect(hadith.grade.isAuthentic, isTrue, reason: hadith.reference);
        }
      }
    });
  });

  group('search', () {
    test('finds hadiths by a word taken from the corpus', () async {
      final results = await db.search('الصلاة');
      expect(results, isNotEmpty);
    });

    test('matches despite diacritics and alif variants', () async {
      final plain = await db.search('الاعمال');
      final withDiacritics = await db.search('الأَعْمَال');
      expect(plain, isNotEmpty);
      expect(
        withDiacritics.map((h) => h.id).toSet(),
        plain.map((h) => h.id).toSet(),
      );
    });

    test('returns nothing for a blank query', () async {
      expect(await db.search('   '), isEmpty);
    });

    test('respects the authenticity filter', () async {
      final all = await db.search('الصلاة');
      final authentic = await db.search('الصلاة', authenticOnly: true);
      expect(authentic.length, lessThanOrEqualTo(all.length));
      for (final hadith in authentic) {
        expect(hadith.grade.isAuthentic, isTrue);
      }
    });

    test('can be scoped to one collection', () async {
      final scoped = await db.search('الله', bookId: 3);
      expect(scoped, isNotEmpty);
      expect(scoped.every((h) => h.bookId == 3), isTrue);
    });

    test('normalised query text matches what the normaliser produces', () async {
      const raw = 'الصَّلَاة';
      final results = await db.search(raw);
      final needle = ArabicNormalizer.normalize(raw);
      for (final hadith in results) {
        expect(
          ArabicNormalizer.normalize(hadith.matnAr),
          contains(needle),
        );
      }
    });
  });

  group('lookups', () {
    test('getHadithsByIds preserves the requested order', () async {
      final some = await db.getHadiths(const HadithQuery(bookId: 3));
      final ids = [some[3].id, some[0].id, some[2].id];
      final fetched = await db.getHadithsByIds(ids);
      expect(fetched.map((h) => h.id).toList(), ids);
    });

    test('getHadithsByIds returns empty for no ids', () async {
      expect(await db.getHadithsByIds(const []), isEmpty);
    });

    test('totalHadithCount matches a full query', () async {
      final all = await db.getHadiths(const HadithQuery());
      expect(await db.totalHadithCount(), all.length);
    });
  });
}
