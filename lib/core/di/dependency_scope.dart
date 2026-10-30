import 'package:flutter/widgets.dart';

import '../../app_dependencies.dart';

/// Exposes [AppDependencies] to the widget tree.
///
/// Screens read repositories through `context.deps`, which keeps constructors
/// free of plumbing while still allowing tests to inject their own container.
class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DependencyScope>();
    assert(scope != null, 'DependencyScope is missing above this widget');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

extension DependencyScopeX on BuildContext {
  /// The application dependency container.
  AppDependencies get deps => DependencyScope.of(this);
}
