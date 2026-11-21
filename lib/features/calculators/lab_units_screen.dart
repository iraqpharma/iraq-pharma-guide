import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

/// محوّل الوحدات المختبرية.
///
/// مختبرات العراق تخلط بين الوحدات التقليدية والوحدات الدولية، والنتيجة
/// نفسها تُكتب ملغم/دل في مختبر وملمول/ل في آخر. هذا المحوّل ينقل بين
/// الاتجاهين مع المدى الطبيعي المرجعي.
class Analyte {
  final String name;      // الاسم الإنكليزي
  final String nameAr;    // الاسم العربي
  final String group;
  final String convUnit;  // الوحدة التقليدية
  final String siUnit;    // الوحدة الدولية
  final double factor;    // تقليدية × factor = دولية
  final double offset;    // للحالات غير الخطّية مثل HbA1c
  final String? normal;   // المدى الطبيعي بالوحدة التقليدية

  const Analyte(
    this.name,
    this.nameAr,
    this.group,
    this.convUnit,
    this.siUnit,
    this.factor, {
    this.offset = 0,
    this.normal,
  });
}

const kAnalytes = <Analyte>[
  // ── الكيمياء العامة ─────────────────────────────────────────────
  Analyte('Glucose', 'سكر الدم', 'الكيمياء العامة', 'mg/dL', 'mmol/L', 0.0555,
      normal: '70 – 100 صائم'),
  Analyte('HbA1c', 'السكر التراكمي', 'الكيمياء العامة', '%', 'mmol/mol',
      10.929,
      offset: -23.5, normal: 'أقل من 5.7'),
  Analyte('Creatinine', 'الكرياتينين', 'الكيمياء العامة', 'mg/dL', 'µmol/L',
      88.4,
      normal: '0.6 – 1.3'),
  Analyte('Urea', 'اليوريا', 'الكيمياء العامة', 'mg/dL', 'mmol/L', 0.1665,
      normal: '15 – 45'),
  Analyte('BUN', 'نيتروجين اليوريا', 'الكيمياء العامة', 'mg/dL', 'mmol/L',
      0.357,
      normal: '7 – 20'),
  Analyte('Uric acid', 'حامض اليوريك', 'الكيمياء العامة', 'mg/dL', 'µmol/L',
      59.48,
      normal: '3.5 – 7.2'),
  Analyte('Total bilirubin', 'البيليروبين الكلّي', 'الكيمياء العامة',
      'mg/dL', 'µmol/L', 17.1,
      normal: '0.2 – 1.2'),
  Analyte('Total protein', 'البروتين الكلّي', 'الكيمياء العامة', 'g/dL',
      'g/L', 10,
      normal: '6.4 – 8.3'),
  Analyte('Albumin', 'الألبومين', 'الكيمياء العامة', 'g/dL', 'g/L', 10,
      normal: '3.5 – 5.0'),
  Analyte('CRP', 'بروتين سي التفاعلي', 'الكيمياء العامة', 'mg/dL', 'mg/L', 10,
      normal: 'أقل من 0.5'),
  Analyte('Lactate', 'اللاكتات', 'الكيمياء العامة', 'mg/dL', 'mmol/L', 0.111,
      normal: '4.5 – 19.8'),
  Analyte('Ammonia', 'الأمونيا', 'الكيمياء العامة', 'µg/dL', 'µmol/L', 0.587,
      normal: '15 – 45'),

  // ── الشحوم ─────────────────────────────────────────────────────
  Analyte('Total cholesterol', 'الكوليسترول الكلّي', 'الشحوم', 'mg/dL',
      'mmol/L', 0.0259,
      normal: 'أقل من 200'),
  Analyte('LDL cholesterol', 'الكوليسترول الضار', 'الشحوم', 'mg/dL',
      'mmol/L', 0.0259,
      normal: 'أقل من 100'),
  Analyte('HDL cholesterol', 'الكوليسترول النافع', 'الشحوم', 'mg/dL',
      'mmol/L', 0.0259,
      normal: 'أكثر من 40'),
  Analyte('Triglycerides', 'الدهون الثلاثية', 'الشحوم', 'mg/dL', 'mmol/L',
      0.0113,
      normal: 'أقل من 150'),

  // ── الشوارد والمعادن ──────────────────────────────────────────
  Analyte('Sodium', 'الصوديوم', 'الشوارد والمعادن', 'mEq/L', 'mmol/L', 1,
      normal: '135 – 145'),
  Analyte('Potassium', 'البوتاسيوم', 'الشوارد والمعادن', 'mEq/L', 'mmol/L', 1,
      normal: '3.5 – 5.1'),
  Analyte('Chloride', 'الكلورايد', 'الشوارد والمعادن', 'mEq/L', 'mmol/L', 1,
      normal: '98 – 107'),
  Analyte('Calcium total', 'الكالسيوم الكلّي', 'الشوارد والمعادن', 'mg/dL',
      'mmol/L', 0.25,
      normal: '8.6 – 10.3'),
  Analyte('Magnesium', 'المغنيسيوم', 'الشوارد والمعادن', 'mg/dL', 'mmol/L',
      0.411,
      normal: '1.7 – 2.4'),
  Analyte('Phosphate', 'الفوسفات', 'الشوارد والمعادن', 'mg/dL', 'mmol/L',
      0.323,
      normal: '2.5 – 4.5'),

  // ── الدم والفيتامينات ─────────────────────────────────────────
  Analyte('Hemoglobin', 'الهيموغلوبين', 'الدم والفيتامينات', 'g/dL', 'g/L',
      10,
      normal: '12 – 16 أنثى  ·  13.5 – 17.5 ذكر'),
  Analyte('Iron', 'الحديد', 'الدم والفيتامينات', 'µg/dL', 'µmol/L', 0.179,
      normal: '60 – 170'),
  Analyte('Ferritin', 'الفيرّيتين', 'الدم والفيتامينات', 'ng/mL', 'pmol/L',
      2.247,
      normal: '30 – 300'),
  Analyte('Vitamin B12', 'فيتامين ب12', 'الدم والفيتامينات', 'pg/mL',
      'pmol/L', 0.738,
      normal: '200 – 900'),
  Analyte('Vitamin D 25-OH', 'فيتامين د', 'الدم والفيتامينات', 'ng/mL',
      'nmol/L', 2.496,
      normal: '30 – 100'),
  Analyte('Folate', 'حامض الفوليك', 'الدم والفيتامينات', 'ng/mL', 'nmol/L',
      2.266,
      normal: '3 – 17'),

  // ── الهرمونات ────────────────────────────────────────────────
  Analyte('Cortisol', 'الكورتيزول', 'الهرمونات', 'µg/dL', 'nmol/L', 27.59,
      normal: '5 – 23 صباحاً'),
  Analyte('Testosterone', 'التستوستيرون', 'الهرمونات', 'ng/dL', 'nmol/L',
      0.0347,
      normal: '300 – 1000 ذكر'),
  Analyte('Thyroxine T4 total', 'الثايروكسين الكلّي', 'الهرمونات', 'µg/dL',
      'nmol/L', 12.87,
      normal: '4.5 – 12'),
  Analyte('Triiodothyronine T3', 'ثلاثي يودوثيرونين', 'الهرمونات', 'ng/dL',
      'nmol/L', 0.0154,
      normal: '80 – 200'),

  // ── مستويات الأدوية ──────────────────────────────────────────
  Analyte('Digoxin', 'الديجوكسين', 'مستويات الأدوية', 'ng/mL', 'nmol/L',
      1.281,
      normal: '0.5 – 2.0 علاجي'),
  Analyte('Phenytoin', 'الفينيتوين', 'مستويات الأدوية', 'µg/mL', 'µmol/L',
      3.96,
      normal: '10 – 20 علاجي'),
  Analyte('Carbamazepine', 'الكاربامازيبين', 'مستويات الأدوية', 'µg/mL',
      'µmol/L', 4.23,
      normal: '4 – 12 علاجي'),
  Analyte('Valproic acid', 'حامض الفالبروييك', 'مستويات الأدوية', 'µg/mL',
      'µmol/L', 6.93,
      normal: '50 – 100 علاجي'),
  Analyte('Theophylline', 'الثيوفيلين', 'مستويات الأدوية', 'µg/mL', 'µmol/L',
      5.55,
      normal: '10 – 20 علاجي'),
  Analyte('Lithium', 'الليثيوم', 'مستويات الأدوية', 'mEq/L', 'mmol/L', 1,
      normal: '0.6 – 1.2 علاجي'),
  Analyte('Vancomycin', 'الفانكومايسين', 'مستويات الأدوية', 'µg/mL',
      'µmol/L', 0.69,
      normal: '10 – 20 قبل الجرعة'),
  Analyte('Gentamicin', 'الجنتامايسين', 'مستويات الأدوية', 'µg/mL', 'µmol/L',
      2.09,
      normal: 'أقل من 2 قبل الجرعة'),
  Analyte('Paracetamol', 'الباراسيتامول', 'مستويات الأدوية', 'µg/mL',
      'µmol/L', 6.62,
      normal: 'سُمّي فوق 150 بعد 4 ساعات'),
  Analyte('Salicylate', 'الساليسيلات', 'مستويات الأدوية', 'mg/dL', 'mmol/L',
      0.0724,
      normal: 'سُمّي فوق 30'),
];

class LabUnitsScreen extends StatefulWidget {
  const LabUnitsScreen({super.key});

  @override
  State<LabUnitsScreen> createState() => _LabUnitsScreenState();
}

class _LabUnitsScreenState extends State<LabUnitsScreen> {
  final _search = TextEditingController();
  final _value  = TextEditingController();
  Analyte? _sel;
  bool _convToSi = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'lab_units');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _value.dispose();
    super.dispose();
  }

  String? get _out {
    final a = _sel;
    final v = double.tryParse(_value.text.trim());
    if (a == null || v == null) return null;
    final r = _convToSi
        ? v * a.factor + a.offset
        : (v - a.offset) / a.factor;
    if (r.abs() >= 100) return r.toStringAsFixed(0);
    if (r.abs() >= 10)  return r.toStringAsFixed(1);
    if (r.abs() >= 1)   return r.toStringAsFixed(2);
    return r.toStringAsFixed(3);
  }

  List<Analyte> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return kAnalytes;
    return kAnalytes
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.nameAr.contains(q) ||
            a.group.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final list   = _filtered;

    final groups = <String, List<Analyte>>{};
    for (final a in list) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('محوّل الوحدات المختبرية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن تحليل بالعربية أو الإنكليزية',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
        if (_sel != null) _converter(_sel!, isDark),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text('لا توجد نتائج',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
                  children: [
                    for (final g in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 7),
                        child: Text(g.key,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ),
                      for (final a in g.value) _tile(a, isDark),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _tile(Analyte a, bool isDark) {
    final theme = Theme.of(context);
    final sel   = _sel?.name == a.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: sel
                ? AppColors.primary.withOpacity(0.45)
                : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFECEFF2))),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Haptics.tap();
            setState(() {
              _sel = a;
              _value.clear();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(a.nameAr,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('${a.convUnit}  ⇄  ${a.siUnit}',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _converter(Analyte a, bool isDark) {
    final theme = Theme.of(context);
    final from  = _convToSi ? a.convUnit : a.siUnit;
    final to    = _convToSi ? a.siUnit : a.convUnit;
    final out   = _out;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${a.name}  ·  ${a.nameAr}',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: () => setState(() => _sel = null),
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _value,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: from,
                  labelStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  filled: true,
                  fillColor:
                      isDark ? theme.colorScheme.surface : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Haptics.select();
                setState(() => _convToSi = !_convToSi);
              },
              icon: const Icon(Icons.swap_horiz_rounded,
                  size: 22, color: AppColors.primary),
              tooltip: 'اعكس الاتجاه',
            ),
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.35)),
                ),
                child: Row(children: [
                  Text(to,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text(out ?? '—',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ]),
              ),
            ),
          ]),
          if (a.normal != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.straighten_rounded,
                  size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 7),
              Expanded(
                child: Text('المدى الطبيعي: ${a.normal} ${a.convUnit}',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ]),
          ],
          if (a.name == 'HbA1c') ...[
            const SizedBox(height: 8),
            Text(
                'يعتمد التحويل معادلة IFCC المعتمدة عالمياً بين النسبة '
                'المئوية و ملمول/مول',
                style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
