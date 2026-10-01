import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    TextStyle heading(double size, FontWeight weight) =>
        GoogleFonts.cormorantGaramond(
          fontSize: size,
          fontWeight: weight,
          color: primary,
          height: 1.15,
        );

    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
      double? letterSpacing,
    }) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? primary,
      letterSpacing: letterSpacing,
      height: 1.4,
    );

    return TextTheme(
      displayLarge: heading(52, FontWeight.w700),
      displayMedium: heading(44, FontWeight.w700),
      displaySmall: heading(36, FontWeight.w700),
      headlineLarge: heading(32, FontWeight.w700),
      headlineMedium: heading(28, FontWeight.w700),
      headlineSmall: heading(24, FontWeight.w600),
      titleLarge: heading(22, FontWeight.w700),
      titleMedium: body(16, weight: FontWeight.w600),
      titleSmall: body(14, weight: FontWeight.w600),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, color: secondary),
      labelLarge: body(14, weight: FontWeight.w600, letterSpacing: 0.4),
      labelMedium: body(
        12,
        weight: FontWeight.w600,
        color: secondary,
        letterSpacing: 1.4,
      ),
      labelSmall: body(11, color: secondary, letterSpacing: 0.5),
    );
  }
}
