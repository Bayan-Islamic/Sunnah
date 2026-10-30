import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the light and dark themes for Bayan Sunnah.
class AppTheme {
  const AppTheme._();

  /// Arabic needs noticeably more leading than Latin text; 1.9 keeps the
  /// diacritics clear of the following line without looking airy.
  static const double arabicLineHeight = 1.9;
  static const double bodyLineHeight = 1.5;

  static ThemeData light() => _build(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.emerald900,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.emerald900,
          secondary: AppColors.emerald600,
          surface: AppColors.surfaceLight,
        ),
        scaffold: AppColors.readerLight,
        surface: AppColors.surfaceLight,
        text: AppColors.textLight,
        muted: AppColors.textMutedLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.emerald600,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.emerald600,
          secondary: AppColors.emerald100,
          surface: AppColors.surfaceDark,
        ),
        scaffold: AppColors.readerDark,
        surface: AppColors.surfaceDark,
        text: AppColors.textDark,
        muted: AppColors.textMutedDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color surface,
    required Color text,
    required Color muted,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: brightness == Brightness.light
                ? const Color(0x14000000)
                : const Color(0x1FFFFFFF),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: text,
        iconColor: colorScheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.light
            ? const Color(0x14000000)
            : const Color(0x1FFFFFFF),
        space: 1,
        thickness: 1,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: text)
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              height: bodyLineHeight,
              color: text,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(color: muted),
          ),
      progressIndicatorTheme:
          base.progressIndicatorTheme.copyWith(color: colorScheme.primary),
    );
  }
}
