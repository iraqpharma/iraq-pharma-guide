import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';

/// «دواء اليوم» — دواء واحد كل يوم مع ما يجب أن يُقال للمريض عنه.
///
/// الاختيار ثابت لكل يوم (مشتقّ من التاريخ) فكل المستخدمين يرون الدواء
/// نفسه، ويُفضَّل المتوفّر في السوق العراقية حتى تكون الفائدة عملية.
class DrugOfDayScreen extends StatefulWidget {
  const DrugOfDayScreen({super.key});

  @override
  State<DrugOfDayScreen> createState() => _DrugOfDayScreenState();
}

class _DrugOfDayScreenState extends State<DrugOfDayScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = DateTime.now();
    // بذرة ثابتة لليوم: عدد الأيام من بداية 2020.
    final seed =
        DateTime(n.year, n.month, n.day).difference(DateTime(2020)).inDays;
    final d = await DatabaseHelper.instance.drugOfTheDay(seed);
    if (!mounted) return;
    setState(() {
      _d = d;
      _loading = false;
    });
  }

  String _s(String key) => (_d?[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('دواء اليوم',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _d == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text('تعذّر اختيار دواء اليوم',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: [
                    // ── الترويسة ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF2F6FB8), Color(0xFF3A72B8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white70, size: 15),
                            const SizedBox(width: 6),
                            Text('اختيار اليوم',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 9),
                          Text(_s('generic_name'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold)),
                          if (_s('generic_name_ar').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(_s('generic_name_ar'),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.88),
                                    fontSize: 14)),
                          ],
                          if (_s('pharmacological_class').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(_s('pharmacological_class'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── النصيحة الصيدلانية — جوهر النشاط ────────────────
                    if (_s('counseling_note_ar').isNotEmpty)
                      _block(
                        'ما تقوله للمريض',
                        Icons.record_voice_over_rounded,
                        AppColors.primary,
                        _s('counseling_note_ar'),
                      ),

                    if (_s('indications_ar').isNotEmpty)
                      _block('الاستعمالات', Icons.check_circle_outline_rounded,
                          const Color(0xFF2E8F63), _s('indications_ar')),

                    if (_s('adult_dosage_ar').isNotEmpty)
                      _block('جرعة البالغين', Icons.straighten_rounded,
                          const Color(0xFF3F93A8), _s('adult_dosage_ar')),

                    if (_s('side_effects_ar').isNotEmpty)
                      _block('الأعراض الجانبية', Icons.warning_amber_rounded,
                          AppColors.warningAmber, _s('side_effects_ar')),

                    if (_s('iraq_market_note_ar').isNotEmpty)
                      _block('في السوق العراقية', Icons.store_rounded,
                          const Color(0xFF9A6B4F), _s('iraq_market_note_ar')),

                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/drug/${_d!['id']}'),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('المونوغراف الكامل',
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _block(String title, IconData icon, Color color, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 12.5, height: 1.75)),
      ]),
    );
  }
}
