import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  primaryColor: AppColors.primary,
 
  scaffoldBackgroundColor: AppColors.background,
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
    
     titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Colors.black,
    ),
  ),
 
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary, // text color
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),

);
