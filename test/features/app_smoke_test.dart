import 'package:bayan_sunnah/app_dependencies.dart';
import 'package:bayan_sunnah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/db_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to the collection list from the bundled database',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final dependencies = AppDependencies(
      database: await openAssetDatabase(),
      preferences: await SharedPreferences.getInstance(),
    );
    addTearDown(dependencies.database.close);

    await tester.pumpWidget(BayanSunnahApp(dependencies: dependencies));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // The first query hits a real SQLite isolate, so it needs real time to
    // resolve; only then can the frame be pumped with the loaded state.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bayan Sunnah · بيان السنة'), findsOneWidget);
    expect(find.textContaining('Sahih al-Bukhari'), findsOneWidget);
    expect(find.textContaining('40 Hadith Nawawi'), findsOneWidget);
  });
}
