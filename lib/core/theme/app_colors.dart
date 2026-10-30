import 'package:flutter/material.dart';

/// The deep-emerald palette shared by the Bayan Islamic Suite.
class AppColors {
  const AppColors._();

  // Brand.
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald50 = Color(0xFFECFDF5);

  // Grading accents (kept in sync with HadithGrade).
  static const Color gradeSahih = Color(0xFF059669);
  static const Color gradeHasan = Color(0xFFD97706);
  static const Color gradeDaif = Color(0xFFDC2626);
  static const Color gradeUnknown = Color(0xFF64748B);

  // Light reader surface: a warm off-white that is easier on the eye than
  // pure white for long Arabic passages.
  static const Color readerLight = Color(0xFFFDFBF5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF1C1917);
  static const Color textMutedLight = Color(0xFF57534E);

  // Dark reader surface.
  static const Color readerDark = Color(0xFF121815);
  static const Color surfaceDark = Color(0xFF1B241F);
  static const Color textDark = Color(0xFFE7E5E4);
  static const Color textMutedDark = Color(0xFFA8A29E);
}
