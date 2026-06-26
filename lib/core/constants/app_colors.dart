import 'package:flutter/material.dart';

class AppColors {
  // ── Primary palette (deep emerald teal — matches screenshot exactly) ────────
  static const primary      = Color(0xFF00695C);
  static const primaryDark  = Color(0xFF004D40);
  static const primaryLight = Color(0xFFE0F2F1);
  static const accent       = Color(0xFF26A69A);

  // ── Legacy aliases (keep existing references compiling) ────────────────────
  static const primaryBlue  = primary;
  static const accentTeal   = accent;
  static const darkNavy     = primaryDark;
  static const lightBlue    = primaryLight;

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const successGreen = Color(0xFF2E7D32);
  static const warningAmber = Color(0xFFF39C12);
  static const errorRed     = Color(0xFFD32F2F);

  // ── Surface & Text ────────────────────────────────────────────────────────
  static const background   = Color(0xFFF8F9FA);
  static const surface      = Color(0xFFF8F9FA);
  static const cardWhite    = Color(0xFFFFFFFF);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSecondary= Color(0xFF718096);
  static const divider      = Color(0xFFEEF0F3);

  // ── Category icon backdrop colors ─────────────────────────────────────────
  static const catCardio      = Color(0xFFE53E3E);
  static const catAntibiotics = Color(0xFF3B82F6);
  static const catDiabetes    = Color(0xFF10B981);
  static const catPain        = Color(0xFFF97316);
  static const catGastro      = Color(0xFF14B8A6);
  static const catNeuro       = Color(0xFF8B5CF6);
  static const catRespiratory = Color(0xFF06B6D4);
  static const catEndocrine   = Color(0xFF8D6E63);
  static const catVitamins    = Color(0xFFFFB300);   // amber-gold
  static const catCosmetic    = Color(0xFFEC407A);   // rose-pink

  // ── Quick tool colors ─────────────────────────────────────────────────────
  static const toolPregnancy = Color(0xFF7C3AED);
  static const toolPediatric = Color(0xFFF97316);
  static const toolCold      = Color(0xFF3B82F6);
  static const toolRenal     = Color(0xFF10B981);
}
