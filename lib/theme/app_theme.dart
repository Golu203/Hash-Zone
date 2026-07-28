import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Minimalist Light Theme Palette: White, Black, Gray, Charcoal
  static const Color primaryBlack = Color(0xFF000000);
  static const Color secondaryWhite = Color(0xFFFFFFFF);
  static const Color charcoalDark = Color(0xFF111111);
  static const Color charcoalMedium = Color(0xFF333333);
  static const Color grayMuted = Color(0xFF666666);
  static const Color grayLight = Color(0xFFF7F7F8);
  static const Color borderBlack = Color(0xFF000000);
  static const Color whatsAppGreen = Color(0xFF25D366);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: secondaryWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        secondary: charcoalDark,
        surface: secondaryWhite,
        onPrimary: secondaryWhite,
        onSecondary: secondaryWhite,
        onSurface: charcoalDark,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: charcoalDark,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: charcoalDark,
        ),
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: charcoalDark,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: charcoalDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: charcoalDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: charcoalDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: grayMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: secondaryWhite,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryWhite,
        foregroundColor: charcoalDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: secondaryWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderBlack, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: secondaryWhite,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlack,
          side: const BorderSide(color: primaryBlack, width: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryWhite,
        hintStyle: const TextStyle(color: grayMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderBlack, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderBlack, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 2.0),
        ),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
