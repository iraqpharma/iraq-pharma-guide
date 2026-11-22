import '../../core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../services/haptics_service.dart';

/// «تحدّي التداخلات» — زوج أدوية في كل سؤال: هل بينهما تداخل مُدرج؟
///
/// الأزواج تُبنى من نصّ التداخلات في قاعدة التطبيق نفسها، فالسؤال عن
/// «المُدرَج في مصدر التطبيق» لا عن الواقع كلّه — وهذا مذكور للمستخدم
/// صراحةً حتى لا يَبنِي قراراً سريرياً على غياب الذكر.
class InteractionChallengeScreen extends StatefulWidget {
  const InteractionChallengeScreen({super.key});

  @override
  State<InteractionChallengeScreen> createState() =>
      _InteractionChallengeScreenState();
}

class _InteractionChallengeScreenState
    extends State<InteractionChallengeScreen> {
  List<Map<String, dynamic>> _pairs = const [];
  int _index   = 0;
  int _score   = 0;
  int? _chosen;            // 1 = يوجد تداخل ، 0 = لا يوجد
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await DatabaseHelper.instance.interactionPairs(count: 8);
    if (!mounted) return;
    setState(() {
      _pairs   = p;
      _loading = false;
      _index   = 0;
      _score   = 0;
      _chosen  = null;
    });
  }

  void _pick(int v) {
    if (_chosen != null) return;
    final correct = (_pairs[_index]['interacts'] as int) == v;
    if (correct) {
      Haptics.success();
    } else {
      Haptics.error();
    }
    setState(() {
      _chosen = v;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= _pairs.length) {
      setState(() => _index = _pairs.length); // شاشة النتيجة
    } else {
      setState(() {
        _index++;
        _chosen = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text((context.s.isAr ? 'تحدّي التداخلات' : 'Interaction Challenge'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_pairs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text((context.s.isAr ? 'تحدّي التداخلات' : 'Interaction Challenge'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text((context.s.isAr ? 'تعذّر توليد الأزواج، أعد المحاولة' : 'Could not build the pairs, try again'),
                style:
                    TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    // ── شاشة النتيجة ──────────────────────────────────────────────────
    if (_index >= _pairs.length) {
      final pct = (_score / _pairs.length * 100).round();
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text((context.s.isAr ? 'تحدّي التداخلات' : 'Interaction Challenge'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 108,
                height: 108,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (pct >= 70
                          ? AppColors.successGreen
                          : AppColors.warningAmber)
                      .withOpacity(0.12),
                ),
                child: Text('$pct٪',
                    style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: pct >= 70
                            ? AppColors.successGreen
                            : AppColors.warningAmber)),
              ),
              const SizedBox(height: 16),
              Text((context.s.isAr ? '$_score من ${_pairs.length}' : '$_score of ${_pairs.length}'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  pct >= 70
                      ? (context.s.isAr ? 'معرفتك بالتداخلات قوية، واصل' : 'Your interaction knowledge is strong, keep going')
                      : 'التداخلات أكثر ما يُغفل في الصيدلية. أعد المحاولة '
                          'بأزواج جديدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.7,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text((context.s.isAr ? 'أزواج جديدة' : 'New pairs')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    final p        = _pairs[_index];
    final truth    = p['interacts'] as int;
    final answered = _chosen != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text((context.s.isAr ? 'تحدّي التداخلات' : 'Interaction Challenge'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_index + 1) / _pairs.length,
            minHeight: 3,
            backgroundColor: theme.dividerColor.withOpacity(0.2),
            color: const Color(0xFFC2454B),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Text((context.s.isAr ? '${_index + 1} من ${_pairs.length}' : '${_index + 1} of ${_pairs.length}'),
              style: TextStyle(
                  fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),

          // ── الزوج ─────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _drugChip(p['a'].toString())),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC2454B),
                ),
                child: const Icon(Icons.add_rounded,
                    size: 19, color: Colors.white),
              ),
            ),
            Expanded(child: _drugChip(p['b'].toString())),
          ]),

          const SizedBox(height: 20),
          Text((context.s.isAr ? 'هل يوجد تداخل دوائي مُعتبَر بين هذين الدوائين؟' : 'Is there a clinically significant interaction between these two drugs?'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text((context.s.isAr ? 'تداخل يستدعي تنبيه الطبيب أو تعديل الجرعة أو المراقبة' : 'One that calls for alerting the prescriber, adjusting the dose or monitoring'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: _answerBtn(
                  (context.s.isAr ? 'نعم، يوجد تداخل' : 'Yes, they interact'), Icons.warning_amber_rounded, 1, truth),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _answerBtn(
                  (context.s.isAr ? 'لا تداخل مُعتبَر' : 'No significant interaction'), Icons.check_circle_outline_rounded, 0,
                  truth),
            ),
          ]),

          if (answered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 7),
                    Text((context.s.isAr ? 'التفسير' : 'Explanation'),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(p['explain'].toString(),
                      style: const TextStyle(fontSize: 12.5, height: 1.8)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                    _index + 1 >= _pairs.length ? (context.s.isAr ? 'النتيجة' : 'Result') : (context.s.isAr ? 'التالي' : 'Next'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _drugChip(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: const Color(0xFFC2454B).withOpacity(0.22), width: 1.3),
      ),
      child: Text(name,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 3,
          style: const TextStyle(
              fontSize: 13.5, height: 1.4, fontWeight: FontWeight.bold)),
    );
  }

  Widget _answerBtn(String label, IconData icon, int value, int truth) {
    final answered = _chosen != null;
    final picked   = _chosen == value;
    final isTruth  = truth == value;

    Color border = Theme.of(context).dividerColor.withOpacity(0.5);
    Color? fill;
    Color fg = Theme.of(context).colorScheme.onSurface;
    if (answered) {
      if (isTruth) {
        border = AppColors.successGreen;
        fill = AppColors.successGreen.withOpacity(0.10);
        fg = AppColors.successGreen;
      } else if (picked) {
        border = AppColors.errorRed;
        fill = AppColors.errorRed.withOpacity(0.08);
        fg = AppColors.errorRed;
      }
    }

    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: answered ? null : () => _pick(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: answered ? 1.5 : 1),
          ),
          child: Column(children: [
            Icon(icon, size: 21, color: fg),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.bold, color: fg)),
          ]),
        ),
      ),
    );
  }
}
