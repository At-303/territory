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
  static const error = Color(0xFFE2423B);
}

/// Region styles, in order: square, circle, triangle, heart, sparkle.
const List<Color> regionColors = [
  AppColors.blue,
  AppColors.yellow,
  AppColors.purple,
  AppColors.coral,
  AppColors.green,
];

class AppText {
  static const double body = 24;     // buttons, board numbers
  static const double heading = 32;  // screen titles, level numbers
  static const double display = 64;  // game title
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.ink,
    required this.dialog,
    required this.cell,
  });

  final Color background; // screen
  final Color ink;        // text, icons, outlines on the background
  final Color dialog;
  final Color cell;       // empty board cell

  static const light = AppPalette(
    background: Color(0xFFF0E8DC),
    ink: Color(0xFF1A1A1A),
    dialog: Color(0xFFF4F2F8),
    cell: Colors.white,
  );

  static const dark = AppPalette(
    background: Color(0xFF1F1D24),
    ink: Color(0xFFEDE7DB),
    dialog: Color(0xFF2B2830),
    cell: Color(0xFF2C2A33),
  );

  @override
  AppPalette copyWith({Color? background, Color? ink, Color? dialog, Color? cell}) =>
      AppPalette(
        background: background ?? this.background,
        ink: ink ?? this.ink,
        dialog: dialog ?? this.dialog,
        cell: cell ?? this.cell,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      dialog: Color.lerp(dialog, other.dialog, t)!,
      cell: Color.lerp(cell, other.cell, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
      surface: p.background,
    ),
    iconTheme: IconThemeData(color: p.ink),
    extensions: [p],
    textTheme: GoogleFonts.museoModernoTextTheme().apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
  );
}