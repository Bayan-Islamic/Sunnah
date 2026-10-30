import 'package:bayan_sunnah/core/utils/arabic_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicNormalizer.normalize', () {
    test('strips diacritics (tashkeel)', () {
      expect(ArabicNormalizer.normalize('مُحَمَّدٌ'), 'محمد');
      expect(ArabicNormalizer.normalize('كِتَابٌ'), 'كتاب');
    });

    test('strips tatweel', () {
      expect(ArabicNormalizer.normalize('مـــحـــمـــد'), 'محمد');
    });

    test('unifies alif variants to bare alif', () {
      expect(ArabicNormalizer.normalize('أَحْمَد'), 'احمد');
      expect(ArabicNormalizer.normalize('إسلام'), 'اسلام');
      expect(ArabicNormalizer.normalize('آمن'), 'امن');
    });

    test('folds taa marbuta to haa', () {
      expect(ArabicNormalizer.normalize('صلاة'), 'صلاه');
      expect(ArabicNormalizer.normalize('جنة'), 'جنه');
    });

    test('folds alif maqsura to yaa', () {
      expect(ArabicNormalizer.normalize('هدى'), 'هدي');
    });

    test('collapses whitespace and newlines', () {
      expect(ArabicNormalizer.normalize('a\n\n  b\tc'), 'a b c');
    });

    test('returns empty string for null and blank input', () {
      expect(ArabicNormalizer.normalize(null), '');
      expect(ArabicNormalizer.normalize(''), '');
      expect(ArabicNormalizer.normalize('   '), '');
    });

    test('is idempotent', () {
      const input = 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ';
      final once = ArabicNormalizer.normalize(input);
      expect(ArabicNormalizer.normalize(once), once);
    });
  });

  group('ArabicNormalizer.normalizeQuery', () {
    test('returns null for empty or whitespace-only queries', () {
      expect(ArabicNormalizer.normalizeQuery(''), isNull);
      expect(ArabicNormalizer.normalizeQuery('   '), isNull);
      expect(ArabicNormalizer.normalizeQuery(null), isNull);
    });

    test('returns the folded query otherwise', () {
      expect(ArabicNormalizer.normalizeQuery('الصَّلَاة'), 'الصلاه');
    });
  });

  group('ArabicNormalizer.matches', () {
    test('ignores diacritics and letter variants', () {
      expect(
        ArabicNormalizer.matches('إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ', 'الاعمال'),
        isTrue,
      );
      expect(ArabicNormalizer.matches('كتاب الصلاة', 'الصلاه'), isTrue);
    });

    test('does not match unrelated text', () {
      expect(ArabicNormalizer.matches('كتاب الصلاة', 'الزكاة'), isFalse);
    });
  });

  group('ArabicNormalizer.normalizeWithOffsets', () {
    test('maps each folded character back to its source index', () {
      const source = 'كِتَاب';
      final (folded, offsets) = ArabicNormalizer.normalizeWithOffsets(source);
      expect(folded, 'كتاب');
      expect(offsets.length, folded.length);
      // Each offset points at the surviving consonant in the original string.
      expect(offsets, [0, 2, 4, 5]);
      for (final offset in offsets) {
        expect(source[offset], isNot(anyOf('\u064B', '\u064E')));
      }
    });

    test('folds letter variants in the output', () {
      final (folded, _) = ArabicNormalizer.normalizeWithOffsets('أَحْمَد');
      expect(folded, 'احمد');
    });
  });
}
