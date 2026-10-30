/// Normalises Arabic text so that search ignores orthographic variation.
///
/// Diacritics (tashkeel), tatweel, alif variants, taa marbuta, and the
/// dotless yaa are all folded to a canonical form. The `matn_search` column in
/// `assets/sunnah.db` is produced with the *same* rules by
/// `tools/build_db.py`, so a query normalised here matches stored rows exactly.
class ArabicNormalizer {
  const ArabicNormalizer._();

  /// Tashkeel, Quranic annotation marks and superscript alef.
  static final RegExp _diacritics = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC'
    r'\u06DF-\u06E8\u06EA-\u06ED]',
  );

  /// Characters that must never survive into the search form.
  static final RegExp _tatweel = RegExp('\u0640');

  static const Map<String, String> _letterFolds = <String, String>{
    '\u0623': '\u0627', // أ -> ا
    '\u0625': '\u0627', // إ -> ا
    '\u0622': '\u0627', // آ -> ا
    '\u0671': '\u0627', // ٱ -> ا
    '\u0649': '\u064A', // ى -> ي
    '\u0629': '\u0647', // ة -> ه
    '\u0624': '\u0648', // ؤ -> و
    '\u0626': '\u064A', // ئ -> ي
  };

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns the search form of [text].
  ///
  /// Returns an empty string for null or blank input.
  static String normalize(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }
    var result = text
        .replaceAll('<br>', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(_tatweel, '');
    result = result.replaceAllMapped(_diacritics, (_) => '');
    for (final entry in _letterFolds.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAll(_whitespace, ' ').trim();
  }

  /// Normalises a user query for a `LIKE` comparison.
  ///
  /// Returns `null` when the query has no searchable content, which callers
  /// treat as "do not run a text filter".
  static String? normalizeQuery(String? text) {
    final normalized = normalize(text);
    return normalized.isEmpty ? null : normalized;
  }

  /// Returns the normalised form of [text] together with, for every output
  /// character, its index in the original string.
  ///
  /// Used to highlight a normalised search term inside text that still carries
  /// its diacritics: match on the folded form, then map offsets back.
  static (String, List<int>) normalizeWithOffsets(String text) {
    final buffer = StringBuffer();
    final offsets = <int>[];
    var lastWasSpace = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (_diacritics.hasMatch(ch) || ch == _tatweel.pattern) {
        continue;
      }
      if (_whitespace.hasMatch(ch)) {
        if (lastWasSpace || buffer.isEmpty) {
          continue;
        }
        buffer.write(' ');
        offsets.add(i);
        lastWasSpace = true;
        continue;
      }
      lastWasSpace = false;
      buffer.write(_letterFolds[ch] ?? ch);
      offsets.add(i);
    }
    return (buffer.toString(), offsets);
  }

  /// Whether [haystack] contains [needle] once both are normalised.
  static bool matches(String? haystack, String? needle) {
    final n = normalizeQuery(needle);
    if (n == null) {
      return false;
    }
    return normalize(haystack).contains(n);
  }
}
