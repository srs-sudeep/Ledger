import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const surface = Color(0xFFFAF8FF);
  static const surfaceContainerLow = Color(0xFFF2F3FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEAEDFF);
  static const surfaceContainerHigh = Color(0xFFE2E7FF);
  static const surfaceTint = Color(0xFF0053DB);
  static const primary = Color(0xFF000000);
  static const primaryContainer = Color(0xFF00174B);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const secondary = Color(0xFF515F74);
  static const outline = Color(0xFF76777D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const tertiaryFixed = Color(0xFFFCDEB5);
  static const onTertiaryFixedVariant = Color(0xFF574425);
  static const onPrimary = Color(0xFFFFFFFF);
  static const inverseSurface = Color(0xFF283044);
}

class AppTheme {
  static ThemeData light() {
    final manrope = GoogleFonts.manropeTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: manrope.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
        headlineLarge: manrope.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
        headlineMedium: manrope.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        titleLarge: manrope.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        titleMedium: inter.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(color: AppColors.onSurface),
        bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.onSurface),
        bodySmall: inter.bodySmall?.copyWith(color: AppColors.secondary),
        labelLarge: inter.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        labelMedium: inter.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: inter.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.secondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: manrope.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppColors.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: inter.labelMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: inter.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.surfaceTint,
        unselectedItemColor: AppColors.secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
    );
  }
}
