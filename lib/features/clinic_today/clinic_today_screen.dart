import '../../core/l10n/app_strings.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import 'quiz_shuffle.dart';
import '../../services/haptics_service.dart';

/// «عيادتك اليوم» — خمسة أسئلة سريرية يومياً، تعمل بلا إنترنت.
///
/// الأسئلة مضمَّنة في قاعدة التطبيق (جدول `quiz_questions`)، والسِّلسِلة
/// محفوظة محلياً. أسئلة اليوم ثابتة: تُختار مرة واحدة وتبقى حتى منتصف الليل.
class ClinicTodayScreen extends StatefulWidget {
  const ClinicTodayScreen({super.key});

  @override
  State<ClinicTodayScreen> createState() => _ClinicTodayScreenState();
}

class _ClinicTodayScreenState extends State<ClinicTodayScreen> {
  static const _kDate = 'clinic_date';
  static const _kQids = 'clinic_qids';
  static const _kStreak = 'clinic_streak';
  static const _kBest = 'clinic_best';
  static const _kLast = 'clinic_last_played';

  List<Map<String, dynamic>> _questions = const [];
  int _index = 0;
  int? _chosen;
  int _score = 0;
  bool _loading = true;
  bool _finished = false;
  int _streak = 0;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt(_kStreak) ?? 0;
    _best = prefs.getInt(_kBest) ?? 0;

    final db = DatabaseHelper.instance;
    List<Map<String, dynamic>> qs = const [];

    // أسئلة اليوم ثابتة: إن كانت محفوظة لليوم نفسه نُعيد تحميلها بأعيانها
    final savedDate = prefs.getString(_kDate);
    final savedQids = prefs.getStringList(_kQids);
    if (savedDate == _todayKey && savedQids != null && savedQids.isNotEmpty) {
      qs = await db.quizByIds(savedQids);
    }
    if (qs.isEmpty) {
      // بذرة اليوم: عدد الأيام منذ 2020 — ثابتة لكل المستخدمين
      final n = DateTime.now();
      final daySeed =
          DateTime(n.year, n.month, n.day).difference(DateTime(2020)).inDays;
      qs = await db.dailyQuiz(count: 5, daySeed: daySeed);
      await prefs.setString(_kDate, _todayKey);
      await prefs.setStringList(
          _kQids, qs.map((e) => (e['qid'] ?? '').toString()).toList());
    }

    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loading = false;
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLast);
    if (last != _todayKey) {
      final y = DateTime.now().subtract(const Duration(days: 1));
      final yKey = '${y.year}-${y.month.toString().padLeft(2, '0')}-'
          '${y.day.toString().padLeft(2, '0')}';
      _streak = (last == yKey) ? _streak + 1 : 1;
      _best = _streak > _best ? _streak : _best;
      await prefs.setInt(_kStreak, _streak);
      await prefs.setInt(_kBest, _best);
      await prefs.setString(_kLast, _todayKey);
    }
    if (mounted) setState(() => _finished = true);
  }

  void _pick(int i, int answer) {
    if (_chosen != null) return;
    // الردّ اللمسي يسبق إعادة الرسم كي يصل مع الضغطة لا بعدها
    if (i == answer) {
      Haptics.success();
    } else {
      Haptics.error();
    }
    setState(() {
      _chosen = i;
      if (i == answer) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _finish();
    } else {
      setState(() {
        _index++;
        _chosen = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((context.s.isAr ? 'أسئلة اليوم' : 'Today\'s Questions'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.local_fire_department,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('$_streak',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const _NoQuestions()
              : _finished
                  ? _Result(
                      score: _score,
                      total: _questions.length,
                      streak: _streak,
                      best: _best,
                    )
                  : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    final raw = (jsonDecode((q['options_json'] ?? '[]').toString()) as List)
        .map((e) => e.toString())
        .toList();
    // خلط ثابت: يزيل انحياز موقع الإجابة الصحيحة في بيانات الأسئلة.
    final sh = shuffleOptions(
      (q['qid'] ?? '').toString(),
      raw,
      (q['answer_index'] as num?)?.toInt() ?? 0,
    );
    final options = sh.options;
    final answer = sh.answer;
    final theme = Theme.of(context);

    return Column(children: [
      LinearProgressIndicator(
        value: (_index + 1) / _questions.length,
        minHeight: 4,
        backgroundColor: theme.dividerColor.withOpacity(0.2),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text((context.s.isAr ? 'السؤال ${_index + 1} من ${_questions.length}' : 'Question ${_index + 1} of ${_questions.length}'),
                style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: theme.dividerColor.withOpacity(0.4)),
              ),
              child: Text((q['question_ar'] ?? '').toString(),
                  style: const TextStyle(
                      fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < options.length; i++)
              _OptionTile(
                text: options[i],
                state: _chosen == null
                    ? _OptState.idle
                    : (i == answer
                        ? _OptState.correct
                        : (i == _chosen ? _OptState.wrong : _OptState.idle)),
                onTap: () => _pick(i, answer),
              ),
            if (_chosen != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_chosen == answer
                          ? AppColors.successGreen
                          : AppColors.errorRed)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(
                            _chosen == answer
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 19,
                            color: _chosen == answer
                                ? AppColors.successGreen
                                : AppColors.errorRed),
                        const SizedBox(width: 7),
                        Text(_chosen == answer ? (context.s.isAr ? 'إجابة صحيحة' : 'Correct') : (context.s.isAr ? 'إجابة خاطئة' : 'Incorrect'),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _chosen == answer
                                    ? AppColors.successGreen
                                    : AppColors.errorRed)),
                      ]),
                      const SizedBox(height: 8),
                      Text((q['explain_ar'] ?? '').toString(),
                          style: const TextStyle(fontSize: 13.5, height: 1.6)),
                      if ((q['ref_ar'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('المصدر: ${q['ref_ar']}',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ]),
              ),
              const SizedBox(height: 16),
              // ارتفاع ثابت 48 كان يقصّ نزول حرف «ي» في الخط العربي.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _index + 1 >= _questions.length ? (context.s.isAr ? 'إنهاء' : 'Finish') : (context.s.isAr ? 'السؤال التالي' : 'Next question'),
                    style: const TextStyle(
                        fontSize: 15, height: 1.6, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}

enum _OptState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String text;
  final _OptState state;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg = theme.colorScheme.surface;
    Color border = theme.dividerColor.withOpacity(0.5);
    Color fg = theme.colorScheme.onSurface;
    IconData? icon;

    if (state == _OptState.correct) {
      bg = AppColors.successGreen.withOpacity(0.14);
      border = AppColors.successGreen;
      fg = AppColors.successGreen;
      icon = Icons.check_circle;
    } else if (state == _OptState.wrong) {
      bg = AppColors.errorRed.withOpacity(0.12);
      border = AppColors.errorRed;
      fg = AppColors.errorRed;
      icon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: state == _OptState.idle ? 1 : 1.6),
          ),
          child: Row(children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: fg,
                      fontWeight: state == _OptState.idle
                          ? FontWeight.normal
                          : FontWeight.bold)),
            ),
            if (icon != null) Icon(icon, color: fg, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final int score;
  final int total;
  final int streak;
  final int best;
  const _Result(
      {required this.score,
      required this.total,
      required this.streak,
      required this.best});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    final good = pct >= 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (good ? AppColors.successGreen : AppColors.warningAmber)
                  .withOpacity(0.12),
            ),
            child: Center(
              child: Text('$score / $total',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: good
                          ? AppColors.successGreen
                          : AppColors.warningAmber)),
            ),
          ),
          const SizedBox(height: 18),
          Text(good ? (context.s.isAr ? 'أحسنت!' : 'Well done!') : (context.s.isAr ? 'راجع ما فاتك' : 'Review what you missed'),
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            good
                ? (context.s.isAr ? 'عُد غداً لخمسة أسئلة جديدة' : 'Come back tomorrow for five new questions')
                : (context.s.isAr ? 'اقرأ الشروح أعلاه، وعُد غداً لأسئلة جديدة' : 'Read the explanations above and come back tomorrow'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Stat(Icons.local_fire_department, '$streak', (context.s.isAr ? 'سلسلة الأيام' : 'Day streak')),
            const SizedBox(width: 26),
            _Stat(Icons.emoji_events_outlined, '$best', (context.s.isAr ? 'أفضل سلسلة' : 'Best streak')),
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 5),
        Text(value,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]);
}

class _NoQuestions extends StatelessWidget {
  const _NoQuestions();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.quiz_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text((context.s.isAr ? 'لا توجد أسئلة في هذه النسخة' : 'No questions in this version'),
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text((context.s.isAr ? 'حدّث التطبيق للحصول على بنك الأسئلة' : 'Update the app to get the question bank'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
          ]),
        ),
      );
}
