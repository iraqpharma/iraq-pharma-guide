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

  // ── Category palette v3.1 ─────────────────────────────────────────────────
  // لوحة واحدة مضبوطة: تشبّع متوسط (≈45–55%) وإضاءة متقاربة، فلا لون يصرخ
  // ولا لون يبهت. كل قسم يأخذ موضعاً مختلفاً على عجلة الألوان حتى تبقى
  // الأقسام مميّزة عن بعضها عند النظر السريع، وكلها تتناغم مع الأخضر الأساسي.
  static const cCardio       = Color(0xFFC2454B); // قرمزي هادئ
  static const cAntibiotics  = Color(0xFF3A72B8); // أزرق فولاذي
  static const cOncology     = Color(0xFF7A4EA8); // بنفسجي عميق
  static const cAnalgesics   = Color(0xFFD08A3E); // عسلي
  static const cGastro       = Color(0xFF2E8B82); // أخضر مزرق
  static const cRespiratory  = Color(0xFF3F93A8); // سماوي رمادي
  static const cNeuro        = Color(0xFF6B6BC4); // نيلي
  static const cPsych        = Color(0xFF8A62B5); // خزامى
  static const cDiabetes     = Color(0xFF2E8F63); // زمردي
  static const cEndocrine    = Color(0xFF9A6B4F); // طيني
  static const cHematology   = Color(0xFFB04A4A); // آجرّي
  static const cImmunology   = Color(0xFF2E8077); // تركوازي داكن
  static const cDerma        = Color(0xFFC25F7E); // وردي محروق
  static const cOphtha       = Color(0xFF3C7FB0); // أزرق سماوي
  static const cUrology      = Color(0xFF3E8EA0); // مائي
  static const cWomens       = Color(0xFFBD6690); // موف
  static const cVaccines     = Color(0xFF4A8F5A); // أخضر ورقي
  static const cVitamins     = Color(0xFFC79A3C); // ذهبي
  static const cFluids       = Color(0xFF3E8F9C); // أزرق مائي
  static const cAnesthesia   = Color(0xFF5F7184); // رمادي أزرق
  static const cNarcotics    = Color(0xFF8A6A55); // بنّي
  static const cCosmetic     = Color(0xFFC06C8C); // وردي مائل للموف
  static const cOtherCat     = Color(0xFF6E7B88); // رمادي محايد

  // ── Category icon backdrop colors (legacy aliases) ────────────────────────
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
  static const catNarcotics   = Color(0xFF6D4C41);   // dark brown
  static const catOther       = Color(0xFF78909C);   // blue-grey

  // ── Quick tool colors ─────────────────────────────────────────────────────
  static const toolPregnancy = Color(0xFF7C3AED);
  static const toolPediatric = Color(0xFFF97316);
  static const toolCold      = Color(0xFF3B82F6);
  static const toolRenal     = Color(0xFF10B981);

  // ── Dark mode surfaces ────────────────────────────────────────────────────
  static const darkBg           = Color(0xFF0F172A); // very dark navy — scaffold
  static const darkSurface      = Color(0xFF1E293B); // dark slate — drawer / sheets
  static const darkCard         = Color(0xFF243146); // slightly lighter — cards
  static const darkElevated     = Color(0xFF2D3D56); // elevated cards / dialogs
  static const darkText         = Color(0xFFF1F5F9); // near-white — primary text
  static const darkTextMuted    = Color(0xFF94A3B8); // muted slate — secondary text
  static const darkDivider      = Color(0xFF2D3F55); // subtle separator
  static const darkInputFill    = Color(0xFF1E293B); // text field fill
}
