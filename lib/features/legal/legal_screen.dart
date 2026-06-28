import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ── Legal page types ──────────────────────────────────────────────────────────
enum LegalType { privacy, terms, disclaimer }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  // ── Content definitions ────────────────────────────────────────────────────
  String get _title => switch (type) {
        LegalType.privacy    => 'سياسة الخصوصية',
        LegalType.terms      => 'شروط الاستخدام',
        LegalType.disclaimer => 'إخلاء المسؤولية',
      };

  IconData get _icon => switch (type) {
        LegalType.privacy    => Icons.privacy_tip_outlined,
        LegalType.terms      => Icons.gavel_rounded,
        LegalType.disclaimer => Icons.warning_amber_rounded,
      };

  Color get _color => switch (type) {
        LegalType.privacy    => AppColors.primary,
        LegalType.terms      => const Color(0xFF5C6BC0),
        LegalType.disclaimer => const Color(0xFFF57C00),
      };

  List<_Section> get _sections => switch (type) {
        LegalType.privacy    => _privacySections,
        LegalType.terms      => _termsSections,
        LegalType.disclaimer => _disclaimerSections,
      };

  // ── Privacy Policy ─────────────────────────────────────────────────────────
  static const _privacySections = [
    _Section('مقدمة',
        'نحن في Iraq Pharma Guide نلتزم بحماية خصوصيتك. توضح هذه السياسة كيفية جمع معلوماتك واستخدامها وحمايتها عند استخدامك لتطبيقنا.'),
    _Section('المعلومات التي نجمعها', '''
نجمع المعلومات التالية عند تسجيلك:
• الاسم الكامل واسم المستخدم
• البريد الإلكتروني وكلمة المرور (مشفّرة)
• المهنة والمحافظة وتاريخ الميلاد (اختياري)

كما نجمع تلقائياً:
• إحصائيات استخدام التطبيق (عدد البحوث، استخدام الأدوات)
• الملاحظات التي تضيفها في المرجع التفاعلي'''),
    _Section('كيفية استخدام المعلومات', '''
نستخدم معلوماتك من أجل:
• تشغيل حسابك وتقديم خدمات التطبيق
• تحسين تجربة المستخدم وتطوير الميزات
• إرسال إشعارات متعلقة بالتطبيق (بموافقتك)
• الرد على استفساراتك ودعم المستخدم'''),
    _Section('حماية البيانات', '''
• جميع البيانات مخزّنة بشكل آمن على خوادم Supabase
• كلمات المرور مشفّرة ولا يمكن لأحد الاطلاع عليها
• لا نشارك بياناتك مع أطراف ثالثة لأغراض تجارية
• يحق لك طلب حذف حسابك وبياناتك في أي وقت'''),
    _Section('التواصل والدعم',
        'لأي استفسار بشأن خصوصيتك، تواصل معنا عبر: urmuqa@gmail.com'),
    _Section('تاريخ آخر تحديث', 'يونيو 2025'),
  ];

  // ── Terms of Use ───────────────────────────────────────────────────────────
  static const _termsSections = [
    _Section('قبول الشروط',
        'باستخدامك لتطبيق Iraq Pharma Guide، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يُرجى عدم استخدام التطبيق.'),
    _Section('استخدام التطبيق', '''
يُسمح باستخدام التطبيق لـ:
• الصيادلة والعاملين في القطاع الصيدلاني في العراق
• البحث عن معلومات الأدوية لأغراض مهنية
• حسابات الجرعات والتفاعلات الدوائية كمرجع مساعد

يُحظر استخدام التطبيق لـ:
• أي غرض مخالف للقانون العراقي
• نشر أو مشاركة المحتوى بطريقة تنتهك حقوق الملكية الفكرية
• محاولة اختراق أو التلاعب بالنظام'''),
    _Section('الحساب والمسؤولية', '''
• أنت مسؤول عن الحفاظ على سرية بيانات حسابك
• يجب إبلاغنا فوراً عند اشتباهك بأي استخدام غير مصرح به
• نحتفظ بالحق في تعليق أي حساب يخالف هذه الشروط'''),
    _Section('الملكية الفكرية', '''
• جميع المحتويات والتصاميم والبيانات الواردة في التطبيق هي ملك حصري لـ Iraq Pharma Guide
• لا يُسمح بنسخ أو توزيع أي محتوى دون إذن مكتوب مسبق'''),
    _Section('التعديلات على الشروط',
        'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إشعارك بأي تغييرات جوهرية عبر التطبيق.'),
    _Section('تاريخ آخر تحديث', 'يونيو 2025'),
  ];

  // ── Disclaimer ─────────────────────────────────────────────────────────────
  static const _disclaimerSections = [
    _Section('⚠️ تنبيه مهم',
        'المعلومات الواردة في تطبيق Iraq Pharma Guide مخصصة للمرجعية المهنية للصيادلة والعاملين في القطاع الصيدلاني فقط، وليست بديلاً عن الاستشارة الطبية أو الصيدلانية المتخصصة.'),
    _Section('حدود المسؤولية', '''
لا يتحمل تطبيق Iraq Pharma Guide أي مسؤولية عن:
• القرارات الطبية أو الصيدلانية المبنية على معلومات التطبيق
• أي أضرار مباشرة أو غير مباشرة ناجمة عن الاعتماد على المعلومات الواردة
• دقة المعلومات في جميع الأوقات نظراً للتطور المستمر في علم الأدوية'''),
    _Section('دقة المعلومات', '''
• نسعى جاهدين لتقديم معلومات دقيقة ومحدّثة
• يجب دائماً التحقق من المعلومات من المصادر الرسمية والنشرات الدوائية المعتمدة
• تُحسب الجرعات في التطبيق كمرجع تقديري ويجب مراجعة الطبيب المختص'''),
    _Section('الاستخدام المهني', '''
هذا التطبيق مخصص حصراً للاستخدام من قِبل:
• الصيادلة المرخصين
• الصيادلة المتدربين تحت إشراف مرخص
• معاوني الصيادلة في بيئة مهنية خاضعة للإشراف

استخدامه من قبل غير المختصين يكون على مسؤوليتهم الشخصية الكاملة.'''),
    _Section('إخلاء المسؤولية القانوني',
        'يُستخدم هذا التطبيق "كما هو" دون أي ضمانات صريحة أو ضمنية. Iraq Pharma Guide وفريق التطوير غير مسؤولين عن أي خسائر أو أضرار من أي نوع تنجم عن استخدام هذا التطبيق أو الوثوق بمعلوماته.'),
    _Section('تاريخ آخر تحديث', 'يونيو 2025'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: _color,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(_title,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            centerTitle: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkNavy, _color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(_title,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Iraq Pharma Guide',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SectionCard(
                    section: _sections[i], accentColor: _color),
                childCount: _sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _Section {
  final String title, body;
  const _Section(this.title, this.body);
}

// ── Section card widget ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _Section section;
  final Color accentColor;
  const _SectionCard({required this.section, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(section.title,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(section.body,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.8)),
        ]),
      ),
    );
  }
}
