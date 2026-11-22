import '../../shared/widgets/t_text.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

/// جدول التلقيح الوطني العراقي.
///
/// الصيدلاني يُسأل كل يوم: «ابني عمره خمسة أشهر، شنو اللقاح الجاي؟».
/// باختيار تاريخ الميلاد يحوّل الجدول العمري إلى تواريخ فعلية، ويبيّن
/// الزيارة الحالية والزيارات الفائتة.
class VaccineVisit {
  final String age;      // العمر كما في الجدول الوطني
  final int days;        // العمر بالأيام لحساب التاريخ
  final List<String> vaccines;
  final String note;
  const VaccineVisit(this.age, this.days, this.vaccines, [this.note = '']);
}

const _visits = <VaccineVisit>[
  VaccineVisit('عند الولادة', 0, [
    'BCG  ·  0.1 مل داخل الأدمة',
    'OPV 0  ·  نقطتان فموياً',
    'Hepatitis B 1  ·  خلال 24 ساعة من الولادة',
  ], 'جرعة التهاب الكبد الأولى مهمّة خلال اليوم الأول، وتأخيرها يقلّل '
      'الحماية من انتقال الفيروس من الأم'),
  VaccineVisit('شهران', 60, [
    'Pentavalent 1  ·  DTP + Hib + HepB',
    'OPV 1',
    'Rotavirus 1  ·  فموي',
  ], 'الجرعة الأولى من لقاح الروتا لا تُعطى بعد عمر 15 أسبوعاً'),
  VaccineVisit('أربعة أشهر', 120, [
    'Tetravalent 2  ·  DTP + Hib',
    'OPV 2',
    'IPV  ·  البوليو المعطّل عضلياً',
    'Rotavirus 2',
  ], 'جرعة البوليو المعطّل تُعطى مع هذه الزيارة في البرنامج العراقي'),
  VaccineVisit('ستة أشهر', 180, [
    'Pentavalent 3  ·  DTP + Hib + HepB',
    'OPV 3',
    'Rotavirus 3',
  ], 'آخر جرعة من الروتا لا تُعطى بعد عمر ثمانية أشهر'),
  VaccineVisit('تسعة أشهر', 270, [
    'Measles  ·  الحصبة أحادية',
    'Vitamin A  ·  100000 وحدة',
  ], 'لقاح الحصبة هنا لا يُلغي الحاجة إلى MMR في الخامسة عشرة'),
  VaccineVisit('خمسة عشر شهراً', 450, [
    'MMR 1  ·  حصبة ونكاف وحميراء',
  ]),
  VaccineVisit('ثمانية عشر شهراً', 540, [
    'Tetravalent booster  ·  DTP + Hib',
    'OPV booster',
    'Vitamin A  ·  200000 وحدة',
  ], 'الجرعة المعزّزة الأولى'),
  VaccineVisit('عند دخول المدرسة  ·  4 إلى 6 سنوات', 1825, [
    'DTP booster',
    'OPV booster',
    'MMR 2',
  ], 'الجرعة المعزّزة الثانية. بعد عمر السادسة يُستعمل Td بدل DTP'),
  VaccineVisit('كل عشر سنوات بعد المدرسة', 3650, [
    'Td  ·  تيتانوس وخفّاق الدفتيريا',
  ], 'تتكرّر مدى الحياة كل عشر سنوات'),
];

const _privateList = <List<String>>[
  ['Pneumococcal  ·  PCV', 'غير مشمول في الجدول الوطني، يُصرف خاصّاً. '
      'جرعتان أو ثلاث في السنة الأولى مع جرعة معزّزة'],
  ['Varicella  ·  الجدري المائي', 'جرعة بعد السنة وجرعة ثانية بعد ستة أسابيع'],
  ['Hepatitis A', 'جرعتان بفاصل ستّة أشهر، بعد عمر السنة'],
  ['Influenza  ·  الإنفلونزا الموسمية', 'سنوياً من عمر ستّة أشهر، '
      'وجرعتان في السنة الأولى من التلقيح'],
  ['Meningococcal  ·  السحائي', 'مطلوب لحجّاج العراق ومسافري الحجّ والعمرة'],
  ['HPV  ·  فيروس الورم الحلمي', 'للفتيات من عمر تسع سنوات، جرعتان'],
  ['Typhoid  ·  التيفوئيد', 'جرعة كل ثلاث سنوات في المناطق الموبوءة'],
];

class VaccineScheduleScreen extends StatefulWidget {
  const VaccineScheduleScreen({super.key});

  @override
  State<VaccineScheduleScreen> createState() => _VaccineScheduleScreenState();
}

class _VaccineScheduleScreenState extends State<VaccineScheduleScreen> {
  DateTime? _birth;
  bool _showPrivate = false;

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: 'تاريخ ميلاد الطفل',
    );
    if (d != null) {
      Haptics.success();
      setState(() => _birth = d);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'vaccine');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ageDays =
        _birth == null ? null : DateTime.now().difference(_birth!).inDays;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TText('جدول التلقيح العراقي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TText('حوّل الجدول إلى تواريخ',
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TText(
                    'اختر تاريخ الميلاد لتظهر تواريخ كل زيارة، والزيارات '
                    'التي فاتت',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 11),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.cake_outlined, size: 17),
                      label: TText(
                          _birth == null
                              ? 'تاريخ الميلاد'
                              : '${_birth!.year}/${_birth!.month}/${_birth!.day}',
                          style: const TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_birth != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _birth = null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: trS(context, 'إلغاء'),
                    ),
                  ],
                ]),
                if (ageDays != null) ...[
                  const SizedBox(height: 9),
                  TText(_ageText(ageDays),
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final v in _visits) _visitCard(v, ageDays, isDark),
          const SizedBox(height: 10),
          _card(
            isDark,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _showPrivate = !_showPrivate),
                  child: Row(children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: TText('لقاحات خارج الجدول الوطني',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                    Icon(
                        _showPrivate
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                  ]),
                ),
                if (_showPrivate) ...[
                  const SizedBox(height: 11),
                  for (final p in _privateList)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TText(p[0],
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          TText(p[1],
                              style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.7,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: AppColors.warningAmber.withOpacity(0.22)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 17, color: AppColors.warningAmber),
              const SizedBox(width: 9),
              Expanded(
                child: TText(
                    'جدول مرجعي للاسترشاد. بطاقة التلقيح الصادرة من مركز '
                    'الرعاية الصحية الأولية وتعليمات وزارة الصحة هي المرجع '
                    'الملزم، وقد تتغيّر اللقاحات وأعمارها بقرار وزاري',
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.7,
                        color: theme.colorScheme.onSurface)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _ageText(int days) {
    if (days < 60) return 'العمر الحالي: $days يوماً';
    final m = (days / 30.44).floor();
    if (m < 24) return 'العمر الحالي: $m شهراً';
    final y = (days / 365.25).floor();
    final rm = ((days - y * 365.25) / 30.44).floor();
    return 'العمر الحالي: $y سنة'
        '${rm > 0 ? ' و$rm شهراً' : ''}';
  }

  Widget _card(bool isDark, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: child,
    );
  }

  Widget _visitCard(VaccineVisit v, int? ageDays, bool isDark) {
    final theme = Theme.of(context);

    // الحالة: فائتة، مستحقّة الآن، أو قادمة
    String? state;
    Color stateColor = AppColors.primary;
    if (ageDays != null) {
      if (ageDays > v.days + 30) {
        state = 'فائتة';
        stateColor = AppColors.errorRed;
      } else if (ageDays >= v.days - 7) {
        state = 'مستحقّة الآن';
        stateColor = AppColors.successGreen;
      } else {
        state = 'قادمة';
        stateColor = const Color(0xFF6E7B88);
      }
    }

    final due = _birth?.add(Duration(days: v.days));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: state == 'مستحقّة الآن'
                ? AppColors.successGreen.withOpacity(0.45)
                : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFECEFF2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TText(v.age,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            if (state != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: TText(state,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: stateColor)),
              ),
          ]),
          if (due != null && v.days < 3650) ...[
            const SizedBox(height: 5),
            TText('التاريخ: ${due.year}/${due.month}/${due.day}',
                style: TextStyle(
                    fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          for (final vac in v.vaccines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.55),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TText(vac,
                      style: const TextStyle(fontSize: 12.5, height: 1.5)),
                ),
              ]),
            ),
          if (v.note.isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: TText(v.note,
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.7,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }
}
