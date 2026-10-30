import 'package:equatable/equatable.dart';

/// A hadith collection bundled in the offline database.
class Book extends Equatable {
  const Book({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.author,
    required this.totalHadiths,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String author;
  final int totalHadiths;

  factory Book.fromMap(Map<String, Object?> map) => Book(
        id: map['id'] as int,
        nameAr: (map['name_ar'] as String?) ?? '',
        nameEn: (map['name_en'] as String?) ?? '',
        author: (map['author'] as String?) ?? '',
        totalHadiths: (map['total_hadiths'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [id, nameAr, nameEn, author, totalHadiths];
}
