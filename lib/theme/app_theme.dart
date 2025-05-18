import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: const Color(0xFF121212), // Soft black background
    fontFamily: 'Roboto',
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212), // Soft black background
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white), // White icons
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF000000), // True black for contrast
      selectedItemColor: Color(0xFFFF0000), // Red for active icons
      unselectedItemColor: Colors.white, // White for inactive icons
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // White text
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: const Color(0xFF121212), // Soft black background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212), // Soft black background
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white), // White icons
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF000000), // True black for contrast
      selectedItemColor: Color(0xFFFFD700), // Gold for active icons
      unselectedItemColor: Colors.white, // White for inactive icons
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    textTheme: const TextTheme(
      bodyLarge:
          TextStyle(color: Color.fromARGB(255, 255, 255, 255)), // White text
      bodyMedium:
          TextStyle(color: Color.fromARGB(255, 255, 255, 255)), // White text
    ),
  );
}
