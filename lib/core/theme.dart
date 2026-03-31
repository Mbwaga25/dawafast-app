import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Slate/Blue theme inspired by Dawafast Web Frontend (globals.css OKLCH colors)
  static const Color primaryBlue = Color(0xFF1E293B); // Slate 800
  static const Color accentBlue = Color(0xFF334155); // Slate 700
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  static final TextStyle headingStyle = GoogleFonts.inter(
    color: textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceWhite,
        background: backgroundWhite,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundWhite,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Dawafast Web radius (0.625rem = 10px)
          side: const BorderSide(color: borderColor),
        ),
        color: surfaceWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
