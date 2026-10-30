import 'package:equatable/equatable.dart';

import '../constants/hadith_grade.dart';

/// A single hadith record.
class Hadith extends Equatable {
  const Hadith({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.hadithNumber,
    required this.narrator,
    required this.matnAr,
    required this.matnEn,
    required this.grade,
    required this.gradeSource,
    this.bookNameAr = '',
    this.bookNameEn = '',
    this.chapterTitleAr = '',
    this.isBookmarked = false,
  });

  final int id;
  final int bookId;
  final int chapterId;
  final int hadithNumber;
  final String narrator;
  final String matnAr;
  final String matnEn;
  final HadithGrade grade;

  /// The scholar or edition the verdict is attributed to (e.g. "Al-Albani").
  final String? gradeSource;

  final String bookNameAr;
  final String bookNameEn;
  final String chapterTitleAr;
  final bool isBookmarked;

  /// Reference string shown in share/copy output, e.g. "Sahih al-Bukhari 1".
  String get reference {
    final name = bookNameEn.isNotEmpty ? bookNameEn : 'Hadith';
    return '$name $hadithNumber';
  }

  factory Hadith.fromMap(Map<String, Object?> map) => Hadith(
        id: map['id'] as int,
        bookId: map['book_id'] as int,
        chapterId: map['chapter_id'] as int,
        hadithNumber: (map['hadith_number'] as int?) ?? 0,
        narrator: (map['narrator'] as String?) ?? '',
        matnAr: (map['matn_ar'] as String?) ?? '',
        matnEn: (map['matn_en'] as String?) ?? '',
        grade: HadithGrade.fromId(map['grade'] as String?),
        gradeSource: map['grade_source'] as String?,
        bookNameAr: (map['book_name_ar'] as String?) ?? '',
        bookNameEn: (map['book_name_en'] as String?) ?? '',
        chapterTitleAr: (map['chapter_title_ar'] as String?) ?? '',
      );

  Hadith copyWith({bool? isBookmarked}) => Hadith(
        id: id,
        bookId: bookId,
        chapterId: chapterId,
        hadithNumber: hadithNumber,
        narrator: narrator,
        matnAr: matnAr,
        matnEn: matnEn,
        grade: grade,
        gradeSource: gradeSource,
        bookNameAr: bookNameAr,
        bookNameEn: bookNameEn,
        chapterTitleAr: chapterTitleAr,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterId,
        hadithNumber,
        narrator,
        matnAr,
        matnEn,
        grade,
        gradeSource,
        bookNameAr,
        bookNameEn,
        chapterTitleAr,
        isBookmarked,
      ];
}
