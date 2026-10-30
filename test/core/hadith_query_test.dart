import 'package:bayan_sunnah/core/constants/hadith_grade.dart';
import 'package:bayan_sunnah/core/database/hadith_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HadithQuery.whereClause', () {
    test('is empty when nothing is constrained', () {
      const query = HadithQuery();
      expect(query.whereClause, '');
      expect(query.whereArgs, isEmpty);
    });

    test('constrains by book and chapter', () {
      const query = HadithQuery(bookId: 1, chapterId: 2);
      expect(query.whereClause, 'h.book_id = ? AND h.chapter_id = ?');
      expect(query.whereArgs, [1, 2]);
    });

    test('constrains to sahih and hasan when authenticOnly', () {
      const query = HadithQuery(authenticOnly: true);
      expect(query.whereClause, 'h.grade IN (?, ?)');
      expect(query.whereArgs, ['sahih', 'hasan']);
    });

    test('never includes daif or null grades in the authentic filter', () {
      const query = HadithQuery(authenticOnly: true);
      expect(query.whereClause, isNot(contains('daif')));
      expect(query.whereArgs, isNot(contains('daif')));
      expect(query.whereArgs, isNot(contains(null)));
    });

    test('combines filters in a stable order', () {
      const query = HadithQuery(
        bookId: 3,
        chapterId: 7,
        authenticOnly: true,
        normalizedText: 'الصبر',
      );
      expect(
        query.whereClause,
        'h.book_id = ? AND h.chapter_id = ? AND h.grade IN (?, ?) '
        'AND h.matn_search LIKE ?',
      );
      expect(query.whereArgs, [3, 7, 'sahih', 'hasan', '%الصبر%']);
    });

    test('ignores an empty search string', () {
      const query = HadithQuery(normalizedText: '');
      expect(query.whereClause, '');
      expect(query.whereArgs, isEmpty);
    });
  });

  group('HadithQuery.allows', () {
    const filter = HadithQuery(authenticOnly: true);

    test('accepts sahih and hasan', () {
      expect(filter.allows('sahih'), isTrue);
      expect(filter.allows('hasan'), isTrue);
    });

    test('rejects daif and unclassified hadiths', () {
      expect(filter.allows('daif'), isFalse);
      expect(filter.allows(null), isFalse);
      expect(filter.allows(''), isFalse);
    });

    test('is case and whitespace insensitive', () {
      expect(filter.allows(' Sahih '), isTrue);
    });

    test('accepts everything when the filter is off', () {
      const open = HadithQuery();
      expect(open.allows('daif'), isTrue);
      expect(open.allows(null), isTrue);
    });
  });

  group('HadithGrade', () {
    test('parses the stored values', () {
      expect(HadithGrade.fromId('sahih'), HadithGrade.sahih);
      expect(HadithGrade.fromId('hasan'), HadithGrade.hasan);
      expect(HadithGrade.fromId('daif'), HadithGrade.daif);
    });

    test('treats unknown and null as unclassified', () {
      expect(HadithGrade.fromId(null), HadithGrade.unknown);
      expect(HadithGrade.fromId('mawdu'), HadithGrade.unknown);
    });

    test('marks only sahih and hasan as authentic', () {
      expect(HadithGrade.sahih.isAuthentic, isTrue);
      expect(HadithGrade.hasan.isAuthentic, isTrue);
      expect(HadithGrade.daif.isAuthentic, isFalse);
      expect(HadithGrade.unknown.isAuthentic, isFalse);
    });

    test('uses the specified badge colours', () {
      expect(HadithGrade.sahih.color.toARGB32(), 0xFF059669);
      expect(HadithGrade.hasan.color.toARGB32(), 0xFFD97706);
      expect(HadithGrade.daif.color.toARGB32(), 0xFFDC2626);
    });
  });
}
