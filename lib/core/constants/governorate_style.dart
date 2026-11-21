import 'package:flutter/material.dart';

/// هوية بصرية لكل محافظة — أيقونة ولون ثابتان، فيتعرّف المستخدم على
/// المحافظة من شكلها قبل أن يقرأ اسمها. الألوان مختارة بتشبّع متوسط
/// (لا فاقعة ولا باهتة) ومتباينة عن بعضها ليبقى الشريط مقروءاً.
class GovStyle {
  final IconData icon;
  final Color color;
  const GovStyle(this.icon, this.color);

  static const _map = <String, GovStyle>{
    'بغداد':       GovStyle(Icons.location_city_rounded,        Color(0xFF2F6FB8)),
    'البصرة':      GovStyle(Icons.anchor_rounded,               Color(0xFF2E8B82)),
    'نينوى':       GovStyle(Icons.account_balance_rounded,      Color(0xFF8A62B5)),
    'أربيل':       GovStyle(Icons.castle_rounded,               Color(0xFFC2454B)),
    'النجف':       GovStyle(Icons.mosque_rounded,               Color(0xFF2E8F63)),
    'كربلاء':      GovStyle(Icons.brightness_low_rounded,       Color(0xFFBD6690)),
    'ذي قار':      GovStyle(Icons.foundation_rounded,           Color(0xFF9A6B4F)),
    'بابل':        GovStyle(Icons.temple_hindu_rounded,         Color(0xFF6B6BC4)),
    'ديالى':       GovStyle(Icons.park_rounded,                 Color(0xFF4A8F5A)),
    'الأنبار':     GovStyle(Icons.waves_rounded,                Color(0xFF3F93A8)),
    'كركوك':       GovStyle(Icons.local_fire_department_rounded, Color(0xFFD08A3E)),
    'واسط':        GovStyle(Icons.agriculture_rounded,          Color(0xFF7A8F3E)),
    'صلاح الدين':  GovStyle(Icons.terrain_rounded,              Color(0xFF5F7184)),
    'ميسان':       GovStyle(Icons.water_drop_rounded,           Color(0xFF3E8EA0)),
    'المثنى':      GovStyle(Icons.grass_rounded,                Color(0xFF7FA03C)),
    'القادسية':    GovStyle(Icons.spa_rounded,                  Color(0xFF2E8077)),
    'دهوك':        GovStyle(Icons.landscape_rounded,            Color(0xFF7A4EA8)),
    'السليمانية':  GovStyle(Icons.filter_hdr_rounded,           Color(0xFFB04A4A)),
  };

  static GovStyle of(String city) =>
      _map[city.trim()] ??
      const GovStyle(Icons.place_rounded, Color(0xFF6E7B88));
}
