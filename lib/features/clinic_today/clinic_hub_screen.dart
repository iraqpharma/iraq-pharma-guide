import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import 'leaderboard.dart';
import '../../shared/widgets/section_intro.dart';

/// «عيادتك اليوم» — لوحة الأنشطة اليومية.
///
/// كلها تعمل بلا إنترنت من قاعدة التطبيق المضمَّنة، ما عدا لوحة
/// المتصدّرين في التحدّي السريع.
class ClinicTodayHubScreen extends StatefulWidget {
  const ClinicTodayHubScreen({super.key});

  @override
  State<ClinicTodayHubScreen> createState() => _ClinicTodayHubScreenState();
}

class _ClinicTodayHubScreenState extends State<ClinicTodayHubScreen> {
  int _streak = 0;
  int _best   = 0;
  String? _lastPlayed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'clinic_today');
    });
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _streak     = p.getInt('clinic_streak') ?? 0;
      _best       = p.getInt('clinic_best') ?? 0;
      _lastPlayed = p.getString('clinic_last_played');
    });
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final doneToday = _lastPlayed == _todayKey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('عيادتك اليوم',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            // ── البطاقة الرئيسية: أسئلة اليوم ──────────────────────────
            _HeroCard(
              doneToday: doneToday,
              streak: _streak,
              best: _best,
              onTap: () async {
                await context.push('/clinic-today/quiz');
                _load();
              },
            ),
            const SizedBox(height: 12),

            // ── صفّ من بطاقتين مربّعتين ────────────────────────────────
            SizedBox(
              height: 148,
              child: Row(children: [
                Expanded(
                  child: _SquareCard(
                    icon: Icons.medication_liquid_rounded,
                    color: const Color(0xFF3A72B8),
                    title: 'دواء اليوم',
                    subtitle: 'دواء واحد وما تقوله للمريض عنه',
                    tag: 'يومي',
                    onTap: () => context.push('/clinic-today/drug'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SquareCard(
                    icon: Icons.assignment_ind_rounded,
                    color: const Color(0xFF7A4EA8),
                    title: 'حالة الأسبوع',
                    subtitle: 'حالة سريرية وقرارك فيها',
                    tag: 'أسبوعي',
                    onTap: () => context.push('/clinic-today/case'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── بطاقتان عريضتان ────────────────────────────────────────
            _WideCard(
              icon: Icons.merge_type_rounded,
              color: const Color(0xFFC2454B),
              title: 'تحدّي التداخلات',
              subtitle: 'ثمانية أزواج أدوية: أيّها بينه تداخل مُعتبَر؟',
              onTap: () => context.push('/clinic-today/interactions'),
            ),
            const SizedBox(height: 10),
            _WideCard(
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD08A3E),
              title: 'الحاسبة السريعة',
              subtitle: 'عشر حسابات صيدلانية في دقيقتين، ونتيجتك تدخل اللوحة',
              onTap: () async {
                await context.push('/clinic-today/speed');
                setState(() {});
              },
            ),

            const SizedBox(height: 18),
            const _HowItWorks(),

            // ── لوحة المتصدّرين في الختام ──────────────────────────────
            // مكانها هنا لا في الأعلى: الصيدلاني يفتح القسم ليلعب لا
            // ليرى ترتيبه، والترتيب مكافأة بعد اللعب لا عائق قبله.
            const SizedBox(height: 18),
            const Leaderboard(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// البطاقة الرئيسية
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final bool doneToday;
  final int streak;
  final int best;
  final VoidCallback onTap;
  const _HeroCard({
    required this.doneToday,
    required this.streak,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF00695C), Color(0xFF00A58F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00695C).withOpacity(0.30),
                blurRadius: 16,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.quiz_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أسئلة اليوم',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                          doneToday
                              ? 'أنهيتها، عد غداً لأسئلة جديدة'
                              : 'خمسة أسئلة سريرية تحفظ سِلسِلتك',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 12.5)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(doneToday ? 0.22 : 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(doneToday ? 'تمّت' : 'ابدأ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: doneToday
                              ? Colors.white
                              : const Color(0xFF00695C))),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _stat(Icons.local_fire_department_rounded, '$streak',
                    streak == 1 ? 'يوم متتابع' : 'أيام متتابعة'),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: Colors.white.withOpacity(0.22),
                ),
                _stat(Icons.workspace_premium_rounded, '$best', 'أطول سِلسِلة'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.1,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 10)),
            ],
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// بطاقة مربّعة
// ═══════════════════════════════════════════════════════════════════════════════

class _SquareCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
  const _SquareCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.16),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(isDark ? 0.30 : 0.17),
                          color.withOpacity(isDark ? 0.14 : 0.07),
                        ],
                      ),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(tag,
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ]),
                const Spacer(),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// بطاقة عريضة
// ═══════════════════════════════════════════════════════════════════════════════

class _WideCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WideCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: isDark
              ? [color.withOpacity(0.22), cs.surface]
              : [color.withOpacity(0.12), Colors.white],
        ),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(isDark ? 0.26 : 0.16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: color.withOpacity(0.7), size: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// آلية اختيار المحتوى — مكتوبة للمستخدم لا مخفيّة عنه
// ═══════════════════════════════════════════════════════════════════════════════

class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(children: [
              const Icon(Icons.help_outline_rounded,
                  size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('كيف يُختار محتوى هذه الأقسام؟',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
              Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.primary),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('أسئلة اليوم',
                    'خمسة أسئلة من بنك فيه 352 سؤالاً، تُختار بمفتاح مشتقّ '
                    'من تاريخ اليوم فيراها كل المستخدمين متطابقة وتتغيّر '
                    'عند منتصف الليل، ولا تتكرّر مجموعة اليوم إلا بعد أن '
                    'يدور البنك كاملاً. ترتيب الخيارات مخلوط فلا يكون '
                    'موقع الإجابة الصحيحة ثابتاً', cs),
                _line('دواء اليوم',
                    'دواء واحد من الأدوية المتوفّرة محلياً التي لها نصيحة '
                    'صيدلانية مكتوبة، يُختار بالتاريخ أيضاً فهو نفسه '
                    'للجميع ويتبدّل كل يوم', cs),
                _line('حالة الأسبوع',
                    'حالة من عشرين حالة سريرية، تتبدّل كل أسبوع لا كل يوم '
                    'لأنها تحتاج تفكيراً أطول', cs),
                _line('تحدّي التداخلات',
                    'ثمانية أزواج تُبنى لحظياً من بيانات التداخلات في '
                    'التطبيق: نصفها أزواج بينها تداخل مذكور فعلاً، ونصفها '
                    'أزواج من أقسام مختلفة لا تداخل بينها. تختلف الأزواج '
                    'في كل محاولة', cs),
                _line('الحاسبة السريعة',
                    'الأرقام تُولَّد عشوائياً في كل محاولة فلا تُحفظ '
                    'الأجوبة، والنقاط = 100 لكل إجابة صحيحة + 5 لكل ثانية '
                    'متبقّية', cs),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _line(String title, String body, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(body,
                style: TextStyle(
                    fontSize: 11.5, height: 1.75, color: cs.onSurfaceVariant)),
          ],
        ),
      );
}
