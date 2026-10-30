import 'package:bayan_sunnah/core/settings/cubit/settings_cubit.dart';
import 'package:bayan_sunnah/core/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsCubit> build([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    return SettingsCubit(SettingsRepository(await SharedPreferences.getInstance()));
  }

  test('defaults to hiding weak hadiths', () async {
    final cubit = await build();
    expect(cubit.state.showAuthenticOnly, isTrue);
    expect(cubit.state.arabicFontScale, 1.0);
  });

  test('toggling the filter emits and persists the new value', () async {
    final cubit = await build();
    await cubit.setShowAuthenticOnly(false);
    expect(cubit.state.showAuthenticOnly, isFalse);

    // A fresh cubit over the same preferences restores the choice.
    final restored = SettingsCubit(
      SettingsRepository(await SharedPreferences.getInstance()),
    );
    expect(restored.state.showAuthenticOnly, isFalse);
  });

  test('does not emit when the value is unchanged', () async {
    final cubit = await build();
    var emissions = 0;
    final subscription = cubit.stream.listen((_) => emissions++);
    await cubit.setShowAuthenticOnly(true);
    expect(emissions, 0);
    await subscription.cancel();
  });

  test('clamps the Arabic font scale to the supported range', () async {
    final cubit = await build();
    await cubit.setArabicFontScale(5.0);
    expect(cubit.state.arabicFontScale, 2.0);
    await cubit.setArabicFontScale(0.1);
    expect(cubit.state.arabicFontScale, 0.8);
  });
}
