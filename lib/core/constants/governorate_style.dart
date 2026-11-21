import 'package:flutter/material.dart';

/// هوية بصرية محايدة لكل محافظة.
///
/// بلا رموز وبلا اختصارات: الأيقونات الرمزية (جامع، قلعة، نخلة…) توحي
/// بانتماء طائفي أو قومي، والاختصارات بحرفين (بغ، بص، نج) لا تُقرأ
/// بوضوح ولا تليق بتطبيق مهني. البديل اسم المحافظة كاملاً داخل شريحة
/// مقوّسة بلونها الخاص — واضح في لمحة ولا يحتمل أي تأويل.
class GovStyle {
  final Color color;
  const GovStyle(this.color);

  static const _map = <String, Color>{
    'بغداد':       Color(0xFF2F6FB8),
    'البصرة':      Color(0xFF2E8B82),
    'نينوى':       Color(0xFF8A62B5),
    'أربيل':       Color(0xFFC2454B),
    'النجف':       Color(0xFF2E8F63),
    'كربلاء':      Color(0xFFBD6690),
    'ذي قار':      Color(0xFF9A6B4F),
    'بابل':        Color(0xFF6B6BC4),
    'ديالى':       Color(0xFF4A8F5A),
    'الأنبار':     Color(0xFF3F93A8),
    'كركوك':       Color(0xFFD08A3E),
    'واسط':        Color(0xFF7A8F3E),
    'صلاح الدين':  Color(0xFF5F7184),
    'ميسان':       Color(0xFF3E8EA0),
    'المثنى':      Color(0xFF7FA03C),
    'القادسية':    Color(0xFF2E8077),
    'دهوك':        Color(0xFF7A4EA8),
    'السليمانية':  Color(0xFFB04A4A),
  };

  static const _fallback = Color(0xFF6E7B88);

  static Color colorOf(String city) => _map[city.trim()] ?? _fallback;

  static GovStyle of(String city) => GovStyle(colorOf(city));
}

/// شريحة المحافظة — الاسم كاملاً داخل مربّع مقوّس بلون المحافظة.
///
/// تحلّ محلّ الدائرة ذات الحرفين. `compact` تصغّرها قليلاً للاستعمال
/// داخل صفوف ضيّقة، و`dim` تُخفّف اللون للعناصر غير النشطة.
class GovMark extends StatelessWidget {
  final String city;
  final bool dim;
  final bool compact;

  /// عدّاد اختياري يظهر بجانب الاسم، مثل عدد الإعلانات في المحافظة.
  final int? count;

  const GovMark({
    super.key,
    required this.city,
    this.dim = false,
    this.compact = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final c    = GovStyle.colorOf(city);
    final name = city.trim().isEmpty ? 'غير محدّد' : city.trim();
    final fs   = compact ? 12.0 : 13.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
        color: c.withOpacity(dim ? 0.05 : 0.11),
        border: Border.all(color: c.withOpacity(dim ? 0.14 : 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 4,
          height: compact ? 12 : 14,
          margin: EdgeInsetsDirectional.only(end: compact ? 7 : 8),
          decoration: BoxDecoration(
            color: c.withOpacity(dim ? 0.35 : 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: fs,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: dim ? c.withOpacity(0.55) : c,
          ),
        ),
        if (count != null) ...[
          SizedBox(width: compact ? 6 : 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: c.withOpacity(dim ? 0.10 : 0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text('$count',
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.bold,
                  color: dim ? c.withOpacity(0.55) : c,
                )),
          ),
        ],
      ]),
    );
  }
}
