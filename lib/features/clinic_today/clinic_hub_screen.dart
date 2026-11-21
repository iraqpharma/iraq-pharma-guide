import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';

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
    final theme     = Theme.of(context);
    final doneToday = _lastPlayed == _todayKey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('عيادتك اليوم',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            // ── شريط السِّلسِلة ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                ),
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      doneToday
                          ? Icons.local_fire_department_rounded
                          : Icons.whatshot_outlined,
                      color: Colors.white,
                      size: 26),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _streak == 0
                              ? 'ابدأ سِلسِلتك اليوم'
                              : 'سِلسِلة $_streak ${_streak == 1 ? "يوم" : "أيام"}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(
                          doneToday
                              ? 'أنهيت أسئلة اليوم — عد غداً'
                              : 'لم تُنهِ أسئلة اليوم بعد',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (_best > 0)
                  Column(children: [
                    Text('$_best',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('أفضل',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10)),
                  ]),
              ]),
            ),

            const SizedBox(height: 16),

            _ActivityCard(
              icon: Icons.quiz_rounded,
              color: const Color(0xFF00897B),
              title: 'أسئلة اليوم',
              subtitle: 'خمسة أسئلة سريرية تحفظ سِلسِلتك',
              tag: doneToday ? 'أُنجزت' : 'جديدة',
              tagColor:
                  doneToday ? AppColors.successGreen : AppColors.warningAmber,
              onTap: () async {
                await context.push('/clinic-today/quiz');
                _load();
              },
            ),
            _ActivityCard(
              icon: Icons.medication_liquid_rounded,
              color: const Color(0xFF3A72B8),
              title: 'دواء اليوم',
              subtitle: 'دواء واحد، وما يجب أن تقوله للمريض عنه',
              tag: 'يتغيّر يومياً',
              onTap: () => context.push('/clinic-today/drug'),
            ),
            _ActivityCard(
              icon: Icons.assignment_ind_rounded,
              color: const Color(0xFF7A4EA8),
              title: 'حالة الأسبوع',
              subtitle: 'حالة سريرية مفصّلة وقرارك فيها',
              tag: 'يتغيّر أسبوعياً',
              onTap: () => context.push('/clinic-today/case'),
            ),
            _ActivityCard(
              icon: Icons.merge_type_rounded,
              color: const Color(0xFFC2454B),
              title: 'تحدّي التداخلات',
              subtitle: 'زوج أدوية — هل بينهما تداخل مُدرج؟',
              tag: 'ثمانية أزواج',
              onTap: () => context.push('/clinic-today/interactions'),
            ),
            _ActivityCard(
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD08A3E),
              title: 'الحاسبة السريعة',
              subtitle: 'عشر حسابات بوقت محدود + لوحة المتصدّرين',
              tag: 'تنافُس',
              onTap: () => context.push('/clinic-today/speed'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? tag;
  final Color? tagColor;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : const Color(0xFFECEFF2)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.14),
                    blurRadius: 11,
                    spreadRadius: -3,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(isDark ? 0.30 : 0.17),
                        color.withOpacity(isDark ? 0.14 : 0.07),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25)),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (tagColor ?? color).withOpacity(0.13),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(tag!,
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor ?? color)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.5), size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
