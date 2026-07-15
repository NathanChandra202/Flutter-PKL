import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Official Brand Colors
  static const Color primaryBlack = Color(0xFF111111); // Deep black/slate
  static const Color accentGold = Color(0xFFD4AF37); // Champagne Gold
  static const Color accentGoldLight = Color(0xFFF1E5AC); // Soft Gold
  static const Color neonGreen = Color(0xFF10B981); // Success green (kept for forms)
  
  static const Color bgWhite = Color(0xFFFAFAFA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  static const Color textBlack = Color(0xFF111111);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        secondary: accentGold,
        surface: surfaceWhite,
        error: Colors.redAccent,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syncopate(
            color: textBlack, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: GoogleFonts.syncopate(
            color: textBlack, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(
            color: textBlack, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.inter(
            color: textBlack, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(
            color: textBlack, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.inter(
            color: textMuted, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }
}

