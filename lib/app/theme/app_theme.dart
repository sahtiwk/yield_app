import 'package:flutter/material.dart';

abstract final class Palette {
  static const green = Color(0xFF003F32);
  static const mint = Color(0xFFB8EEDB);
  static const pale = Color(0xFFE4F5EF);
  static const background = Color(0xFFF7F9FA);
  static const surface = Color(0xFFF0F3F0);
  static const ink = Color(0xFF252D29);
  static const muted = Color(0xFF5D6862);
  static const orange = Color(0xFFFF962B);
  static const peach = Color(0xFFFFDDC4);
  static const amber = Color(0xFF925000);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 1,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Palette.pale,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, letterSpacing: 0),
    ),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Palette.pale,
  ),
  scaffoldBackgroundColor: Palette.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.green,
    primary: Palette.green,
    surface: Colors.white,
  ),
  fontFamily: 'Poppins',
  fontFamilyFallback: const [
    'NotoSansTelugu',
    'NotoSansDevanagari',
    'NotoSansKannada',
    'NotoSansTamil',
  ],
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: Palette.green,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: Palette.ink,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Palette.muted),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: Palette.muted),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 50),
      side: const BorderSide(color: Color(0xFFDCE3DD)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Palette.green, width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE4E9E5), thickness: 1),
);
