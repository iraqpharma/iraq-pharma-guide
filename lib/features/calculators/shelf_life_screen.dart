import '../../shared/widgets/t_text.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

/// مدّة صلاحية الدواء بعد فتحه.
///
/// السؤال الذي يتكرّر على الصيدلاني كل يوم: «قطرة العين مفتوحة من شهرين،
/// تنفع؟». تاريخ الانتهاء المطبوع على العلبة يخصّ العبوة المغلقة فقط،
/// وبعد أول فتح تبدأ مدّة أقصر بكثير.
class ShelfLifeItem {
  final String form;
  final String days;
  final int? typicalDays;
  final String note;
  final IconData icon;
  final Color color;
  const ShelfLifeItem(
    this.form,
    this.days,
    this.typicalDays,
    this.note,
    this.icon,
    this.color,
  );
}

const _items = <ShelfLifeItem>[
  ShelfLifeItem(
    'قطرة العين أو الأذن',
    '28 يوماً',
    28,
    'المادة الحافظة تكفي شهراً بعد الفتح. القطرة بلا مادة حافظة '
        '(أحادية الجرعة) تُرمى بعد 12–24 ساعة من فتحها',
    Icons.remove_red_eye_outlined,
    Color(0xFF3C7FB0),
  ),
  ShelfLifeItem(
    'قلم أو قنينة أنسولين قيد الاستعمال',
    '28 يوماً',
    28,
    'خارج الثلاجة بحرارة الغرفة دون 25 درجة. القلم المفتوح لا يُعاد '
        'للثلاجة. بعض الأنواع 42 يوماً، راجع نشرة المنتج',
    Icons.vaccines_outlined,
    Color(0xFF2E8F63),
  ),
  ShelfLifeItem(
    'مضاد حيوي شراب بعد التحضير بالماء',
    '7 إلى 14 يوماً',
    7,
    'الأموكسيسيلين والأوغمنتين 7 أيام في الثلاجة، والأزيثرومايسين '
        '10 أيام، والسيفيكسيم 14. اكتب تاريخ التحضير على العلبة',
    Icons.science_outlined,
    Color(0xFF3A72B8),
  ),
  ShelfLifeItem(
    'شراب جاهز أو معلّق فموي',
    '3 أشهر',
    90,
    'ما لم تذكر النشرة غير ذلك. أغلق بإحكام وتجنّب الحرارة والشمس',
    Icons.local_drink_outlined,
    Color(0xFF2E8B82),
  ),
  ShelfLifeItem(
    'كريم أو مرهم في أنبوب',
    '3 إلى 6 أشهر',
    90,
    'الأنبوب أنظف من العلبة ذات الغطاء لأن الأصابع لا تلمس المحتوى. '
        'يُرمى عند تغيّر اللون أو الرائحة أو انفصال القوام',
    Icons.healing_outlined,
    Color(0xFFC25F7E),
  ),
  ShelfLifeItem(
    'بخاخ الأنف',
    '3 أشهر',
    90,
    'لا يُشارَك بين شخصين إطلاقاً. نظّف الفوهة بعد كل استعمال',
    Icons.air_outlined,
    Color(0xFF3F93A8),
  ),
  ShelfLifeItem(
    'محلول وريدي بعد الفتح أو الثقب',
    '24 ساعة',
    1,
    'في الثلاجة، وبعض الأدوية أقل بكثير. التحضير في ظرف معقّم يطيل '
        'المدّة حسب بروتوكول المستشفى',
    Icons.water_drop_outlined,
    Color(0xFF3E8F9C),
  ),
  ShelfLifeItem(
    'قنينة متعدّدة الجرعات (حقن)',
    '28 يوماً',
    28,
    'من أول ثقب للغطاء المطاطي. اكتب التاريخ على القنينة، وامسح '
        'الغطاء بالكحول قبل كل سحب',
    Icons.colorize_outlined,
    Color(0xFF7A4EA8),
  ),
  ShelfLifeItem(
    'تحاميل ولبوس',
    'حتى تاريخ العلبة',
    null,
    'لا تتأثر بالفتح لأن كل وحدة مغلّفة وحدها، لكنها تذوب بالحرارة '
        'فتُحفظ في مكان بارد',
    Icons.medication_outlined,
    Color(0xFF9A6B4F),
  ),
  ShelfLifeItem(
    'أقراص وكبسولات في شريط',
    'حتى تاريخ العلبة',
    null,
    'الشريط يحمي كل حبّة وحدها. أمّا العلبة المفتوحة ذات الحبوب '
        'السائبة فستّة أشهر، ولا تُنقل الحبوب إلى علبة أخرى',
    Icons.medication_liquid_outlined,
    Color(0xFF6E7B88),
  ),
];

class ShelfLifeScreen extends StatefulWidget {
  const ShelfLifeScreen({super.key});

  @override
  State<ShelfLifeScreen> createState() => _ShelfLifeScreenState();
}

class _ShelfLifeScreenState extends State<ShelfLifeScreen> {
  int? _open;
  DateTime? _opened;

  Future<void> _pickDate(int i) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 400)),
      lastDate: now,
      helpText: 'متى فُتحت العبوة؟',
    );
    if (d != null) {
      Haptics.success();
      setState(() => _opened = d);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'shelf_life');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TText('الصلاحية بعد الفتح',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.16)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: TText(
                    'التاريخ المطبوع على العلبة يخصّ العبوة المغلقة. بعد '
                    'أول فتح تبدأ مدّة أقصر، وهذه هي',
                    style: TextStyle(
                        fontSize: 12, height: 1.65, color: theme.colorScheme.onSurface)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _items.length; i++) _card(i, _items[i]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: AppColors.warningAmber.withOpacity(0.22)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 17, color: AppColors.warningAmber),
              const SizedBox(width: 9),
              Expanded(
                child: TText(
                    'هذه مدد عامة مرجعية. نشرة المنتج تسبقها دائماً، وأي '
                    'تغيّر في اللون أو الرائحة أو القوام يعني الرمي فوراً '
                    'مهما بقي من الوقت',
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

  Widget _card(int i, ShelfLifeItem it) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final open   = _open == i;

    DateTime? expiry;
    int? left;
    if (open && _opened != null && it.typicalDays != null) {
      expiry = _opened!.add(Duration(days: it.typicalDays!));
      left = expiry.difference(DateTime.now()).inDays;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: open
                ? it.color.withOpacity(0.4)
                : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFECEFF2))),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          InkWell(
            onTap: () => setState(() {
              _open = open ? null : i;
              if (!open) _opened = null;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: it.color.withOpacity(isDark ? 0.22 : 0.12),
                  ),
                  child: Icon(it.icon, color: it.color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TText(it.form,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: it.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: TText(it.days,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: it.color)),
                ),
              ]),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(it.note,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.8,
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (it.typicalDays != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(i),
                      icon: const Icon(Icons.event_outlined, size: 17),
                      label: TText(
                          _opened == null
                              ? 'متى فُتحت العبوة؟'
                              : 'فُتحت في '
                                  '${_opened!.year}/${_opened!.month}/${_opened!.day}',
                          style: const TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: it.color,
                        side: BorderSide(color: it.color.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 11),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (left! < 0
                                  ? AppColors.errorRed
                                  : (left <= 5
                                      ? AppColors.warningAmber
                                      : AppColors.successGreen))
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TText(
                                left < 0
                                    ? 'انتهت صلاحيتها منذ ${-left} يوماً'
                                    : (left == 0
                                        ? 'تنتهي اليوم'
                                        : 'تبقّى $left يوماً'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: left < 0
                                      ? AppColors.errorRed
                                      : (left <= 5
                                          ? AppColors.warningAmber
                                          : AppColors.successGreen),
                                )),
                            const SizedBox(height: 3),
                            TText(
                                'آخر يوم صالح: '
                                '${expiry.year}/${expiry.month}/${expiry.day}',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
        ]),
      ),
    );
  }
}
