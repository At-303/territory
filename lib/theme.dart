import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF0E8DC);
  static const blue = Color(0xFF8FA6C8);
  static const purple = Color(0xFFB5A0CC);
  static const yellow = Color(0xFFE8BE68);
  static const coral = Color(0xFFD98B78);
  static const green = Color(0xFF8FA896);
  static const ink = Color(0xFF1A1A1A);
  static const dialog = Color(0xFFF4F2F8);
}

/// Region styles, in order: square, circle, triangle, heart, sparkle.
const List<Color> regionColors = [
  AppColors.blue,
  AppColors.yellow,
  AppColors.purple,
  AppColors.coral,
  AppColors.green,
];

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      surface: AppColors.background,
    ),
    textTheme: GoogleFonts.lexendTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
