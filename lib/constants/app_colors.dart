import 'package:flutter/material.dart';

/// Tobeque brand color system — mirrors the website's minimal fashion aesthetic.
/// Primary language: clean white, deep black, subtle grey surfaces, red accents.
class AppColors {
  // ── Core surfaces ───────────────────────────────────────────────────────────
  static const Color background       = Color(0xFFFFFFFF);   // pure white (page bg)
  static const Color surfaceLight     = Color(0xFFF6F6F5);   // off-white card/section bg
  static const Color surface          = Color(0xFFF0F0F0);   // light grey dividers & skeletons
  static const Color surfaceContainer = Color(0xFFEEEEEE);   // image placeholders

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFF0D0D0D);   // near-black body & headings
  static const Color textSecondary    = Color(0xFF6B6B6B);   // muted labels
  static const Color textTertiary     = Color(0xFF9E9E9E);   // very muted hints
  static const Color textOnDark       = Color(0xFFFFFFFF);   // white text on dark bg

  // ── Accent / Brand ──────────────────────────────────────────────────────────
  static const Color primary          = Color(0xFF0D0D0D);   // main CTA: black buttons
  static const Color primaryLight     = Color(0xFF1A1A1A);   // dark card bg
  static const Color accent           = Color(0xFFE53935);   // sale/discount badge red
  static const Color accentGreen      = Color(0xFF2E7D32);   // "Save X%" emerald green
  static const Color accentAmber      = Color(0xFFFFC107);   // star ratings

  // ── Borders ─────────────────────────────────────────────────────────────────
  static const Color border           = Color(0xFFDDDDDD);   // standard border
  static const Color borderLight      = Color(0xFFEEEEEE);   // subtle divider

  // ── Legacy aliases (backward compat) ────────────────────────────────────────
  static const Color darkBackground   = Color(0xFF1A1A1A);
  static const Color textDark         = textPrimary;
  static const Color textLight        = textOnDark;
  static const Color cardBackground   = surfaceLight;
}
