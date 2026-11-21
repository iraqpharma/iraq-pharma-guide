import 'package:flutter/material.dart';

import '../../../data/models/drug_model.dart';

/// شارات السلامة والتخزين — الإصدار 3.0
class SafetyBadges extends StatelessWidget {
  final Drug drug;
  const SafetyBadges({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (drug.isVesicant)
        const _Badge('مُقرِّح، خطر تنخّر عند التسرّب',
            Icons.warning_amber_rounded, Color(0xFFAE2E24)),
      if (drug.lightProtection)
        const _Badge('يُحفظ بعيداً عن الضوء',
            Icons.light_mode_outlined, Color(0xFFA9761F)),
      if (drug.isRefrigerated)
        const _Badge('يُحفظ مبرّداً 2-8°م', Icons.ac_unit, Color(0xFF0F6B4F)),
      if (drug.isOncology)
        const _Badge('دواء أورام', Icons.bloodtype_outlined, Color(0xFF7B1FA2)),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// بطاقة تعليمات تحضير الأدوية (الكيماوي والحقن) — الإصدار 3.0
///
/// قاعدة سلامة: لا تُعرض البطاقة إن لم توجد بيانات تحضير فعلية.
class PreparationCard extends StatelessWidget {
  final Drug drug;
  const PreparationCard({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['المُحلّل', drug.reconstitutionDiluent],
      ['حجم الحلّ', drug.reconstitutionVolume],
      ['سائل التمديد النهائي', drug.finalDilutionFluid],
      ['الحجم النهائي', drug.finalVolume],
      ['زمن التسريب', drug.infusionTime],
      ['الثبات بعد التحضير', drug.stabilityAfterPrep],
    ]
        .where((e) =>
            e[1].trim().isNotEmpty &&
            e[1].trim() != 'لا ينطبق' &&
            e[1].trim() != 'Not applicable')
        .toList();

    if (rows.isEmpty &&
        drug.ppeRequired.isEmpty &&
        drug.preparationNotesAr.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Icon(Icons.science_outlined, size: 20, color: Color(0xFF0F6B4F)),
            SizedBox(width: 8),
            Text('تعليمات التحضير',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        ),
        if (drug.isVesicant) const _VesicantBanner(),
        ...rows.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 128,
                        child: Text(e[0],
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant))),
                    Expanded(
                        child: Text(e[1],
                            style: const TextStyle(fontSize: 13.5))),
                  ]),
            )),
        if (drug.ppeRequired.isNotEmpty)
          _Block('الوقاية الشخصية', drug.ppeRequired, Icons.masks_outlined),
        if (drug.preparationNotesAr.isNotEmpty)
          _Block('ملاحظات التحضير', drug.preparationNotesAr,
              Icons.info_outline_rounded),
        const SizedBox(height: 10),
      ]),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _Block(this.title, this.body, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
        ]),
      );
}

class _VesicantBanner extends StatelessWidget {
  const _VesicantBanner();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFAE2E24), size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'دواء مُقرِّح (vesicant): التسرّب خارج الوريد يُسبّب تنخّراً'
                      'أوقف التسريب فوراً ولا تنزع القنية، واسحب ما أمكن من الدواء'
                      'ثم طبّق بروتوكول التسرّب والترياق المذكور أدناه',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Color(0xFFAE2E24)))),
            ]),
      );
}

/// مصدر الدواء كما هو مسجّل في قاعدة 3.0 — نص حقيقي لا زر فارغ.
class DrugSourceCard extends StatelessWidget {
  final Drug drug;
  const DrugSourceCard({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    if (drug.referenceDisplayAr.isEmpty && drug.sourcePrimary.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dividerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.menu_book_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          const Text('المصدر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 6),
        if (drug.referenceDisplayAr.isNotEmpty)
          Text(drug.referenceDisplayAr,
              style: const TextStyle(fontSize: 12.5, height: 1.6)),
        if (drug.sourceCitation.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(drug.sourceCitation,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 6),
        Text('مراجعة وصياغة سريرية: د. حميد عدنان حميد',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
