import 'package:flutter/material.dart';

abstract final class SoutraliColors {
  static const orange = Color(0xFFFE7402);
  static const green = Color(0xFF037C30);
  static const deepGreen = Color(0xFF0B5A2A);
  static const orangeText = Color(0xFFB24A00);
  static const ivory = Color(0xFFFFF9F2);
  static const ink = Color(0xFF1F2A24);
  static const muted = Color(0xFF5A6B62);
  static const paleGreen = Color(0xFFE8F5EC);
  static const paleOrange = Color(0xFFFFF0E0);
  static const border = Color(0xFFDCE5DF);
  static const danger = Color(0xFFB3261E);
}

abstract final class SoutraliTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: SoutraliColors.green,
      brightness: Brightness.light,
      primary: SoutraliColors.green,
      secondary: SoutraliColors.orange,
      surface: Colors.white,
      error: SoutraliColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SoutraliColors.ivory,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: SoutraliColors.ink,
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: SoutraliColors.ink,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: SoutraliColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: SoutraliColors.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: SoutraliColors.muted, fontSize: 14, height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SoutraliColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SoutraliColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SoutraliColors.green, width: 2),
        ),
      ),
    );
  }
}