import 'package:equatable/equatable.dart';

/// A *kitab* (book section) within a collection.
class Chapter extends Equatable {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.titleAr,
    required this.titleEn,
    this.hadithCount = 0,
  });

  final int id;
  final int bookId;
  final int chapterNumber;
  final String titleAr;
  final String titleEn;

  /// Number of hadiths in the chapter, respecting the active grade filter.
  final int hadithCount;

  factory Chapter.fromMap(Map<String, Object?> map) => Chapter(
        id: map['id'] as int,
        bookId: map['book_id'] as int,
        chapterNumber: (map['chapter_number'] as int?) ?? 0,
        titleAr: (map['title_ar'] as String?) ?? '',
        titleEn: (map['title_en'] as String?) ?? '',
        hadithCount: (map['hadith_count'] as int?) ?? 0,
      );

  Chapter copyWith({int? hadithCount}) => Chapter(
        id: id,
        bookId: bookId,
        chapterNumber: chapterNumber,
        titleAr: titleAr,
        titleEn: titleEn,
        hadithCount: hadithCount ?? this.hadithCount,
      );

  @override
  List<Object?> get props =>
      [id, bookId, chapterNumber, titleAr, titleEn, hadithCount];
}
