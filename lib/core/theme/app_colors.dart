import 'package:flutter/material.dart';

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
}
