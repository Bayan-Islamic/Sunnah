part of 'settings_cubit.dart';

/// Reader preferences held in memory.
class SettingsState extends Equatable {
  const SettingsState({
    this.showAuthenticOnly = true,
    this.arabicFontScale = 1.0,
  });

  /// When true, only sahih and hasan hadiths are shown.
  final bool showAuthenticOnly;
  final double arabicFontScale;

  SettingsState copyWith({
    bool? showAuthenticOnly,
    double? arabicFontScale,
  }) =>
      SettingsState(
        showAuthenticOnly: showAuthenticOnly ?? this.showAuthenticOnly,
        arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      );

  @override
  List<Object?> get props => [showAuthenticOnly, arabicFontScale];
}
