import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LIBASS Design System — Modern Balanced Chic
/// Deep Forest Green (#2C5F2D) + Coral (#FF6B6B)
class LibassTheme {
  // ─── COLORS ────────────────────────────────────────
  static const Color accentPrimary = Color(0xFF2D5A42);
  static const Color accentPrimaryLight = Color(0xFFE8F0EC); // Light Sage Green
  static const Color accentSecondary = Color(0xFFE85B5B);
  static const Color accentSecondaryLight = Color(0xFFF8E8E6); // Light Pink Surface
  static const Color accentTertiary = Color(0xFFD4A574); // Warm Sand

  static const Color bgPrimary = Color(0xFFF5F2ED); // Soft Cream Background
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSurfaceDim = Color(0xFFF5EFE7); // Cream Accent

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  static const Color success = Color(0xFF7DAF8C);
  static const Color danger = Color(0xFFE85B5B);
  static const Color warning = Color(0xFFD4A574);

  static const Color borderColor = Color(0xFFE5D9CF); // Card Border
  static const Color borderSubtle = Color(0xFFF0E6DC); // Light Border

  // ─── THEME DATA ────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentPrimary,
          primary: accentPrimary,
          secondary: accentSecondary,
          surface: bgSurface,
          error: danger,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: textPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: textPrimary,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            color: textSecondary,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgSurface,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSubtle),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentPrimary,
            side: const BorderSide(color: borderColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentPrimary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bgSurface,
          selectedItemColor: accentPrimary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
