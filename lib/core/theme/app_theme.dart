import 'package:flutter/material.dart';
import 'package:gigways/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColorToken.primary.color,
          secondary: AppColorToken.secondary.color,
          error: AppColorToken.error.color,
          background: AppColorToken.background.color,
          surface: AppColorToken.surface.color,
        ),
      );

  // Spacing
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Border radius
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;

  static final borderRadius4 = BorderRadius.circular(r4);
  static final borderRadius8 = BorderRadius.circular(r8);
  static final borderRadius12 = BorderRadius.circular(r12);
  static final borderRadius16 = BorderRadius.circular(r16);
}
