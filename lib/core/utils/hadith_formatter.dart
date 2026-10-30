import '../models/hadith.dart';

/// Builds the plain-text representation used by copy and share.
class HadithFormatter {
  const HadithFormatter._();

  /// Formats [hadith] as text suitable for the clipboard or a share sheet.
  static String toPlainText(Hadith hadith) {
    final buffer = StringBuffer()
      ..writeln(hadith.matnAr.trim())
      ..writeln();
    if (hadith.narrator.trim().isNotEmpty) {
      buffer
        ..writeln(hadith.narrator.trim())
        ..writeln();
    }
    if (hadith.matnEn.trim().isNotEmpty) {
      buffer
        ..writeln(hadith.matnEn.trim())
        ..writeln();
    }
    buffer.write('— ${hadith.reference}');
    final source = hadith.gradeSource;
    final gradeLabel = hadith.grade.labelEn;
    buffer.write(' · $gradeLabel');
    if (source != null && source.trim().isNotEmpty) {
      buffer.write(' ($source)');
    }
    return buffer.toString();
  }
}
