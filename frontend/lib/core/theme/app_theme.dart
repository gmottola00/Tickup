import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Colors.indigo;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        typography: Typography.material2021(),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        typography: Typography.material2021(),
      );
}
