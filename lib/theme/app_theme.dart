import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF006847); // Football pitch green
  static const Color accent = Color(0xFFFFD600); // Vivid yellow
  static const Color background = Color(0xFF222831); // Dark background
  static const Color card = Color(0xFF393E46); // Card background
  static const Color error = Color(0xFFFF3A3A);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        background: background,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: accent,
          fontFamily: 'BebasNeue',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'BebasNeue',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
          fontFamily: 'Roboto',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        hintStyle: TextStyle(color: Colors.white54),
      ),
      cardColor: card,
    );
  }
}
