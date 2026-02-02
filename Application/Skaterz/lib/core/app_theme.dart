import 'package:flutter/material.dart';
import 'package:skaterz/core/constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryOld,
      primary: AppColors.primaryOld,
      secondary: AppColors.secondaryOld,
      surface: Colors.white,
      onSurface: AppColors.textDark,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryOld,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textLight,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textLight),
      titleTextStyle: TextStyle(
        color: AppColors.textLight,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
  );
}
