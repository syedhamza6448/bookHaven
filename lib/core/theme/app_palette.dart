import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

extension AppPalette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get accent => isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get textPrimary => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get error => isDark ? AppColors.darkError : AppColors.lightError;
}
