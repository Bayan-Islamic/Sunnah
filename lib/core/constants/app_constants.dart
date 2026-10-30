/// Application-wide constants for Bayan Sunnah.
class AppConstants {
  const AppConstants._();

  static const String appNameAr = 'بيان السنة';
  static const String appNameEn = 'Bayan Sunnah';
  static const String packageName = 'org.bayan_islamic.sunnah';

  /// Bundled, pre-populated database shipped as a Flutter asset.
  static const String databaseAsset = 'assets/sunnah.db';
  static const String databaseFileName = 'sunnah.db';
  static const int databaseVersion = 1;

  /// Shared-preferences keys.
  static const String prefShowAuthenticOnly = 'pref_show_authentic_only';
  static const String prefArabicFontScale = 'pref_arabic_font_scale';
  static const String prefBookmarks = 'pref_bookmarks';
  static const String prefLastRead = 'pref_last_read';
}
