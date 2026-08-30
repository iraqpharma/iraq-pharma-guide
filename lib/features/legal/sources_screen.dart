import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

/// References screen — added for App Store guideline 1.4.1.
///
/// App Review rejected 2.3.0 (25) because the app presented medical
/// information "without citations ... such as links to sources", and required
/// the citations to be "easy for the user to find". This screen is that
/// citation list, and it is reachable from three places: the drawer, the
/// bottom of every drug detail page, and the bottom of the interaction
/// reference.
///
/// Deliberately self-contained: it carries its own bilingual strings and
/// reads the language from Directionality rather than AppStrings, so it can
/// be dropped in without touching the 72 KB app_strings.dart.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ar ? 'المصادر والمراجع' : 'Sources & References',
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Intro(ar: ar),
          const SizedBox(height: 18),
          ..._sources.map((s) => _SourceCard(source: s, ar: ar)),
          const SizedBox(height: 8),
          _Method(ar: ar),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _Source {
  final String titleAr, titleEn, descAr, descEn, url;
  const _Source({
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.url,
  });
}

/// Every entry here must be a reference the app's content genuinely draws on.
/// Do not add a source that was not used — App Review does open these links.
const _sources = <_Source>[
  _Source(
    titleAr: 'إدارة الغذاء والدواء الأمريكية (FDA)',
    titleEn: 'U.S. Food and Drug Administration (FDA)',
    descAr:
        'نشرات المنتج المعتمدة، التحذيرات الرسمية وحدود الجرعات القصوى، وتحذيرات الصندوق الأسود.',
    descEn:
        'Approved product labeling, official safety warnings, maximum-dose limits, and boxed warnings.',
    url: 'https://www.accessdata.fda.gov/scripts/cder/daf/',
  ),
  _Source(
    titleAr: 'DailyMed — المكتبة الوطنية الأمريكية للطب',
    titleEn: 'DailyMed — U.S. National Library of Medicine',
    descAr: 'النشرات الدوائية الكاملة المعتمدة رسميًا لكل مستحضر.',
    descEn: 'Full official prescribing information for each product.',
    url: 'https://dailymed.nlm.nih.gov/dailymed/',
  ),
  _Source(
    titleAr: 'منظمة الصحة العالمية (WHO)',
    titleEn: 'World Health Organization (WHO)',
    descAr:
        'قائمة الأدوية الأساسية، وسلّم تسكين الألم المعتمد في تصنيف المسكنات داخل التطبيق.',
    descEn:
        'Model List of Essential Medicines, and the analgesic ladder used to classify pain medicines in the app.',
    url: 'https://www.who.int/publications/i/item/WHO-MHP-HPS-EML-2023.02',
  ),
  _Source(
    titleAr: 'معادلة كوكروفت–غولت (Cockcroft–Gault)',
    titleEn: 'Cockcroft–Gault equation',
    descAr:
        'المعادلة المعتمدة في حساب تصفية الكرياتينين. Cockcroft DW, Gault MH. Nephron. 1976;16(1):31-41.',
    descEn:
        'The equation used for creatinine clearance. Cockcroft DW, Gault MH. Nephron. 1976;16(1):31-41.',
    url: 'https://pubmed.ncbi.nlm.nih.gov/1244564/',
  ),
  _Source(
    titleAr: 'Hale\'s Medications & Mothers\' Milk',
    titleEn: 'Hale\'s Medications & Mothers\' Milk',
    descAr: 'المرجع المعتمد في تصنيف أمان الأدوية أثناء الرضاعة داخل التطبيق.',
    descEn:
        'The reference used for the lactation-safety classification shown in the app.',
    url: 'https://www.halesmeds.com/',
  ),
];

// ── UI ───────────────────────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  final bool ar;
  const _Intro({required this.ar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.18)),
      ),
      child: Text(
        ar
            ? 'المعلومات الدوائية المعروضة في هذا التطبيق مجمّعة من المراجع المذكورة أدناه، وهي معدّة لأغراض تعليمية ومرجعية فقط. اضغط على أي مرجع لفتح مصدره.'
            : 'The drug information in this app is compiled from the references listed below and is provided for educational and reference purposes only. Tap any reference to open its source.',
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13.5, height: 1.7, color: Colors.black87),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final _Source source;
  final bool ar;
  const _SourceCard({required this.source, required this.ar});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(source.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ar ? 'تعذّر فتح الرابط' : 'Could not open the link'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      size: 20, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? source.titleAr : source.titleEn,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ar ? source.descAr : source.descEn,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12.5,
                            height: 1.6,
                            color: Colors.black.withValues(alpha: 0.62)),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        source.url,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 11.5,
                            color: AppColors.primaryBlue,
                            decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    size: 17, color: Colors.black.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  final bool ar;
  const _Method({required this.ar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'منهجية جمع البيانات' : 'How the data was compiled',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'جُمعت بطاقات الأدوية من المراجع أعلاه ثم صيغت بالعربية لأغراض الدراسة والمراجعة. التطبيق أداة تعليمية ومرجعية، وليس جهازًا طبيًا، ولا يقدّم تشخيصًا ولا وصفة علاجية، ولا يغني عن استشارة طبيب أو صيدلاني مرخّص. تُراجع قاعدة البيانات وتُحدَّث بشكل دوري.'
                : 'Drug entries were compiled from the references above and written in Arabic for study and revision. The app is an educational reference tool. It is not a medical device, it does not provide diagnosis or prescriptions, and it does not replace consultation with a licensed physician or pharmacist. The database is reviewed and updated periodically.',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                height: 1.75,
                color: Colors.black.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable footer link ─────────────────────────────────────────────────────

/// Drop this at the bottom of any screen that shows medical content. It is
/// what makes the citations "easy to find" from the content itself, which is
/// what App Review asked for — a single screen buried in a menu is not enough.
class SourcesFooterLink extends StatelessWidget {
  const SourcesFooterLink({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SourcesScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 15, color: AppColors.primaryBlue),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  ar
                      ? 'المعلومات مجمّعة من مراجع دوائية معيارية — عرض المصادر'
                      : 'Compiled from standard pharmaceutical references — view sources',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
