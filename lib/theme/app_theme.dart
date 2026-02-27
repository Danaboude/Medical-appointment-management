import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF055B66);
  static const Color secondaryColor = Color(0xFFFFFFFF);
  static const Color neutralColor = Color(0xFFF5F5F5);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Tajawal',
      fontFamilyFallback: ['Tajawal', 'sans-serif', 'Roboto'],
      primaryColor: primaryColor,
      scaffoldBackgroundColor: neutralColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: neutralColor,
        error: errorColor,
        onPrimary: secondaryColor,
        onSecondary: primaryColor,
        onSurface: Colors.black,
        onError: secondaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        color: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Tajawal',
      fontFamilyFallback: ['Tajawal', 'sans-serif', 'Roboto'],
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF1E1E1E),
        error: errorColor,
        onPrimary: secondaryColor,
        onSecondary: primaryColor,
        onSurface: Colors.white,
        onError: secondaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        color: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryColor),
        titleTextStyle: TextStyle(
          color: secondaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
