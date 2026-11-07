import 'package:flutter/material.dart';

/// Design tokens from DESIGN-notion.md: warm paper canvas, near-black ink,
/// one blue accent for the primary action, hairlines instead of heavy shadows.
abstract final class Palette {
  static const primary = Color(0xFF0075DE);
  static const primaryActive = Color(0xFF005BAB);
  static const canvas = Color(0xFFFFFFFF);
  static const canvasSoft = Color(0xFFF6F5F4);
  static const ink = Color(0xF2000000); // ~95% black
  static const inkSecondary = Color(0xFF31302E);
  static const inkMuted = Color(0xFF615D59);
  static const inkFaint = Color(0xFFA39E98);
  static const hairline = Color(0xFFE6E6E6);
}

abstract final class Radii {
  static const xs = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
}

/// Level-1 "barely-there" layered shadow.
const softShadow = [
  BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0A000000), blurRadius: 18, offset: Offset(0, 4)),
];

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.canvasSoft,
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.primary,
      onPrimary: Colors.white,
      surface: Palette.canvas,
      onSurface: Palette.ink,
      outline: Palette.hairline,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.canvasSoft,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.25, color: Palette.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.canvas,
      labelStyle: const TextStyle(color: Palette.inkMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.xs),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.xs),
        borderSide: const BorderSide(color: Palette.primary),
      ),
    ),
  );
}
