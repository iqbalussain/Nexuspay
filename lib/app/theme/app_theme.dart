import 'package:flutter/material.dart';

/// Centralised theme. Architecture §24: "Support light/dark theme
/// architecture even if only one theme is initially released" — both are
/// wired up now so nothing downstream has to special-case dark mode later.
///
/// Colours/spacing here are a reasonable starting point, not final visual
/// design — swap the seed colour or extend with design tokens (spacing,
/// radius, elevation — §24) once branding is confirmed.
class AppTheme {
  static const _seedColor = Color(0xFF0F62FE);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.standard,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.standard,
      );
}
