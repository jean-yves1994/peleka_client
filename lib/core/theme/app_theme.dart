import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color navy = Color(0xFF08295D);
  static const Color navyDark = Color(0xFF061E45);
  static const Color navyLight = Color(0xFFE7ECF4);
  static const Color orange = Color(0xFFFF8508);
  static const Color orangeDark = Color(0xFFE06E00);
  static const Color orangeLight = Color(0xFFFFF0DE);
  static const Color blue = Color(0xFF0789D1);
  static const Color blueLight = Color(0xFFE1F1FB);
  static const Color primary = navy;
  static const Color accent = orange;
  static const Color bg = Color(0xFFF6F8FB);
  static const Color surface = Colors.white;
  static const Color ink900 = Color(0xFF0F172A);
  static const Color ink800 = Color(0xFF1E293B);
  static const Color ink700 = Color(0xFF334155);
  static const Color ink500 = Color(0xFF64748B);
  static const Color ink400 = Color(0xFF94A3B8);
  static const Color ink200 = Color(0xFFE2E8F0);
  static const Color ink100 = Color(0xFFF1F5F9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
}

class AppTheme {
  static ThemeData light() {
    final t = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
          primary: AppColors.navy,
          onPrimary: Colors.white,
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          tertiary: AppColors.blue,
          surface: AppColors.surface,
          onSurface: AppColors.ink900,
          error: AppColors.error),
      textTheme:
          t.apply(bodyColor: AppColors.ink900, displayColor: AppColors.navy),
      appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
              color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: AppColors.navy)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.ink200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.blue,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.ink200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.ink200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error)),
          labelStyle:
              GoogleFonts.poppins(color: AppColors.ink500, fontSize: 13),
          hintStyle:
              GoogleFonts.poppins(color: AppColors.ink400, fontSize: 14)),
    );
  }
}
