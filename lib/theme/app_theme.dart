import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  // Brand Green (Emerald / Mint)
  static const Color primaryGreen = Color(0xFF059669);
  static const Color darkGreen = Color(0xFF047857);
  static const Color emeraldBtn = Color(0xFF065F46);
  static const Color lightGreenBadge = Color(0xFFDCFCE7);
  static const Color greenText = Color(0xFF15803D);

  // Brand Navy / Slate
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Accents
  static const Color accentPurple = Color(0xFF6366F1);
  static const Color accentPurpleLight = Color(0xFFEEF2FF);
  static const Color accentPurpleText = Color(0xFF4F46E5);
  static const Color streakOrange = Color(0xFFEA580C);
  static const Color streakOrangeLight = Color(0xFFFFEDD5);

  // Alert Red
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertRedBg = Color(0xFFB91C1C);
  static const Color alertRedLight = Color(0xFFFEE2E2);

  // Blue / Info
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color infoBlueLight = Color(0xFFE0F2FE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentPurple,
        surface: cardBg,
        error: alertRed,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1E293B),
        unselectedItemColor: Color(0xFF94A3B8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
