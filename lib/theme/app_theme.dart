import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.dark.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.violet,
        surface: Color(0xFF0B1020),
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.light.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.purple,
        secondary: AppColors.violet,
        surface: Colors.white,
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
