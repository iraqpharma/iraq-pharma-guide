import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// حاسبة السوائل والتخفيف — أربع حاسبات في شاشة واحدة:
///
/// 1. التخفيف (C1·V1 = C2·V2): كم أسحب من العيار وكم أضيف من المذيب.
/// 2. معدل التسريب: mL/hr وعدد القطرات في الدقيقة.
/// 3. الجرعة بالوزن: من mcg/kg/min إلى mL/hr وبالعكس.
/// 4. سوائل الصيانة للأطفال (Holliday-Segar 4-2-1).
///
/// كل النتائج تُحتسب محلياً بلا إنترنت، والأرقام للمساعدة لا للاستبدال
/// بالتحقّق من المصدر قبل التحضير.
class FluidCalculatorScreen extends StatelessWidget {
  const FluidCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('حاسبة السوائل والتخفيف',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle:
                TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'التخفيف'),
              Tab(text: 'معدل التسريب'),
              Tab(text: 'جرعة بالوزن'),
              Tab(text: 'صيانة الأطفال'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _DilutionTab(),
          _RateTab(),
          _WeightDoseTab(),
          _MaintenanceTab(),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// عناصر مشتركة
// ═══════════════════════════════════════════════════════════════════════════════

double? _n(TextEditingController c) {
  final t = c.text.trim().replaceAll('٫', '.').replaceAll(',', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String _fmt(double v, [int dp = 2]) {
  if (v.isNaN || v.isInfinite) return '—';
  final s = v.toStringAsFixed(dp);
  return s.endsWith('.00')
      ? s.substring(0, s.length - 3)
      : (s.endsWith('0') && s.contains('.') ? s.substring(0, s.length - 1) : s);
}

class _Num extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String unit;
  final String? hint;
  final ValueChanged<String> onChanged;
  const _Num({
    required this.ctrl,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.٫]')),
          ],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            labelStyle: const TextStyle(fontSize: 13),
            suffixText: unit,
            suffixStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.4)),
          ),
        ),
      );
}

class _Result extends StatelessWidget {
  final String title;
  final List<List<String>> rows; // [label, value]
  final Color color;
  final String? note;
  const _Result({
    required this.title,
    required this.rows,
    this.color = AppColors.primary,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            color.withOpacity(isDark ? 0.22 : 0.11),
            color.withOpacity(isDark ? 0.10 : 0.03),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.calculate_rounded, size: 17, color: color),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 10),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(r[0],
                      style: const TextStyle(fontSize: 12.5, height: 1.4)),
                ),
                const SizedBox(width: 8),
                Text(r[1],
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note!,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.warningAmber.withOpacity(0.22)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 17, color: AppColors.warningAmber),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
                'الحاسبة أداة مساعدة — راجع نشرة المنتج وبروتوكول المستشفى '
                'قبل التحضير، وتحقّق من الحساب مرّة ثانية مع زميل في '
                'الأدوية عالية الخطورة.',
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.65,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1) التخفيف — C1·V1 = C2·V2
// ═══════════════════════════════════════════════════════════════════════════════

class _DilutionTab extends StatefulWidget {
  const _DilutionTab();

  @override
  State<_DilutionTab> createState() => _DilutionTabState();
}

class _DilutionTabState extends State<_DilutionTab> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  final _v2 = TextEditingController();

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _v2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c1 = _n(_c1), c2 = _n(_c2), v2 = _n(_v2);
    final ok = c1 != null && c2 != null && v2 != null && c1 > 0 && c2 > 0;
    final v1 = ok ? (c2 * v2) / c1 : null;
    final tooStrong = ok && c2 > c1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text('من تركيز جاهز إلى تركيز مطلوب — تُحسب كمية العيار والمذيب.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _Num(
            ctrl: _c1,
            label: 'تركيز العيار المتوفّر (C1)',
            unit: 'mg/mL',
            hint: 'مثال: 50',
            onChanged: (_) => setState(() {})),
        _Num(
            ctrl: _c2,
            label: 'التركيز المطلوب (C2)',
            unit: 'mg/mL',
            hint: 'مثال: 5',
            onChanged: (_) => setState(() {})),
        _Num(
            ctrl: _v2,
            label: 'الحجم النهائي المطلوب (V2)',
            unit: 'mL',
            hint: 'مثال: 100',
            onChanged: (_) => setState(() {})),
        if (tooStrong)
          const _Result(
            title: 'غير ممكن',
            rows: [
              ['التركيز المطلوب أعلى من تركيز العيار', '✕'],
            ],
            color: AppColors.errorRed,
            note: 'التخفيف يُنزِل التركيز لا يرفعه — راجع الأرقام أو ابحث '
                'عن عيار أقوى.',
          )
        else if (v1 != null)
          _Result(
            title: 'التحضير',
            rows: [
              ['اسحب من العيار', '${_fmt(v1)} mL'],
              ['أضف مذيباً', '${_fmt(v2! - v1)} mL'],
              ['الحجم النهائي', '${_fmt(v2)} mL'],
              ['الكمية الكلية للدواء', '${_fmt(c2! * v2)} mg'],
            ],
            note: 'نسبة التخفيف ≈ 1 : ${_fmt(c1! / c2, 1)} — '
                'استعمل المذيب الموصى به في نشرة الدواء (NS أو D5W أو ماء '
                'للحقن) لا أي مذيب.',
          ),
        const _Disclaimer(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2) معدل التسريب
// ═══════════════════════════════════════════════════════════════════════════════

class _RateTab extends StatefulWidget {
  const _RateTab();

  @override
  State<_RateTab> createState() => _RateTabState();
}

class _RateTabState extends State<_RateTab> {
  final _vol   = TextEditingController();
  final _hours = TextEditingController();
  int _dropFactor = 20;

  @override
  void dispose() {
    _vol.dispose();
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _n(_vol), h = _n(_hours);
    final ok = v != null && h != null && h > 0;
    final mlh = ok ? v / h : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text('من حجم الكيس ومدّة التسريب إلى معدل المضخة وعدد القطرات.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _Num(
            ctrl: _vol,
            label: 'الحجم الكلي',
            unit: 'mL',
            hint: 'مثال: 500',
            onChanged: (_) => setState(() {})),
        _Num(
            ctrl: _hours,
            label: 'مدّة التسريب',
            unit: 'ساعة',
            hint: 'مثال: 8 — نصف ساعة تُكتب 0.5',
            onChanged: (_) => setState(() {})),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, right: 2),
          child: Text('معامل القطرة (مكتوب على علبة السِت)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final f in [10, 15, 20, 60])
              ChoiceChip(
                label: Text(
                    f == 60 ? '60 (ميكرو)' : '$f gtt/mL',
                    style: const TextStyle(fontSize: 12)),
                selected: _dropFactor == f,
                onSelected: (_) => setState(() => _dropFactor = f),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (mlh != null)
          _Result(
            title: 'المعدل',
            rows: [
              ['معدل المضخة', '${_fmt(mlh)} mL/hr'],
              ['القطرات', '${_fmt(mlh * _dropFactor / 60, 0)} قطرة/دقيقة'],
              ['بالثانية', 'قطرة كل ${_fmt(60 / (mlh * _dropFactor / 60), 1)} ث'],
            ],
            note: 'بالعدّ اليدوي: احسب القطرات في 15 ثانية واضربها في 4 '
                'للتحقّق من الضبط.',
          ),
        const _Disclaimer(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3) الجرعة بالوزن — mcg/kg/min ⇄ mL/hr
// ═══════════════════════════════════════════════════════════════════════════════

class _WeightDoseTab extends StatefulWidget {
  const _WeightDoseTab();

  @override
  State<_WeightDoseTab> createState() => _WeightDoseTabState();
}

class _WeightDoseTabState extends State<_WeightDoseTab> {
  final _weight = TextEditingController();
  final _dose   = TextEditingController();
  final _drugMg = TextEditingController();
  final _bagMl  = TextEditingController();
  String _unit  = 'mcg/kg/min';

  @override
  void dispose() {
    _weight.dispose();
    _dose.dispose();
    _drugMg.dispose();
    _bagMl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w   = _n(_weight);
    final d   = _n(_dose);
    final mg  = _n(_drugMg);
    final ml  = _n(_bagMl);
    final ok  = w != null && d != null && mg != null && ml != null &&
        w > 0 && ml > 0 && mg > 0;

    double? mlh;
    double? mcgMin;
    double? concMcgMl;
    if (ok) {
      concMcgMl = (mg * 1000) / ml;                  // mcg/mL في الكيس
      mcgMin = switch (_unit) {
        'mcg/kg/min' => d * w,
        'mcg/kg/hr'  => d * w / 60,
        'mg/kg/hr'   => d * w * 1000 / 60,
        _            => d * w,
      };
      mlh = mcgMin * 60 / concMcgMl;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text(
            'لأدوية التسريب المحسوبة بالوزن (نورإبينفرين، دوبامين، '
            'ميدازولام…): من الجرعة المطلوبة إلى معدل المضخة.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _Num(
            ctrl: _weight,
            label: 'وزن المريض',
            unit: 'kg',
            onChanged: (_) => setState(() {})),
        _Num(
            ctrl: _dose,
            label: 'الجرعة المطلوبة',
            unit: _unit,
            hint: 'مثال: 0.05',
            onChanged: (_) => setState(() {})),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(
            spacing: 8,
            children: [
              for (final u in ['mcg/kg/min', 'mcg/kg/hr', 'mg/kg/hr'])
                ChoiceChip(
                  label: Text(u, style: const TextStyle(fontSize: 11.5)),
                  selected: _unit == u,
                  onSelected: (_) => setState(() => _unit = u),
                ),
            ],
          ),
        ),
        _Num(
            ctrl: _drugMg,
            label: 'كمية الدواء في الكيس',
            unit: 'mg',
            hint: 'مثال: 4',
            onChanged: (_) => setState(() {})),
        _Num(
            ctrl: _bagMl,
            label: 'حجم الكيس',
            unit: 'mL',
            hint: 'مثال: 50',
            onChanged: (_) => setState(() {})),
        if (mlh != null)
          _Result(
            title: 'الضبط',
            rows: [
              ['معدل المضخة', '${_fmt(mlh)} mL/hr'],
              ['تركيز الكيس', '${_fmt(concMcgMl!, 0)} mcg/mL'],
              ['الجرعة الفعلية', '${_fmt(mcgMin!, 1)} mcg/دقيقة'],
            ],
            note: 'تحقّق من التركيز المعتمد في وحدتك — بعض الوحدات تُحضّر '
                'النورإبينفرين 4 mg/250 mL وأخرى 4 mg/50 mL، والفرق في '
                'المعدل خمسة أضعاف.',
          ),
        const _Disclaimer(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4) سوائل الصيانة للأطفال — Holliday-Segar
// ═══════════════════════════════════════════════════════════════════════════════

class _MaintenanceTab extends StatefulWidget {
  const _MaintenanceTab();

  @override
  State<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<_MaintenanceTab> {
  final _weight = TextEditingController();
  int _dehydration = 0; // 0 / 5 / 10 بالمئة

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  /// قاعدة 4-2-1: أول 10 كغم ×4، الـ10 التالية ×2، وما بعدها ×1 mL/kg/hr.
  static double _hourly(double kg) {
    if (kg <= 10) return kg * 4;
    if (kg <= 20) return 40 + (kg - 10) * 2;
    return 60 + (kg - 20) * 1;
  }

  @override
  Widget build(BuildContext context) {
    final w  = _n(_weight);
    final ok = w != null && w > 0;
    final hr = ok ? _hourly(w) : null;
    final deficit = ok ? w * 1000 * _dehydration / 100 : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text('سوائل الصيانة بقاعدة Holliday-Segar (4-2-1)، مع حساب العَوَز '
            'عند وجود تجفاف.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _Num(
            ctrl: _weight,
            label: 'وزن الطفل',
            unit: 'kg',
            hint: 'مثال: 14',
            onChanged: (_) => setState(() {})),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, right: 2),
          child: Text('درجة التجفاف',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final p in [0, 3, 5, 10])
              ChoiceChip(
                label: Text(p == 0 ? 'بلا تجفاف' : '$p٪',
                    style: const TextStyle(fontSize: 12)),
                selected: _dehydration == p,
                onSelected: (_) => setState(() => _dehydration = p),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (hr != null) ...[
          _Result(
            title: 'الصيانة',
            rows: [
              ['المعدل بالساعة', '${_fmt(hr)} mL/hr'],
              ['في 24 ساعة', '${_fmt(hr * 24, 0)} mL'],
            ],
            note: 'المحلول المعتاد للصيانة عند الأطفال: isotonic '
                '(0.9٪ NaCl + 5٪ dextrose) مع البوتاسيوم عند الحاجة — '
                'المحاليل الناقصة التوتّر ترفع خطر نقص الصوديوم.',
          ),
          if (deficit != null && deficit > 0) ...[
            const SizedBox(height: 12),
            _Result(
              title: 'عَوَز السوائل',
              color: AppColors.warningAmber,
              rows: [
                ['العَوَز الكلي', '${_fmt(deficit, 0)} mL'],
                ['نصفه في 8 ساعات', '${_fmt(deficit / 2 / 8, 1)} mL/hr إضافية'],
                ['والنصف في 16 ساعة', '${_fmt(deficit / 2 / 16, 1)} mL/hr إضافية'],
              ],
              note: 'الصدمة تُعالَج أولاً بجرعة bolus 10–20 mL/kg قبل '
                  'حساب العَوَز، ويُعاد تقييم الطفل بعد كل جرعة.',
            ),
          ],
        ],
        const _Disclaimer(),
      ],
    );
  }
}
