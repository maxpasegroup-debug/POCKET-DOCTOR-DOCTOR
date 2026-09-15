import 'package:flutter/material.dart';

final doctorTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFCFDFF),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF007D38),
    primary: const Color(0xFF007D38),
    secondary: const Color(0xFF061D43),
    onSurface: const Color(0xFF061D43),
    surface: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F6FA),
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE4EAF2)),
    ),
  ),
);
