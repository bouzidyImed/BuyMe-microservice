import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFF97316); // Orange
  static const Color secondaryColor = Color(0xFF71717A); // Gray
  static const Color successColor = Color(0xFF22C55E);
  static const Color infoColor = Color(0xFF0EA5E9);
  static const Color warningColor = Color(0xFFEAB308);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color lightColor = Color(0xFFE3E3E7);
  static const Color darkColor = Color(0xFF27272A);
  static const Color whiteColor = Colors.white;

  static final ThemeData theme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: dangerColor,
      surface: Colors.white,
    ),
    fontFamily: 'Roboto', // Assuming Roboto is available or default
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: darkColor,
      elevation: 0,
      iconTheme: IconThemeData(color: darkColor),
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Pill shape
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30), // Rounded inputs
        borderSide: const BorderSide(color: secondaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: lightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryColor),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 16),
    ),
  );
}
