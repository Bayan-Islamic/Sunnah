import 'package:flutter/material.dart';

/// The authentication grade attached to a hadith.
///
/// Grades come from the bundled database as the lowercase strings
/// `'sahih'`, `'hasan'` and `'daif'`; a NULL grade means the source carried no
/// explicit verdict and is surfaced as [unknown].
enum HadithGrade {
  sahih('sahih', 'صحيح', 'Sahih'),
  hasan('hasan', 'حَسَن', 'Hasan'),
  daif('daif', 'ضعيف', "Da'if"),
  unknown('', 'غير محدد', 'Unclassified');

  const HadithGrade(this.id, this.labelAr, this.labelEn);

  /// Value stored in `hadiths.grade`.
  final String id;
  final String labelAr;
  final String labelEn;

  /// Parses a raw database value; anything unrecognised becomes [unknown].
  static HadithGrade fromId(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'sahih':
        return HadithGrade.sahih;
      case 'hasan':
        return HadithGrade.hasan;
      case 'daif':
        return HadithGrade.daif;
      default:
        return HadithGrade.unknown;
    }
  }

  /// Whether this grade is safe to show to casual readers.
  ///
  /// The "Sahih & Hasan only" filter hides [daif] and [unknown]; only
  /// [sahih] and [hasan] pass.
  bool get isAuthentic => this == HadithGrade.sahih || this == HadithGrade.hasan;

  /// Badge background colour.
  Color get color {
    switch (this) {
      case HadithGrade.sahih:
        return const Color(0xFF059669); // emerald
      case HadithGrade.hasan:
        return const Color(0xFFD97706); // amber
      case HadithGrade.daif:
        return const Color(0xFFDC2626); // red
      case HadithGrade.unknown:
        return const Color(0xFF64748B); // slate
    }
  }

  /// Emoji shown alongside the badge label.
  String get emoji {
    switch (this) {
      case HadithGrade.sahih:
        return '🟢';
      case HadithGrade.hasan:
        return '🟡';
      case HadithGrade.daif:
        return '🔴';
      case HadithGrade.unknown:
        return '⚪';
    }
  }
}
