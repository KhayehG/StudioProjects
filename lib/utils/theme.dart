import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFEEF0F5),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF5B6BE8),
    secondary: Color(0xFF27A06A),
    surface: Color(0xFFEEF0F5),
    background: Color(0xFFEEF0F5), // ignore: deprecated_member_use
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF2D2F45),
    onBackground: Color(0xFF2D2F45), // ignore: deprecated_member_use
    error: Color(0xFFE05A5A),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEEF0F5),
    foregroundColor: Color(0xFF2D2F45),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Color(0xFF2D2F45),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: Color(0xFF2D2F45)),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w600),
    titleLarge: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w600),
    titleMedium: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Color(0xFF2D2F45)),
    bodyMedium: TextStyle(color: Color(0xFF9A9EB5)),
    labelLarge: TextStyle(
      color: Color(0xFF2D2F45), fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFEEF0F5),
    hintStyle: const TextStyle(color: Color(0xFF9A9EB5)),
    labelStyle: const TextStyle(color: Color(0xFF9A9EB5)),
    prefixIconColor: const Color(0xFF9A9EB5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF5B6BE8), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5B6BE8),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(
        vertical: 14, horizontal: 24),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFEEF0F5),
    selectedItemColor: Color(0xFF5B6BE8),
    unselectedItemColor: Color(0xFF9A9EB5),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFE8EAF0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFEEF0F5),
    labelStyle: const TextStyle(color: Color(0xFF2D2F45)),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50)),
  ),
  dividerColor: const Color(0xFFD1D3D8),
  iconTheme: const IconThemeData(color: Color(0xFF2D2F45)),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2D2F45),
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
);
