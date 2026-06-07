import 'package:flutter/material.dart';

/// Dark-mode palette (original constants — keep for backwards compatibility)
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const background = Color(0xFF0A0C10);
  static const surface = Color(0xFF111318);
  static const surfaceElevated = Color(0xFF1A1D24);
  static const surfaceHighlight = Color(0xFF1E2433);

  // ── Primary Accent ───────────────────────────────────────────────────────
  static const primary = Color(0xFF3D7EFF);
  static const primaryLight = Color(0xFF6B9FFF);
  static const primaryDim = Color(0xFF1A3A73);

  // ── Financial ────────────────────────────────────────────────────────────
  static const profit = Color(0xFF00C875);
  static const profitDim = Color(0xFF003D24);
  static const profitLight = Color(0xFF33D68F);

  static const loss = Color(0xFFFF4757);
  static const lossDim = Color(0xFF4D1520);
  static const lossLight = Color(0xFFFF6B78);

  static const warning = Color(0xFFFFB236);
  static const warningDim = Color(0xFF4D3610);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F2F5);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted = Color(0xFF4A5568);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const border = Color(0xFF1E2433);
  static const borderLight = Color(0xFF2A3144);

  // ── Emotion Colors ───────────────────────────────────────────────────────
  static const emotionCalm = Color(0xFF3D7EFF);
  static const emotionFear = Color(0xFFFF8C42);
  static const emotionGreedy = Color(0xFFFF4757);
  static const emotionConfident = Color(0xFF00C875);
  static const emotionNeutral = Color(0xFF8892A4);

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const chartLine = Color(0xFF3D7EFF);
  static const chartGrid = Color(0xFF1A1D24);
  static const chartTooltipBg = Color(0xFF1E2433);

  static const List<Color> chartPalette = [
    Color(0xFF3D7EFF),
    Color(0xFF00C875),
    Color(0xFFFF8C42),
    Color(0xFFAB47BC),
    Color(0xFF26C6DA),
    Color(0xFFFFB236),
  ];

  // ── Theme-adaptive helper ─────────────────────────────────────────────────
  /// Returns a [ThemeColors] object with the correct colors for the current
  /// brightness. Use this in widgets that need to respect light / dark mode.
  ///
  /// Example:
  ///   final c = AppColors.of(context);
  ///   Container(color: c.surface)
  static ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? ThemeColors.dark : ThemeColors.light;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeColors — one object per brightness with all semantic tokens
// ─────────────────────────────────────────────────────────────────────────────

class ThemeColors {
  // backgrounds
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHighlight;

  // primary
  final Color primary;
  final Color primaryLight;
  final Color primaryDim;

  // financial (same across themes)
  final Color profit;
  final Color profitDim;
  final Color loss;
  final Color lossDim;
  final Color warning;
  final Color warningDim;

  // text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // borders
  final Color border;
  final Color borderLight;

  const ThemeColors._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.primary,
    required this.primaryLight,
    required this.primaryDim,
    required this.profit,
    required this.profitDim,
    required this.loss,
    required this.lossDim,
    required this.warning,
    required this.warningDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderLight,
  });

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const dark = ThemeColors._(
    background: Color(0xFF0A0C10),
    surface: Color(0xFF111318),
    surfaceElevated: Color(0xFF1A1D24),
    surfaceHighlight: Color(0xFF1E2433),
    primary: Color(0xFF3D7EFF),
    primaryLight: Color(0xFF6B9FFF),
    primaryDim: Color(0xFF1A3A73),
    profit: Color(0xFF00C875),
    profitDim: Color(0xFF003D24),
    loss: Color(0xFFFF4757),
    lossDim: Color(0xFF4D1520),
    warning: Color(0xFFFFB236),
    warningDim: Color(0xFF4D3610),
    textPrimary: Color(0xFFF0F2F5),
    textSecondary: Color(0xFF8892A4),
    textMuted: Color(0xFF4A5568),
    border: Color(0xFF1E2433),
    borderLight: Color(0xFF2A3144),
  );

  // ── Light palette ──────────────────────────────────────────────────
  // Premium, warm-tinted light mode — never pure white, always has depth
  static const light = ThemeColors._(
    // Warm blue-gray page background — the "paper" the app sits on
    background: Color(0xFFE8EDF8),
    // Slightly warm off-white card/panel surface — not blinding white
    surface: Color(0xFFF8F9FC),
    // Elevated surface — slightly cooler tint to separate layers
    surfaceElevated: Color(0xFFEEF2FB),
    // Highlight — perceptible blue tint for hover/active states
    surfaceHighlight: Color(0xFFE2E9F8),
    // Primary stays consistent
    primary: Color(0xFF3D7EFF),
    primaryLight: Color(0xFF6B9FFF),
    // Soft blue tint for active/selected backgrounds
    primaryDim: Color(0xFFD6E4FF),
    // Financial — rich, accessible colours against the warm surface
    profit: Color(0xFF059669),
    profitDim: Color(0xFFCCF4E3),
    loss: Color(0xFFDC2626),
    lossDim: Color(0xFFFFDDDD),
    warning: Color(0xFFD97706),
    warningDim: Color(0xFFFEF0C7),
    // Text — deep charcoal for high contrast, not harsh pure black
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF374151),
    textMuted: Color(0xFF6B7280),
    // Borders — subtle but clearly visible on the warm surfaces
    border: Color(0xFFC8D3E8),
    borderLight: Color(0xFFB0BFD8),
  );
}
