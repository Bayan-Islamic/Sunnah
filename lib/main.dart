import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_dependencies.dart';
import 'core/database/database_helper.dart';
import 'core/settings/cubit/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/books/presentation/cubit/books_cubit.dart';
import 'features/books/presentation/screens/books_screen.dart';
import 'core/di/dependency_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final dependencies = AppDependencies(
    database: DatabaseHelper.instance,
    preferences: preferences,
  );
  runApp(BayanSunnahApp(dependencies: dependencies));
}

/// Root widget. Everything the app needs is provided here: the dependency
/// container, the settings cubit and the Arabic-first localization delegates.
class BayanSunnahApp extends StatelessWidget {
  const BayanSunnahApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return DependencyScope(
      dependencies: dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(dependencies.settings),
          ),
          BlocProvider<BooksCubit>(
            create: (_) => BooksCubit(dependencies.books),
          ),
        ],
        child: MaterialApp(
          title: 'Bayan Sunnah',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const BooksScreen(),
        ),
      ),
    );
  }
}
