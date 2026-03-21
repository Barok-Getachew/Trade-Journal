import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          background: AppColors.background,
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          error: AppColors.loss,
          onBackground: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onPrimary: Colors.white,
        ),
        textTheme:
            GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleLarge: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: GoogleFonts.poppins(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerColor: AppColors.border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.loss),
          ),
          hintStyle:
              GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
          labelStyle:
              GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textSecondary, size: 20),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          textStyle:
              GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.borderLight),
          radius: const Radius.circular(4),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          primary: Color(0xFF3D7EFF),
          secondary: Color(0xFF6B9FFF),
          error: Color(0xFFFF4757),
          onSurface: Color(0xFF1A1D24),
          onPrimary: Colors.white,
        ),
        textTheme:
            GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: GoogleFonts.poppins(
            color: const Color(0xFF4A5568),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: const Color(0xFF1A1D24),
            fontSize: 15,
          ),
          bodyMedium: GoogleFonts.poppins(
            color: const Color(0xFF4A5568),
            fontSize: 13,
          ),
          bodySmall: GoogleFonts.poppins(
            color: const Color(0xFF8892A4),
            fontSize: 11,
          ),
          labelLarge: GoogleFonts.poppins(
            color: const Color(0xFF1A1D24),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerColor: const Color(0xFFE2E8F0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F4FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3D7EFF), width: 1.5),
          ),
          hintStyle:
              GoogleFonts.poppins(color: const Color(0xFF8892A4), fontSize: 14),
          labelStyle:
              GoogleFonts.poppins(color: const Color(0xFF4A5568), fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D7EFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3D7EFF),
            side: const BorderSide(color: Color(0xFF3D7EFF)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3D7EFF),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4A5568), size: 20),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          textStyle:
              GoogleFonts.poppins(color: const Color(0xFF0D1117), fontSize: 12),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFFCBD5E0)),
          radius: const Radius.circular(4),
        ),
      );
}
