import 'package:flutter/material.dart';

/// Small conveniences used across the presentation layer.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  double get width => MediaQuery.sizeOf(this).width;
}

extension StringX on String {
  /// Whether the string has no visible content.
  bool get isBlank => trim().isEmpty;

  /// Collapses runs of whitespace and trims the result.
  String get collapsed => replaceAll(RegExp(r'\s+'), ' ').trim();
}
