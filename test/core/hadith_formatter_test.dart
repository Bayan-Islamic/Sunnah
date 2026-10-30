import 'package:bayan_sunnah/core/constants/hadith_grade.dart';
import 'package:bayan_sunnah/core/models/hadith.dart';
import 'package:bayan_sunnah/core/utils/hadith_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes the matn, narrator, translation, reference and grade', () {
    const hadith = Hadith(
      id: 1,
      bookId: 1,
      chapterId: 1,
      hadithNumber: 1,
      narrator: 'Umar ibn al-Khattab',
      matnAr: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
      matnEn: 'Actions are but by intention.',
      grade: HadithGrade.daif,
      gradeSource: 'Al-Albani',
      bookNameEn: 'Sahih al-Bukhari',
    );

    final text = HadithFormatter.toPlainText(hadith);
    expect(text, contains('إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ'));
    expect(text, contains('Umar ibn al-Khattab'));
    expect(text, contains('Actions are but by intention.'));
    expect(text, contains('Sahih al-Bukhari 1'));
    expect(text, contains("Da'if"));
    expect(text, contains('Al-Albani'));
  });

  test('omits a missing grade source and translation cleanly', () {
    const hadith = Hadith(
      id: 2,
      bookId: 3,
      chapterId: 1,
      hadithNumber: 2,
      narrator: '',
      matnAr: 'الحديث',
      matnEn: '',
      grade: HadithGrade.sahih,
      gradeSource: '',
      bookNameEn: '40 Hadith Nawawi',
    );

    final text = HadithFormatter.toPlainText(hadith);
    expect(text, contains('الحديث'));
    expect(text, contains('Sahih'));
    expect(text, isNot(contains('(')));
    expect(text.trim().endsWith('Sahih'), isTrue);
  });
}
