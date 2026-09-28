import 'package:flutter/material.dart';

class AppTheme {
  // Tesla / Apple EV inspired Palette
  static const Color background = Color(0xFFF8FAFC); // Clean ceramic white/slate-50
  static const Color surface = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Light gray surface slate-100
  static const Color border = Color(0xFFE2E8F0); // Subtle divider slate-200
  static const Color primary = Color(0xFF0F172A); // Deep slate-900 (Tesla Obsidian)
  static const Color accent = Color(0xFF2563EB); // Modern Electric Blue
  static const Color success = Color(0xFF059669); // Emerald-600
  static const Color danger = Color(0xFFDC2626); // Crimson-600
  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: danger,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
