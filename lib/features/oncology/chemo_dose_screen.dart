import '../../core/l10n/app_strings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import 'chemo_dose_rules.dart';
import '../../shared/widgets/section_intro.dart';

/// حاسبة تخفيض جرعات العلاج الكيميائي.
/// تُدخل القياسات والمختبرات مرة واحدة، فتعطي لكل دواء النسبة الموصى بها
/// وسببها ومصدرها، مع حساب مساحة سطح الجسم ومعادلة Calvert للكاربوبلاتين.
class ChemoDoseScreen extends StatefulWidget {
  const ChemoDoseScreen({super.key});

  @override
  State<ChemoDoseScreen> createState() => _ChemoDoseScreenState();
}

class _ChemoDoseScreenState extends State<ChemoDoseScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age    = TextEditingController();
  final _scr    = TextEditingController();
  final _bili   = TextEditingController();
  final _ast    = TextEditingController();
  final _alp    = TextEditingController();
  final _anc    = TextEditingController();
  final _plt    = TextEditingController();
  final _auc    = TextEditingController(text: '5');

  bool _female = false;
  int  _drugIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'chemo_dose');
    });
  }

  @override
  void dispose() {
    for (final c in [
      _height, _weight, _age, _scr, _bili, _ast, _alp, _anc, _plt, _auc
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c, [double fallback = 0]) =>
      double.tryParse(c.text.trim().replaceAll('٫', '.')) ?? fallback;

  /// Mosteller — الأكثر استعمالاً في بروتوكولات الأورام.
  double get _bsa {
    final h = _n(_height), w = _n(_weight);
    if (h <= 0 || w <= 0) return 0;
    return math.sqrt((h * w) / 3600);
  }

  /// Cockcroft-Gault
  double get _crCl {
    final age = _n(_age), w = _n(_weight), scr = _n(_scr);
    if (age <= 0 || w <= 0 || scr <= 0) return 0;
    final v = ((140 - age) * w) / (72 * scr);
    return _female ? v * 0.85 : v;
  }

  ChemoLabs get _labs => ChemoLabs(
        bilirubin: _n(_bili),
        ast: _n(_ast, 1),
        alp: _n(_alp, 1),
        crCl: _crCl > 0 ? _crCl : 120,
        anc: _n(_anc, 3),
        platelets: _n(_plt, 250),
      );

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final drug = chemoDrugs[_drugIndex];
    final labs = _labs;
    final advice = evaluate(drug, labs);
    final hold   = marrowHold(labs);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cOncology,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text((context.s.isAr ? 'تخفيض جرعات الكيماوي' : 'Chemo Dose Adjustment'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _notice(cs),
          const SizedBox(height: 14),

          _card(cs, (context.s.isAr ? 'المريض' : 'Patient'), Icons.person_outline, [
            Row(children: [
              Expanded(child: _field(_height, (context.s.isAr ? 'الطول (سم)' : 'Height (cm)'))),
              const SizedBox(width: 10),
              Expanded(child: _field(_weight, (context.s.isAr ? 'الوزن (كغم)' : 'Weight (kg)'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_age, (context.s.isAr ? 'العمر (سنة)' : 'Age (years)'))),
              SizedBox(width: 10),
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text((context.s.isAr ? 'ذكر' : 'Male'))),
                    ButtonSegment(value: true, label: Text((context.s.isAr ? 'أنثى' : 'Female'))),
                  ],
                  selected: {_female},
                  onSelectionChanged: (v) =>
                      setState(() => _female = v.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _result((context.s.isAr ? 'مساحة سطح الجسم' : 'Body surface area'),
                    _bsa > 0 ? '${_bsa.toStringAsFixed(2)} m²' : '—',
                    'Mosteller'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _result((context.s.isAr ? 'تصفية الكرياتينين' : 'Creatinine clearance'),
                    _crCl > 0 ? '${_crCl.toStringAsFixed(0)} mL/min' : '—',
                    'Cockcroft-Gault'),
              ),
            ]),
          ]),

          const SizedBox(height: 12),
          _card(cs, (context.s.isAr ? 'المختبرات' : 'Labs'), Icons.science_outlined, [
            Row(children: [
              Expanded(child: _field(_scr, (context.s.isAr ? 'الكرياتينين (mg/dL)' : 'Creatinine (mg/dL)'))),
              const SizedBox(width: 10),
              Expanded(child: _field(_bili, (context.s.isAr ? 'البيليروبين (mg/dL)' : 'Bilirubin (mg/dL)'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_ast, (context.s.isAr ? 'AST/ALT (× الحد الأعلى)' : 'AST/ALT (× ULN)'))),
              const SizedBox(width: 10),
              Expanded(child: _field(_alp, (context.s.isAr ? 'ALP (× الحد الأعلى)' : 'ALP (× ULN)'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_anc, (context.s.isAr ? 'العدلات (×10⁹/L)' : 'Neutrophils (×10⁹/L)'))),
              const SizedBox(width: 10),
              Expanded(child: _field(_plt, (context.s.isAr ? 'الصفيحات (×10⁹/L)' : 'Platelets (×10⁹/L)'))),
            ]),
          ]),

          const SizedBox(height: 12),
          _card(cs, (context.s.isAr ? 'الدواء' : 'Drug'), Icons.medication_outlined, [
            DropdownButtonFormField<int>(
              initialValue: _drugIndex,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                for (var i = 0; i < chemoDrugs.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      '${chemoDrugs[i].name} — ${chemoDrugs[i].nameAr}',
                      style: const TextStyle(fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _drugIndex = v ?? 0),
            ),
            const SizedBox(height: 10),
            Text((context.s.isAr ? 'الجرعة المرجعية: ${drug.standardDose}' : 'Reference dose: ${drug.standardDose}'),
                style: TextStyle(
                    fontSize: 12.5, color: cs.onSurfaceVariant)),
          ]),

          const SizedBox(height: 14),
          if (drug.isCalvert)
            _calvertCard(cs)
          else
            _adviceCard(cs, drug, advice),

          if (hold != null) ...[
            const SizedBox(height: 12),
            _holdCard(hold),
          ],

          const SizedBox(height: 14),
          Text((context.s.isAr ? 'المصدر: ${drug.source}' : 'Source: ${drug.source}'),
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── الواجهات الفرعية ───────────────────────────────────────────────────
  Widget _notice(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.warningAmber.withOpacity(0.35)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFF9A6207), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'أداة مساعدة للقرار. النتيجة لا تُغني عن بروتوكول المركز '
              'العلاجي ولا عن قرار الطبيب المعالج، ولا تشمل التعديل بسبب '
              'السمّية التراكمية أو التداخلات',
              style: TextStyle(
                  fontSize: 12, height: 1.6, color: Color(0xFF7A4E05)),
            ),
          ),
        ]),
      );

  Widget _card(ColorScheme cs, String title, IconData icon,
          List<Widget> children) =>
      Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.cOncology),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.٫]')),
        ],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );

  Widget _result(String label, String value, String note) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cOncology.withOpacity(0.07),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7B))),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cOncology)),
          Text(note,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A8A99))),
        ]),
      );

  Widget _adviceCard(ColorScheme cs, ChemoDrug drug, DoseAdvice a) {
    final pct   = (a.percent * 100).round();
    final color = a.hold
        ? AppColors.errorRed
        : (a.percent < 1 ? AppColors.warningAmber : AppColors.successGreen);
    final bsa   = _bsa;

    String dose = '';
    final m = RegExp(r'(\d+(?:\.\d+)?)(?:–(\d+(?:\.\d+)?))?\s*mg/m²')
        .firstMatch(drug.standardDose);
    if (m != null && bsa > 0 && !a.hold) {
      final lo = double.parse(m.group(1)!) * bsa * a.percent;
      final hi = m.group(2) != null
          ? double.parse(m.group(2)!) * bsa * a.percent
          : null;
      dose = hi == null
          ? '${lo.round()} mg'
          : '${lo.round()}–${hi.round()} mg';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.40), width: 1.4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              a.hold
                  ? Icons.block_rounded
                  : (a.percent < 1
                      ? Icons.trending_down_rounded
                      : Icons.check_circle_outline_rounded),
              color: color,
              size: 22),
          const SizedBox(width: 9),
          Text(a.hold ? (context.s.isAr ? 'يُمنع الإعطاء' : 'Do not give') : (context.s.isAr ? 'الجرعة الموصى بها: $pct٪' : 'Recommended dose: $pct%'),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 10),
        Text(a.reason,
            style: const TextStyle(fontSize: 13.5, height: 1.7)),
        if (dose.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text((context.s.isAr ? 'الجرعة المحسوبة' : 'Calculated dose'),
                  style: TextStyle(fontSize: 12.5)),
              const Spacer(),
              Text(dose,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ]),
          ),
          const SizedBox(height: 6),
          Text('BSA ${bsa.toStringAsFixed(2)} m² × ${drug.standardDose} × $pct٪',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A99))),
        ],
      ]),
    );
  }

  Widget _calvertCard(ColorScheme cs) {
    final gfr = _crCl;
    final auc = _n(_auc, 5);
    final dose = gfr > 0 ? auc * (gfr + 25) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cOncology.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cOncology.withOpacity(0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((context.s.isAr ? 'معادلة Calvert' : 'Calvert formula'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text((context.s.isAr ? 'الجرعة (mg) = AUC × (GFR + 25)' : 'Dose (mg) = AUC × (GFR + 25)'),
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6B7B))),
        const SizedBox(height: 13),
        SizedBox(
          width: 150,
          child: _field(_auc, (context.s.isAr ? 'AUC المستهدف' : 'Target AUC')),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text((context.s.isAr ? 'الجرعة' : 'Dose'), style: TextStyle(fontSize: 13)),
            const Spacer(),
            Text(dose > 0 ? '${dose.round()} mg' : '—',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cOncology)),
          ]),
        ),
        const SizedBox(height: 9),
        const Text(
          'يُستعمل GFR المحسوب بـ Cockcroft-Gault أعلاه. كثير من المراكز '
          'تضع سقفاً لـ GFR عند 125 mL/min لتفادي الجرعات المفرطة',
          style: TextStyle(fontSize: 11.5, height: 1.65, color: Color(0xFF6B6B7B)),
        ),
      ]),
    );
  }

  Widget _holdCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.errorRed.withOpacity(0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.pause_circle_outline_rounded,
              color: AppColors.errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, height: 1.65)),
          ),
        ]),
      );
}
