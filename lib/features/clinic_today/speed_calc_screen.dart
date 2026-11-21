import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../services/haptics_service.dart';

/// سؤال حساب سريع مولَّد عشوائياً.
class _Q {
  final String text;
  final double answer;
  final String unit;
  final String explain;
  const _Q(this.text, this.answer, this.unit, this.explain);
}

/// «الحاسبة السريعة» — عشر حسابات صيدلانية بوقت محدود، ثم لوحة
/// المتصدّرين.
///
/// الأسئلة تُولَّد عشوائياً بأرقام مختلفة كل مرّة، فلا تُحفظ أجوبتها،
/// والمهارة المدرَّبة هي الحساب الذهني الذي يُحتاج فعلاً خلف الكاونتر.
class SpeedCalcScreen extends StatefulWidget {
  const SpeedCalcScreen({super.key});

  @override
  State<SpeedCalcScreen> createState() => _SpeedCalcScreenState();
}

class _SpeedCalcScreenState extends State<SpeedCalcScreen> {
  static const _kBest = 'speed_calc_best';
  static const _total = 10;
  static const _seconds = 120;

  final _rnd  = Random();
  final _ctrl = TextEditingController();

  List<_Q> _qs = const [];
  int _index    = 0;
  int _correct  = 0;
  int _left     = _seconds;
  int _best     = 0;
  bool _started = false;
  bool _done    = false;
  bool? _lastOk;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _best = p.getInt(_kBest) ?? 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ── توليد الأسئلة ──────────────────────────────────────────────────────
  _Q _gen() {
    switch (_rnd.nextInt(5)) {
      case 0: // جرعة بالوزن
        final kg = 4 + _rnd.nextInt(57);
        final mgkg = [5, 10, 15, 20, 25][_rnd.nextInt(5)];
        return _Q(
          'طفل وزنه $kg kg، والجرعة $mgkg mg/kg\nكم الجرعة الكلية؟',
          (kg * mgkg).toDouble(),
          'mg',
          '$kg × $mgkg = ${kg * mgkg} mg',
        );
      case 1: // حجم من شراب
        final mgPer5 = [125, 250, 100, 200][_rnd.nextInt(4)];
        // نصف جرعة أو جرعة أو جرعة ونصف أو جرعتان — أرقام يُصادفها
        // الصيدلاني فعلاً لا كسور غريبة.
        final mult = [0.5, 1, 1.5, 2, 3][_rnd.nextInt(5)];
        final dose = (mgPer5 * mult).round();
        return _Q(
          'الشراب $mgPer5 mg / 5 mL، والمطلوب $dose mg\nكم مِلّيلتراً تُعطي؟',
          dose * 5 / mgPer5,
          'mL',
          '($dose ÷ $mgPer5) × 5 = ${_fmt(dose * 5 / mgPer5)} mL',
        );
      case 2: // معدل التسريب
        final vol = [250, 500, 1000][_rnd.nextInt(3)];
        final hrs = [2, 4, 5, 8, 10][_rnd.nextInt(5)];
        return _Q(
          'كيس $vol mL يُسرَّب على $hrs ساعات\nكم mL/hr؟',
          vol / hrs,
          'mL/hr',
          '$vol ÷ $hrs = ${_fmt(vol / hrs)} mL/hr',
        );
      case 3: // قطرات في الدقيقة
        final mlh = [50, 75, 100, 125, 150][_rnd.nextInt(5)];
        const gtt = 20;
        return _Q(
          'المعدل $mlh mL/hr ومعامل القطرة $gtt gtt/mL\nكم قطرة في الدقيقة؟',
          mlh * gtt / 60,
          'قطرة/د',
          '($mlh × $gtt) ÷ 60 = ${_fmt(mlh * gtt / 60)} قطرة/دقيقة',
        );
      default: // تخفيف
        final c1 = [10, 20, 50, 100][_rnd.nextInt(4)];
        final c2 = [1, 2, 5][_rnd.nextInt(3)];
        final v2 = [50, 100, 250][_rnd.nextInt(3)];
        return _Q(
          'عيار $c1 mg/mL، والمطلوب $c2 mg/mL بحجم $v2 mL\n'
              'كم مِلّيلتراً تسحب من العيار؟',
          c2 * v2 / c1,
          'mL',
          '($c2 × $v2) ÷ $c1 = ${_fmt(c2 * v2 / c1)} mL',
        );
    }
  }

  static String _fmt(num v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  void _start() {
    setState(() {
      _qs      = List.generate(_total, (_) => _gen());
      _index   = 0;
      _correct = 0;
      _left    = _seconds;
      _started = true;
      _done    = false;
      _lastOk  = null;
      _ctrl.clear();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        _finish();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _submit() {
    if (_done) return;
    final given = double.tryParse(
        _ctrl.text.trim().replaceAll('٫', '.').replaceAll(',', ''));
    final want = _qs[_index].answer;
    // هامش 2٪ أو 0.1 — الحساب الذهني لا يُطالَب بدقّة أربع منازل.
    final ok = given != null &&
        (given - want).abs() <= max(0.1, want.abs() * 0.02);
    if (ok) {
      Haptics.success();
    } else {
      Haptics.error();
    }
    setState(() {
      _lastOk = ok;
      if (ok) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _done) return;
      if (_index + 1 >= _qs.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _ctrl.clear();
          _lastOk = null;
        });
      }
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    Haptics.celebrate();
    // النقاط: 100 لكل جواب صحيح + 5 لكل ثانية متبقّية.
    final score = _correct * 100 + _left * 5;
    final p = await SharedPreferences.getInstance();
    if (score > (p.getInt(_kBest) ?? 0)) {
      await p.setInt(_kBest, score);
    }
    // النشر للوحة المتصدّرين لا يُعطّل النتيجة إن فشل الاتصال.
    _publish(score);
    if (!mounted) return;
    setState(() {
      _done = true;
      _started = false;
      _best = max(_best, score);
    });
  }

  Future<void> _publish(int score) async {
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;
      String name = '';
      try {
        final rows = await db
            .from('profiles')
            .select('full_name, username')
            .eq('id', uid)
            .limit(1);
        if (rows.isNotEmpty) {
          final r = rows.first as Map<String, dynamic>;
          name = (r['full_name'] ?? '').toString().trim();
          if (name.isEmpty) name = (r['username'] ?? '').toString();
        }
      } catch (_) {/* الاسم ليس حرجاً */}
      await db.from('speed_scores').insert({
        'user_id': uid,
        'display_name': name,
        'score': score,
        'correct': _correct,
        'total': _total,
      });
    } catch (_) {/* بلا إنترنت — النتيجة محفوظة محلياً */}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الحاسبة السريعة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_started)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: (_left <= 20
                            ? AppColors.errorRed
                            : AppColors.primary)
                        .withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_left ث',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _left <= 20
                              ? AppColors.errorRed
                              : AppColors.primary)),
                ),
              ),
            ),
        ],
      ),
      body: !_started ? _intro() : _game(),
    );
  }

  // ── شاشة البداية / النتيجة ─────────────────────────────────────────────
  Widget _intro() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        if (_done) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFB8762A), Color(0xFFD08A3E)],
              ),
            ),
            child: Column(children: [
              Text('${_correct * 100 + _left * 5}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold)),
              Text('نقطة',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12)),
              const SizedBox(height: 10),
              Text('$_correct إجابة صحيحة من $_total',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFD08A3E).withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFD08A3E).withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.bolt_rounded, size: 19, color: Color(0xFFD08A3E)),
                  SizedBox(width: 8),
                  Text('كيف تعمل',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD08A3E))),
                ]),
                const SizedBox(height: 10),
                Text(
                    'عشرة حسابات صيدلانية في دقيقتين: جرعة بالوزن، حجم من '
                    'شراب، معدل تسريب، قطرات في الدقيقة، وتخفيف\n\n'
                    'النقاط = 100 لكل جواب صحيح + 5 لكل ثانية متبقّية'
                    'الهامش المقبول 2٪ فلا حاجة لدقّة المنازل العشرية',
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.85,
                        color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_best > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 19, color: Color(0xFFD08A3E)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text('أفضل نتيجة لك',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text('$_best',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD08A3E))),
            ]),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded, size: 21),
            label: Text(_done ? 'أعد المحاولة' : 'ابدأ',
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
            'نتيجتك تُنشر في لوحة المتصدّرين داخل «عيادتك اليوم»',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5,
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  // ── شاشة اللعب ─────────────────────────────────────────────────────────
  Widget _game() {
    final q = _qs[_index];
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Row(children: [
          Text('${_index + 1} / $_total',
              style: TextStyle(
                  fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text('صحيح: $_correct',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successGreen)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (_index + 1) / _total,
          minHeight: 3,
          backgroundColor: theme.dividerColor.withOpacity(0.2),
          color: const Color(0xFFD08A3E),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
          ),
          child: Text(q.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, height: 1.8, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          autofocus: true,
          enabled: _lastOk == null,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.٫]')),
          ],
          onSubmitted: (_) => _submit(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            suffixText: q.unit,
            suffixStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: _lastOk == null
                ? theme.colorScheme.surfaceVariant
                : (_lastOk!
                    ? AppColors.successGreen.withOpacity(0.12)
                    : AppColors.errorRed.withOpacity(0.10)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
        if (_lastOk == null)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('تحقّق',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: (_lastOk! ? AppColors.successGreen : AppColors.errorRed)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(_lastOk! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 19,
                  color: _lastOk!
                      ? AppColors.successGreen
                      : AppColors.errorRed),
              const SizedBox(width: 9),
              Expanded(
                child: Text(q.explain,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
            ]),
          ),
      ],
    );
  }
}
