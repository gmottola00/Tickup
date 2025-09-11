import 'package:flutter/material.dart';

class AppTheme {
  // Brand seed color: Orange for light, Deep Orange for dark
  static const _lightSeed = Colors.orange;
  static const _darkSeed = Colors.deepOrange;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _lightSeed,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        typography: Typography.material2021(),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _darkSeed,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        typography: Typography.material2021(),
      );
}
