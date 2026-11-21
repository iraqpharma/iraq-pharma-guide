import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';

/// تعريف قصير بالقسم يظهر مرّة واحدة عند أول فتح.
///
/// أكثر ما يُهدر في التطبيقات أقسام لا يعرف المستخدم ما الذي تفعله، فلا
/// يفتحها أبداً. بدل شرح طويل في صفحة مساعدة لا يقرأها أحد، يظهر تعريف
/// من ثلاثة أسطر عند أوّل دخول للقسم نفسه، ثم لا يعود.
class IntroStep {
  final IconData icon;
  final String title;
  final String body;
  const IntroStep(this.icon, this.title, this.body);
}

class SectionIntro {
  SectionIntro._();

  static const _prefix = 'intro_seen_';

  static Future<bool> seen(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_prefix$key') ?? false;
  }

  static Future<void> markSeen(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_prefix$key', true);
  }

  /// يُعيد عرض كل التعريفات. يُستعمل من الإعدادات.
  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    for (final k in p.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await p.remove(k);
    }
  }

  /// يعرض تعريف القسم إن لم يُعرض من قبل.
  ///
  /// يُنادى من initState بعد إطار واحد كي يكون الـ context جاهزاً.
  static Future<void> showOnce(
    BuildContext context, {
    required String id,
    Color accent = AppColors.primary,
  }) async {
    final intro = kIntros[id];
    if (intro == null) return;
    if (await seen(id)) return;
    if (!context.mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IntroSheet(intro: intro, accent: accent),
    );
    await markSeen(id);
  }

  /// يعرض التعريف بطلب المستخدم، حتى لو رآه سابقاً.
  static Future<void> showNow(
    BuildContext context, {
    required String id,
    Color accent = AppColors.primary,
  }) async {
    final intro = kIntros[id];
    if (intro == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IntroSheet(intro: intro, accent: accent),
    );
  }
}

class IntroContent {
  final String title;
  final String tagline;
  final List<IntroStep> steps;
  const IntroContent(this.title, this.tagline, this.steps);
}

/// نصوص التعريف لكل قسم. مكتوبة بلسان صيدلاني يكلّم زميله، لا بلسان
/// دليل استعمال.
const kIntros = <String, IntroContent>{
  'substitution': IntroContent(
    'الباحث عن البدائل',
    'الدواء غير متوفّر والمريض واقف أمامك. هنا تجد ما يحلّ محلّه',
    [
      IntroStep(Icons.search_rounded, 'ابحث بالاسم',
          'اكتب اسم الدواء الناقص، تجاري أو علمي، لا فرق'),
      IntroStep(Icons.swap_horiz_rounded, 'بديل بنفس المادة أو بنفس العائلة',
          'البديل المطابق أولاً، ثم أدوية العائلة نفسها حين لا يتوفّر مطابق'),
      IntroStep(Icons.fact_check_outlined, 'انتبه للتركيز والشكل',
          'البديل يحمل التركيز والشكل، فتقارنهما قبل الصرف'),
    ],
  ),
  'pricing': IntroContent(
    'حاسبة التسعير',
    'من سعر الفاتورة إلى سعر الرفّ، بربح تحدّده أنت',
    [
      IntroStep(Icons.receipt_long_outlined, 'ابدأ من سعر القطعة في الفاتورة',
          'أدخل سعر الشراء الحقيقي للقطعة الواحدة لا سعر الكارتون'),
      IntroStep(Icons.percent_rounded, 'حدّد نسبة الربح',
          'الحاسبة تعطي سعر البيع والربح بالدينار على القطعة وعلى الكمّية'),
      IntroStep(Icons.savings_outlined, 'قارن قبل أن تُسعّر',
          'راجع السعر مع دليل الأسعار كي لا تخرج عن سعر السوق'),
    ],
  ),
  'notebook': IntroContent(
    'نواقص الصيدلية',
    'سجّل ما نفد وأنت واقف عند الرفّ، لا بعد ساعة حين تنساه',
    [
      IntroStep(Icons.keyboard_alt_outlined, 'اكتب حرفين فقط',
          'الاسم يأتيك من قاعدة الأدوية، فلا تكتبه كاملاً ولا تخطئ بإملائه'),
      IntroStep(Icons.qr_code_scanner_rounded, 'أو اقرأ الباركود',
          'أسرع طريقة وأنت ممسك بالعلبة الأخيرة'),
      IntroStep(Icons.photo_camera_outlined, 'أو صوّر العلبة الآن',
          'الصورة تُسجَّل فوراً وتُكمل الاسم في وقت أهدأ'),
      IntroStep(Icons.send_rounded, 'أرسل القائمة للمندوب',
          'مرتّبة: ما نفد أولاً ثم ما أوشك، بضغطة واحدة على واتساب'),
    ],
  ),
  'price_guide': IntroContent(
    'دليل الأسعار',
    'أسعار السوق التجارية كما يتداولها الصيادلة',
    [
      IntroStep(Icons.search_rounded, 'ابحث بالاسم التجاري',
          'اكتب أول حروف الاسم وستظهر النتائج فوراً'),
      IntroStep(Icons.qr_code_scanner_rounded, 'أو اقرأ الباركود',
          'الرقم يُترجَم إلى اسم الدواء أولاً ثم يُبحث عنه'),
      IntroStep(Icons.refresh_rounded, 'حدّث القائمة بين حين وآخر',
          'الأسعار تتغيّر، والسحب للأسفل يجلب آخر تحديث'),
    ],
  ),
  'clinic_today': IntroContent(
    'عيادتك اليوم',
    'خمس دقائق يومياً تُبقي معلوماتك حيّة',
    [
      IntroStep(Icons.quiz_outlined, 'أسئلة اليوم',
          'خمسة أسئلة جديدة كل يوم، وترتيب الإجابات يتغيّر في كل مرّة'),
      IntroStep(Icons.science_outlined, 'تحدّي التداخلات',
          'زوجان من الأدوية، وعليك أن تقرّر: تداخل أم لا'),
      IntroStep(Icons.leaderboard_outlined, 'لوحة الصدارة',
          'العشرة الأوائل اليوم والأسبوع والشهر'),
    ],
  ),
  'interactions': IntroContent(
    'مدقّق التداخلات',
    'قبل أن تصرف وصفة فيها أكثر من دواء',
    [
      IntroStep(Icons.add_circle_outline_rounded, 'أضف أدوية الوصفة',
          'اثنان أو أكثر، والفحص يشمل كل الأزواج الممكنة بينها'),
      IntroStep(Icons.warning_amber_rounded, 'اقرأ درجة الخطورة',
          'التداخل الشديد يعني راجع الطبيب لا مجرّد تنبيه المريض'),
      IntroStep(Icons.menu_book_outlined, 'المصدر مذكور دائماً',
          'لتعود إليه حين تحتاج تفصيلاً أدقّ'),
    ],
  ),
  'jobs': IntroContent(
    'فرص العمل',
    'وظائف الصيدلة في العراق، معروضة من أصحابها',
    [
      IntroStep(Icons.location_on_outlined, 'فلتر بالمحافظة ونوع الدوام',
          'لتصل إلى ما يناسبك دون تصفّح كل الإعلانات'),
      IntroStep(Icons.add_box_outlined, 'انشر إعلانك',
          'كل إعلان يُراجَع قبل نشره، فلا تظهر الإعلانات الوهمية'),
      IntroStep(Icons.favorite_border_rounded, 'احفظ ما يعجبك',
          'الإعلانات الأكثر إعجاباً تتصدّر القائمة'),
    ],
  ),
  'availability': IntroContent(
    'توفّر الأدوية',
    'أين يوجد الدواء الآن، من صيدلاني إلى صيدلاني',
    [
      IntroStep(Icons.inventory_2_outlined, 'أعلن عمّا عندك',
          'الدواء الموجود في صيدليتك قد يكون نقص زميل في محافظة أخرى'),
      IntroStep(Icons.travel_explore_rounded, 'ابحث عمّا ينقصك',
          'فلتر بالمحافظة واتّصل بصاحب الإعلان مباشرة'),
      IntroStep(Icons.verified_outlined, 'كل إعلان مُراجَع',
          'لا يظهر شيء للمستخدمين قبل الموافقة عليه'),
    ],
  ),
  'shelf_life': IntroContent(
    'الصلاحية بعد الفتح',
    'تاريخ العلبة للعبوة المغلقة. بعد الفتح تبدأ مدّة أقصر',
    [
      IntroStep(Icons.touch_app_outlined, 'اضغط على الشكل الدوائي',
          'قطرة، أنسولين، شراب محضّر، كريم، لكلٍّ مدّته'),
      IntroStep(Icons.event_outlined, 'أدخل تاريخ الفتح',
          'يحسب لك آخر يوم صالح وكم بقي'),
      IntroStep(Icons.edit_calendar_outlined, 'اكتب التاريخ على العلبة',
          'عادة بسيطة تمنع أخطاء كثيرة في الصرف'),
    ],
  ),
  'supply_days': IntroContent(
    'كم تكفي العلبة',
    'سؤال المريض الدائم: متى أرجع أشتري؟',
    [
      IntroStep(Icons.inventory_outlined, 'أدخل حجم العبوة',
          'عدد الأقراص، أو حجم القنينة، أو وحدات القلم'),
      IntroStep(Icons.schedule_rounded, 'ثم الجرعة وعدد المرّات',
          'والحاسبة تعطي عدد الأيام وتاريخ النفاد'),
      IntroStep(Icons.notifications_active_outlined, 'ذكّر المريض قبل النفاد',
          'تاريخ التذكير يظهر قبل خمسة أيام من النفاد'),
    ],
  ),
  'lab_units': IntroContent(
    'وحدات التحاليل',
    'المختبرات تخلط بين الوحدات التقليدية والدولية',
    [
      IntroStep(Icons.search_rounded, 'ابحث عن التحليل',
          'بالعربية أو الإنكليزية، أكثر من أربعين تحليلاً'),
      IntroStep(Icons.swap_horiz_rounded, 'حوّل في الاتجاهين',
          'من ملغم/دل إلى ملمول/ل والعكس بضغطة'),
      IntroStep(Icons.straighten_rounded, 'المدى الطبيعي مرفق',
          'لتعرف هل النتيجة داخل الحدود أم خارجها'),
    ],
  ),
  'vaccine': IntroContent(
    'جدول التلقيح',
    'الجدول الوطني العراقي، محوّلاً إلى تواريخ حقيقية',
    [
      IntroStep(Icons.cake_outlined, 'أدخل تاريخ ميلاد الطفل',
          'فيتحوّل الجدول العمري إلى تواريخ يفهمها الأهل'),
      IntroStep(Icons.event_busy_outlined, 'الزيارات الفائتة تُعلَّم بالأحمر',
          'والمستحقّة الآن بالأخضر'),
      IntroStep(Icons.add_circle_outline_rounded, 'ولقاحات خارج الجدول',
          'المكوّرات الرئوية والجدري المائي وغيرها، للعلم بها'),
    ],
  ),
  'chemo_dose': IntroContent(
    'تخفيض جرعات الكيماوي',
    'أداة مرجعية لتعديل الجرعة حسب وظائف الكبد والكلى',
    [
      IntroStep(Icons.monitor_heart_outlined, 'أدخل قيم المريض',
          'الكرياتينين والبيليروبين وإنزيمات الكبد'),
      IntroStep(Icons.rule_rounded, 'اقرأ القاعدة لا الرقم فقط',
          'الأداة تعرض القاعدة المرجعية التي بُني عليها التعديل'),
      IntroStep(Icons.person_search_outlined, 'القرار للطبيب المعالج',
          'هذه مرجعية سريرية مساعدة لا بديل عن بروتوكول المركز'),
    ],
  ),
  'customers': IntroContent(
    'زبائني',
    'المريض المزمن يسأل «شنو كان علاجي؟» ويتوقّع منك أن تتذكّر',
    [
      IntroStep(Icons.person_add_alt_1_rounded, 'بطاقة لكل زبون متكرّر',
          'اسمه وعمره وحالته المزمنة وأي حساسية عنده'),
      IntroStep(Icons.medication_outlined, 'علاجه وجرعته',
          'الاسم يأتيك من قاعدة الأدوية، والجرعة بكلامك أنت'),
      IntroStep(Icons.event_repeat_rounded, 'وكم يوماً تكفي العلبة',
          'فيحسب التطبيق موعد إعادة الصرف ويُظهر من تأخّر'),
      IntroStep(Icons.lock_outline_rounded, 'كل شيء على هاتفك وحده',
          'لا يُرفع إلى أي خادم. معلومات المرضى أمانة لا تُنشر'),
    ],
  ),
  'barcode': IntroContent(
    'قراءة الباركود',
    'الرقم على العلبة لا يحمل اسم الدواء',
    [
      IntroStep(Icons.qr_code_2_rounded, 'ما الذي يقرأه التطبيق',
          'الكاميرا تقرأ الرقم التسلسلي فقط، والخطوط ترميز لهذا الرقم'),
      IntroStep(Icons.link_rounded, 'الاسم يأتي من قاعدة ربط',
          'إن كان الرقم معروفاً ظهر الاسم فوراً وبُحث عنه'),
      IntroStep(Icons.volunteer_activism_outlined, 'وإن كان مجهولاً',
          'تُسنِده إلى دوائه مرّة واحدة، فيصير معروفاً لكل صيادلة التطبيق'),
    ],
  ),
};

class _IntroSheet extends StatelessWidget {
  final IntroContent intro;
  final Color accent;
  const _IntroSheet({required this.intro, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(intro.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(intro.tagline,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              for (final s in intro.steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, size: 19, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 3),
                            Text(s.body,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.75,
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('فهمت، لنبدأ',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('لن تظهر هذه الشاشة مرّة أخرى',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
