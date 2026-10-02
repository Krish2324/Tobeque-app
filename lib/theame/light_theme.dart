import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
List<String> _fallbacksForPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return const ['SF Pro Text', 'SF Pro Display', 'Helvetica Neue', 'Helvetica', 'Arial'];
    case TargetPlatform.macOS:
      return const ['SF Pro Text', 'SF Pro Display', 'Helvetica Neue', 'Helvetica', 'Arial'];
    case TargetPlatform.android:
      return const ['Roboto', 'Noto Sans', 'Droid Sans', 'Arial', 'Helvetica Neue'];
    case TargetPlatform.windows:
      return const ['Segoe UI', 'Arial', 'Helvetica Neue', 'Helvetica'];
    case TargetPlatform.linux:
      return const ['Ubuntu', 'Cantarell', 'Oxygen', 'Fira Sans', 'DejaVu Sans', 'Arial', 'Helvetica Neue'];
    case TargetPlatform.fuchsia:
      return const ['Roboto', 'Arial'];
  }
}
TextTheme buildWhyteStackTextTheme() {
  final fb = _fallbacksForPlatform();
  TextStyle s(TextStyle t) => t.copyWith(fontFamily: 'Whyte', fontFamilyFallback: fb);

  return TextTheme(
    // Big, bold banners like “BERSHKA MUSIC”
    displayLarge: s(const TextStyle(fontSize: 44, height: .95, letterSpacing: 1.0, fontWeight: FontWeight.w900)),
    displayMedium: s(const TextStyle(fontSize: 36, height: .96, letterSpacing: 1.0, fontWeight: FontWeight.w900)),
    headlineLarge: s(const TextStyle(fontSize: 28, height: .98, letterSpacing: .8, fontWeight: FontWeight.w900)),

    // UI/body text
    titleLarge:  s(const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
    bodyLarge:   s(const TextStyle(fontSize: 16)),
    bodyMedium:  s(const TextStyle(fontSize: 14)),
    labelLarge:  s(const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );
}

ThemeData buildAppTheme() {
  final fb = _fallbacksForPlatform();
  return ThemeData(
    useMaterial3: true,
    // Apply at the theme root too so any styles you don’t override still use the stack.
    fontFamily: 'Whyte',
    fontFamilyFallback: fb,
    textTheme: buildWhyteStackTextTheme(),
  );
}
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,

  // ─── CRITICAL FIX: Samsung One UI overrides Material3 button styles ───────
  // Disable Material3 to prevent Samsung from applying its own dynamic-color
  // button theming (extra rounded corners, tinted backgrounds, etc.)
  useMaterial3: false,

  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,

  // Use InkRipple so Samsung's custom splash factory doesn't interfere
  splashFactory: InkRipple.splashFactory,

  cardTheme: CardThemeData(
    color: AppColors.cardBackground,
    elevation: 4,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  textTheme: buildWhyteStackTextTheme(),

  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Colors.black,
    ),
  ),

  // ─── GLOBAL BUTTON THEMES (Samsung-safe) ─────────────────────────────────
  // By declaring explicit styles here, Samsung One UI CANNOT override them.

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Flat — matches app design
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black, width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),

  // Chip theme (used in filters, tags) — Samsung rounds these aggressively
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: Colors.black,
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    side: const BorderSide(color: Color(0xFFDDDDDD)),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),

  // Input decoration (OTP fields, text fields)
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFDDDDDD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.black, width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);

