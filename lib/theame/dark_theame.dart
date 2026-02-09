import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: AppColors.darkBackground,
    foregroundColor: Colors.white,
  ),
 
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.background, // or AppColors.primary if preferred
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),

);
