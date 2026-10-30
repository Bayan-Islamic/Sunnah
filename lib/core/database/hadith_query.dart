import '../constants/hadith_grade.dart';

/// Immutable description of a hadith lookup.
///
/// The class owns the *filtering* rules, so the "Sahih & Hasan only" behaviour
/// is verifiable without a database. [DatabaseHelper] only turns the produced
/// clause and arguments into SQL.
class HadithQuery {
  const HadithQuery({
    this.bookId,
    this.chapterId,
    this.authenticOnly = false,
    this.normalizedText,
  });

  final int? bookId;
  final int? chapterId;

  /// When true, only [HadithGrade.sahih] and [HadithGrade.hasan] rows match.
  /// Unclassified rows (NULL grade) are hidden too, because they carry no
  /// verdict a casual reader can rely on.
  final bool authenticOnly;

  /// Already-normalised search text matched against `matn_search`.
  final String? normalizedText;

  /// Grades that survive the authenticity filter, in a stable order.
  static const List<String> authenticGrades = <String>['sahih', 'hasan'];

  HadithQuery copyWith({
    int? bookId,
    int? chapterId,
    bool? authenticOnly,
    String? normalizedText,
  }) =>
      HadithQuery(
        bookId: bookId ?? this.bookId,
        chapterId: chapterId ?? this.chapterId,
        authenticOnly: authenticOnly ?? this.authenticOnly,
        normalizedText: normalizedText ?? this.normalizedText,
      );

  /// SQL `WHERE` fragment without the leading `WHERE`, or an empty string when
  /// nothing constrains the query.
  String get whereClause {
    final parts = <String>[];
    if (bookId != null) {
      parts.add('h.book_id = ?');
    }
    if (chapterId != null) {
      parts.add('h.chapter_id = ?');
    }
    if (authenticOnly) {
      parts.add(
        'h.grade IN (${List.filled(authenticGrades.length, '?').join(', ')})',
      );
    }
    final text = normalizedText;
    if (text != null && text.isNotEmpty) {
      parts.add('h.matn_search LIKE ?');
    }
    return parts.join(' AND ');
  }

  /// Positional arguments matching [whereClause].
  List<Object?> get whereArgs {
    final args = <Object?>[];
    if (bookId != null) {
      args.add(bookId);
    }
    if (chapterId != null) {
      args.add(chapterId);
    }
    if (authenticOnly) {
      args.addAll(authenticGrades);
    }
    final text = normalizedText;
    if (text != null && text.isNotEmpty) {
      args.add('%$text%');
    }
    return args;
  }

  /// Whether the row described by [gradeId] passes the current filter.
  bool allows(String? gradeId) {
    if (!authenticOnly) {
      return true;
    }
    return authenticGrades.contains(gradeId?.trim().toLowerCase());
  }
}
