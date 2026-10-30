import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists reader preferences (the authenticity filter and Arabic font scale).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Whether "Sahih & Hasan only" is enabled. Defaults to **true** so a new
  /// reader is never shown a weak narration without opting in.
  bool get showAuthenticOnly =>
      _prefs.getBool(AppConstants.prefShowAuthenticOnly) ?? true;

  Future<void> setShowAuthenticOnly(bool value) =>
      _prefs.setBool(AppConstants.prefShowAuthenticOnly, value);

  /// Multiplier applied to Arabic hadith text. Clamped to 0.8 - 2.0.
  double get arabicFontScale {
    final value = _prefs.getDouble(AppConstants.prefArabicFontScale) ?? 1.0;
    return value.clamp(0.8, 2.0);
  }

  Future<void> setArabicFontScale(double value) =>
      _prefs.setDouble(AppConstants.prefArabicFontScale, value.clamp(0.8, 2.0));
}
