import 'package:flutter/material.dart';
import 'app_colors.dart';

/// لون وأيقونة كل قسم في مكان واحد، حتى تبقى الشاشة الرئيسية وشاشة العوائل
/// وشاشة الأدوية متطابقة بصرياً بلا تكرار للقيم.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);

  static const _map = <String, CategoryStyle>{
    'cardiovascular':      CategoryStyle(Icons.monitor_heart_outlined,     AppColors.cCardio),
    'antibiotics':         CategoryStyle(Icons.biotech_outlined,           AppColors.cAntibiotics),
    'oncology':            CategoryStyle(Icons.radio_button_checked,       AppColors.cOncology),
    'analgesics':          CategoryStyle(Icons.healing_outlined,           AppColors.cAnalgesics),
    'gastrointestinal':    CategoryStyle(Icons.restaurant_outlined,        AppColors.cGastro),
    'respiratory':         CategoryStyle(Icons.air_outlined,               AppColors.cRespiratory),
    'neurology':           CategoryStyle(Icons.psychology_alt_outlined,    AppColors.cNeuro),
    'psychiatry':          CategoryStyle(Icons.self_improvement_outlined,  AppColors.cPsych),
    'diabetes':            CategoryStyle(Icons.water_drop_outlined,        AppColors.cDiabetes),
    'endocrine':           CategoryStyle(Icons.hub_outlined,               AppColors.cEndocrine),
    'hematology':          CategoryStyle(Icons.bloodtype_outlined,         AppColors.cHematology),
    'immunology':          CategoryStyle(Icons.shield_outlined,            AppColors.cImmunology),
    'dermatology':         CategoryStyle(Icons.spa_outlined,               AppColors.cDerma),
    'ophthalmology':       CategoryStyle(Icons.visibility_outlined,        AppColors.cOphtha),
    'urology':             CategoryStyle(Icons.opacity_outlined,           AppColors.cUrology),
    'womens_health':       CategoryStyle(Icons.pregnant_woman_outlined,    AppColors.cWomens),
    'vaccines':            CategoryStyle(Icons.vaccines_outlined,          AppColors.cVaccines),
    'vitamins':            CategoryStyle(Icons.eco_outlined,               AppColors.cVitamins),
    'fluids_electrolytes': CategoryStyle(Icons.science_outlined,           AppColors.cFluids),
    'anesthesia':          CategoryStyle(Icons.airline_seat_flat_outlined, AppColors.cAnesthesia),
    'narcotics':           CategoryStyle(Icons.lock_outline_rounded,       AppColors.cNarcotics),
    'cosmetic':            CategoryStyle(Icons.auto_awesome_outlined,      AppColors.cCosmetic),
    'other':               CategoryStyle(Icons.category_outlined,          AppColors.cOtherCat),
  };

  static CategoryStyle of(String key) =>
      _map[key] ??
      const CategoryStyle(Icons.medication_outlined, AppColors.primary);
}
