import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    (
      q: 'كيف أبحث عن دواء؟',
      a: 'اضغط على أيقونة البحث في الشريط السفلي، ثم اكتب اسم الدواء بالعربي أو الإنجليزي أو رقم التسجيل.'
    ),
    (
      q: 'كيف أستخدم حاسبة الجرعات؟',
      a: 'من قسم الأدوات، اختر "حاسبة الجرعات"، أدخل وزن المريض والدواء والجرعة المطلوبة وستحسب التطبيق الجرعة تلقائياً.'
    ),
    (
      q: 'كيف أحفظ ملاحظاتي المهنية؟',
      a: 'من قسم حسابي → المرجع التفاعلي، يمكنك إضافة وتعديل وحذف ملاحظاتك وبروتوكولاتك الشخصية.'
    ),
    (
      q: 'هل يمكنني استخدام التطبيق بدون إنترنت؟',
      a: 'بعض البيانات الأساسية تعمل offline، لكن البحث والمزامنة تتطلب اتصالاً بالإنترنت.'
    ),
    (
      q: 'كيف أغيّر كلمة المرور؟',
      a: 'من حسابي → تعديل البيانات الشخصية → تغيير كلمة المرور في أعلى الشاشة.'
    ),
    (
      q: 'كيف أتواصل مع الدعم؟',
      a: 'يمكنك إرسال اقتراحاتك أو مشاكلك عبر قسم "إرسال اقتراح" في صفحة حسابي، أو عبر البريد الإلكتروني أدناه.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('قسم الدعم',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkNavy, AppColors.primary],
                begin: Alignment.centerRight, end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مركز المساعدة',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('إجابات على الأسئلة الشائعة وطرق التواصل',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12, color: Colors.white.withOpacity(0.85))),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // FAQ section
          _label('الأسئلة الشائعة', Icons.quiz_outlined),
          const SizedBox(height: 10),
          ..._faqs.map((faq) => _FaqTile(q: faq.q, a: faq.a)),
          const SizedBox(height: 20),

          // Contact section
          _label('تواصل معنا', Icons.contact_support_outlined),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.email_outlined,
            color: AppColors.primary,
            title: 'البريد الإلكتروني',
            subtitle: 'urmuqa@gmail.com',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text, IconData icon) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 8),
    Text(text,
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
  ]);
}

class _FaqTile extends StatefulWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.q,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              ]),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Text(widget.a,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon; final Color color;
  final String title, subtitle;
  const _ContactCard({required this.icon, required this.color, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(subtitle, style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    ]),
  );
}
