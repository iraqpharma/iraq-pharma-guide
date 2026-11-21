import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';

/// حروف ترقيم الخيارات بالعربية.
const _letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

/// «حالة الأسبوع» — حالة سريرية واحدة ثابتة لكل أسبوع.
///
/// تُقرأ من أسئلة النوع `case` في قاعدة التطبيق، والاختيار مشتقّ من رقم
/// الأسبوع، فتبقى الحالة نفسها طوال الأسبوع لكل المستخدمين.
class WeeklyCaseScreen extends StatefulWidget {
  const WeeklyCaseScreen({super.key});

  @override
  State<WeeklyCaseScreen> createState() => _WeeklyCaseScreenState();
}

class _WeeklyCaseScreenState extends State<WeeklyCaseScreen> {
  Map<String, dynamic>? _q;
  List<String> _options = const [];
  int _answer = -1;
  int? _chosen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = DateTime.now();
    final weeks =
        DateTime(n.year, n.month, n.day).difference(DateTime(2020)).inDays ~/ 7;
    final q = await DatabaseHelper.instance.caseOfTheWeek(weeks);
    List<String> opts = const [];
    if (q != null) {
      try {
        final raw = jsonDecode((q['options_json'] ?? '[]').toString());
        opts = (raw as List).map((e) => e.toString()).toList();
      } catch (_) {
        opts = const [];
      }
    }
    if (!mounted) return;
    setState(() {
      _q = q;
      _options = opts;
      _answer = q == null ? -1 : ((q['answer_index'] as num?)?.toInt() ?? 0);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('حالة الأسبوع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_q == null || _options.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text('لا توجد حالة متاحة حالياً',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: [
                    // ── نصّ الحالة ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            const Color(0xFF7A4EA8).withOpacity(0.14),
                            const Color(0xFF7A4EA8).withOpacity(0.04),
                          ],
                        ),
                        border: Border.all(
                            color: const Color(0xFF7A4EA8).withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.assignment_ind_rounded,
                                size: 16, color: Color(0xFF7A4EA8)),
                            const SizedBox(width: 7),
                            const Text('الحالة',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7A4EA8))),
                            const Spacer(),
                            if ((_q!['difficulty'] ?? '').toString().isNotEmpty)
                              Text((_q!['difficulty']).toString(),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                          ]),
                          const SizedBox(height: 10),
                          Text((_q!['question_ar'] ?? '').toString(),
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.85,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                        _chosen == null
                            ? 'اختر قرارك:'
                            : (_chosen == _answer
                                ? 'قرار صحيح'
                                : 'القرار الصحيح مُعلَّم بالأخضر'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _chosen == null
                              ? theme.colorScheme.onSurface
                              : (_chosen == _answer
                                  ? AppColors.successGreen
                                  : AppColors.errorRed),
                        )),
                    const SizedBox(height: 10),

                    for (var i = 0; i < _options.length; i++)
                      _option(i, _options[i]),

                    if (_chosen != null &&
                        (_q!['explain_ar'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 7),
                              Text('الشرح',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ]),
                            const SizedBox(height: 8),
                            Text((_q!['explain_ar']).toString(),
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.8)),
                            if ((_q!['ref_ar'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text('المصدر: ${_q!['ref_ar']}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      height: 1.6,
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _option(int i, String text) {
    final picked  = _chosen == i;
    final correct = _answer == i;
    final shown   = _chosen != null;

    Color border = Theme.of(context).dividerColor.withOpacity(0.5);
    Color? fill;
    if (shown) {
      if (correct) {
        border = AppColors.successGreen;
        fill = AppColors.successGreen.withOpacity(0.08);
      } else if (picked) {
        border = AppColors.errorRed;
        fill = AppColors.errorRed.withOpacity(0.07);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: fill ?? Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: shown ? null : () => setState(() => _chosen = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: shown ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: border.withOpacity(0.15),
                ),
                child: shown && correct
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.successGreen)
                    : (shown && picked
                        ? const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.errorRed)
                        : Text(_letters[i % _letters.length],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13.5, height: 1.6)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
