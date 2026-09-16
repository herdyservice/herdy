import 'package:flutter/material.dart';

class AppTheme {
  static const rose = Color(0xFFD6608F);
  static const roseClair = Color(0xFFF8C6D8);
  static const lavande = Color(0xFF8E7BD4);
  static const or = Color(0xFFE0B25C);
  static const vert = Color(0xFF5FB68C);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: rose,
      brightness: brightness,
    ).copyWith(secondary: lavande);
    final light = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          light ? const Color(0xFFFFF7FA) : const Color(0xFF16121A),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: light ? const Color(0xFF3B2430) : const Color(0xFFF3E7EE),
        ),
        iconTheme: IconThemeData(
          color: light ? const Color(0xFF3B2430) : const Color(0xFFF3E7EE),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: light ? Colors.white : const Color(0xFF231C2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
