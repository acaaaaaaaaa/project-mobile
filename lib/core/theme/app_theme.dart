import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.nunitoSansTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.navy,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        modalBackgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Alias untuk kompatibilitas mundur
  static ThemeData get darkTheme => lightTheme;

  // TextStyle untuk Timer Tabular Figures
  static TextStyle get timerDisplay => GoogleFonts.nunitoSans(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        height: 72 / 64,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get tabularFigures => GoogleFonts.nunitoSans(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get headlineLarge => GoogleFonts.nunitoSans(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 36 / 28,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.nunitoSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 28 / 22,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.nunitoSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 24 / 18,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: AppColors.textMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 20 / 16,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.nunitoSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 16 / 13,
        letterSpacing: 0.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.nunitoSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 14 / 11,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      );
}
