import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          error: AppColors.loss,
          onSurface: AppColors.textPrimary,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
        ),
      );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE5EAF5),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFF5F7FC),
          surfaceContainerHighest: Color(0xFFEBEFF9),
          surfaceContainerHigh: Color(0xFFDDE5F8),
          primary: Color(0xFF3D7EFF),
          primaryContainer: Color(0xFFD6E4FF),
          secondary: Color(0xFF6B9FFF),
          secondaryContainer: Color(0xFFDDE5F8),
          error: Color(0xFFDC2626),
          errorContainer: Color(0xFFFFDDDD),
          onSurface: Color(0xFF111827),
          onSurfaceVariant: Color(0xFF374151),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          outline: Color(0xFFC8D3E8),
          outlineVariant: Color(0xFFB0BFD8),
          shadow: Color(0x1A3D7EFF),
          scrim: Color(0x663D7EFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FC),
          foregroundColor: Color(0xFF0D1117),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Color(0x14000000),
          iconTheme: IconThemeData(color: Color(0xFF374151)),
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
            letterSpacing: -0.3,
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
            color: const Color(0xFF374151),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.poppins(
            color: const Color(0xFF374151),
            fontSize: 13,
          ),
          bodySmall: GoogleFonts.poppins(
            color: const Color(0xFF6B7280),
            fontSize: 11,
          ),
          labelLarge: GoogleFonts.poppins(
            color: const Color(0xFF0D1117),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF5F7FC),
          elevation: 0,
          shadowColor: const Color(0x1A3D7EFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFC8D3E8)),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerColor: const Color(0xFFC8D3E8),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEBEFF9),
          selectedColor: const Color(0xFF3D7EFF),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
          side: const BorderSide(color: Color(0xFFC8D3E8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEBEFF9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC8D3E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC8D3E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF3D7EFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          ),
          hintStyle:
              GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 14),
          labelStyle:
              GoogleFonts.poppins(color: const Color(0xFF374151), fontSize: 14),
          prefixIconColor: const Color(0xFF6B7280),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D7EFF),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: const Color(0x663D7EFF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3D7EFF),
            side: const BorderSide(color: Color(0xFF3D7EFF)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
        iconTheme: const IconThemeData(color: Color(0xFF374151), size: 20),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8D3E8)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          textStyle:
              GoogleFonts.poppins(color: const Color(0xFF0D1117), fontSize: 12),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFFB0BFD8)),
          radius: const Radius.circular(4),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFFF5F7FC),
          elevation: 4,
          shadowColor: const Color(0x1A3D7EFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFC8D3E8)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFF5F7FC),
          elevation: 8,
          shadowColor: const Color(0x1A3D7EFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFC8D3E8)),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFF5F7FC),
          elevation: 8,
          shadowColor: Color(0x1A3D7EFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0D1117),
          contentTextStyle: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}
