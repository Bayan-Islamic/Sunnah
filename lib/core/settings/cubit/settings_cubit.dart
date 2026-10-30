import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings_repository.dart';

part 'settings_state.dart';

/// App-wide reader preferences.
///
/// The authenticity filter lives here so a single toggle can drive the chapter
/// counts, the hadith feed and search at once.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
      : super(
          SettingsState(
            showAuthenticOnly: _repository.showAuthenticOnly,
            arabicFontScale: _repository.arabicFontScale,
          ),
        );

  final SettingsRepository _repository;

  Future<void> setShowAuthenticOnly(bool value) async {
    if (value == state.showAuthenticOnly) {
      return;
    }
    await _repository.setShowAuthenticOnly(value);
    emit(state.copyWith(showAuthenticOnly: value));
  }

  Future<void> setArabicFontScale(double value) async {
    await _repository.setArabicFontScale(value);
    emit(state.copyWith(arabicFontScale: _repository.arabicFontScale));
  }
}
