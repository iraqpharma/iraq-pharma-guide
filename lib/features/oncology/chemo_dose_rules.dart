/// قواعد تعديل جرعات العلاج الكيميائي حسب وظائف الكبد والكلى.
///
/// كل قاعدة منقولة من نشرة الدواء المعتمدة (FDA label) أو من إجماع
/// المراجع السريرية الشائعة (NCCN · ASCO · Lexicomp · BC Cancer Protocols)،
/// ومصدر كل دواء مذكور في `source`. هذه أداة مساعدة للقرار ولا تُغني عن
/// بروتوكول المركز العلاجي ولا عن حكم الطبيب المعالج.

enum Organ { hepatic, renal, both, none }

class DoseRule {
  /// شرط التطبيق — يُقيَّم على القيم المُدخلة.
  final bool Function(ChemoLabs labs) applies;

  /// نسبة الجرعة الموصى بها من الجرعة القياسية (0.0 = يُمنع).
  final double percent;

  /// سبب التعديل كما يظهر للمستخدم.
  final String reason;

  const DoseRule({
    required this.applies,
    required this.percent,
    required this.reason,
  });
}

class ChemoDrug {
  final String name;        // الاسم العلمي
  final String nameAr;
  final String standardDose; // الجرعة القياسية المرجعية
  final Organ organ;
  final String source;
  final List<DoseRule> rules;

  /// كاربوبلاتين يُحسب بمعادلة Calvert لا بنسبة من جرعة قياسية.
  final bool isCalvert;

  const ChemoDrug({
    required this.name,
    required this.nameAr,
    required this.standardDose,
    required this.organ,
    required this.source,
    required this.rules,
    this.isCalvert = false,
  });
}

/// القيم المخبرية المُدخلة.
class ChemoLabs {
  final double bilirubin;  // mg/dL
  final double ast;        // × ULN
  final double alp;        // × ULN
  final double crCl;       // mL/min
  final double anc;        // ×10⁹/L
  final double platelets;  // ×10⁹/L

  const ChemoLabs({
    this.bilirubin = 0,
    this.ast = 1,
    this.alp = 1,
    this.crCl = 120,
    this.anc = 3,
    this.platelets = 250,
  });
}

/// نتيجة التقييم لدواء واحد.
class DoseAdvice {
  final double percent;
  final String reason;
  final bool hold;
  const DoseAdvice(this.percent, this.reason, {this.hold = false});
}

DoseAdvice evaluate(ChemoDrug d, ChemoLabs labs) {
  for (final r in d.rules) {
    if (r.applies(labs)) {
      return DoseAdvice(r.percent, r.reason, hold: r.percent == 0);
    }
  }
  return const DoseAdvice(1.0, 'لا يحتاج تعديلاً بهذه القيم');
}

/// تأجيل الدورة بسبب كبت النقي — يُقيَّم مستقلاً عن الدواء.
String? marrowHold(ChemoLabs l) {
  if (l.anc < 1.0 && l.platelets < 75) {
    return 'العدلات ${l.anc.toStringAsFixed(1)}×10⁹/L والصفيحات '
        '${l.platelets.toStringAsFixed(0)}×10⁹/L، تُؤجَّل الدورة حتى التعافي';
  }
  if (l.anc < 1.0) {
    return 'العدلات ${l.anc.toStringAsFixed(1)}×10⁹/L (<1.0)، تُؤجَّل الدورة عادةً '
        'حتى ≥1.5، ويُراجَع استعمال G-CSF';
  }
  if (l.platelets < 75) {
    return 'الصفيحات ${l.platelets.toStringAsFixed(0)}×10⁹/L (<75)، تُؤجَّل الدورة '
        'عادةً حتى ≥100';
  }
  return null;
}

// ── جدول الأدوية ─────────────────────────────────────────────────────────────
const chemoDrugs = <ChemoDrug>[
  ChemoDrug(
    name: 'Doxorubicin',
    nameAr: 'دوكسوروبيسين',
    standardDose: '60–75 mg/m² كل ٢١ يوماً',
    organ: Organ.hepatic,
    source: 'FDA label · BC Cancer',
    rules: [
      DoseRule(applies: _biliOver5, percent: 0.0,
          reason: 'البيليروبين >5 mg/dL، يُمنع الإعطاء'),
      DoseRule(applies: _bili3to5, percent: 0.25,
          reason: 'البيليروبين 3.1–5 mg/dL، ٢٥٪ من الجرعة'),
      DoseRule(applies: _bili12to3, percent: 0.5,
          reason: 'البيليروبين 1.2–3 mg/dL، ٥٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Epirubicin',
    nameAr: 'إيبيروبيسين',
    standardDose: '60–120 mg/m² كل ٢١ يوماً',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver5, percent: 0.0,
          reason: 'البيليروبين >5 mg/dL، يُمنع الإعطاء'),
      DoseRule(applies: _bili3to5, percent: 0.25,
          reason: 'البيليروبين 3.1–5 mg/dL، ٢٥٪ من الجرعة'),
      DoseRule(applies: _bili12to3, percent: 0.5,
          reason: 'البيليروبين 1.2–3 mg/dL، ٥٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Vincristine',
    nameAr: 'فينكريستين',
    standardDose: '1.4 mg/m² (بحدّ أقصى 2 mg)',
    organ: Organ.hepatic,
    source: 'FDA label · NCCN',
    rules: [
      DoseRule(applies: _biliOver3, percent: 0.5,
          reason: 'البيليروبين >3 mg/dL، ٥٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Vinblastine',
    nameAr: 'فينبلاستين',
    standardDose: '6 mg/m²',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver3, percent: 0.0,
          reason: 'البيليروبين >3 mg/dL، يُمنع الإعطاء'),
      DoseRule(applies: _bili2to3, percent: 0.5,
          reason: 'البيليروبين 2.1–3 mg/dL، ٥٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Vinorelbine',
    nameAr: 'فينوريلبين',
    standardDose: '25–30 mg/m² أسبوعياً',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver3, percent: 0.25,
          reason: 'البيليروبين >3 mg/dL، ٢٥٪ من الجرعة'),
      DoseRule(applies: _bili2to3, percent: 0.5,
          reason: 'البيليروبين 2.1–3 mg/dL، ٥٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Paclitaxel',
    nameAr: 'باكليتاكسيل',
    standardDose: '175 mg/m² كل ٢١ يوماً',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver5, percent: 0.0,
          reason: 'البيليروبين >5× الحد الأعلى، لا يُوصى بالإعطاء'),
      DoseRule(applies: _bili2to5, percent: 0.5,
          reason: 'اختلال كبدي متوسط، خفض الجرعة إلى ٥٠٪ تقريباً'),
      DoseRule(applies: _astHigh, percent: 0.75,
          reason: 'ارتفاع الترانس أميناز، خفض أولي إلى ٧٥٪ مع مراقبة'),
    ],
  ),
  ChemoDrug(
    name: 'Docetaxel',
    nameAr: 'دوسيتاكسيل',
    standardDose: '75–100 mg/m² كل ٢١ يوماً',
    organ: Organ.hepatic,
    source: 'FDA label (تحذير صندوق أسود)',
    rules: [
      DoseRule(applies: _biliOverULN, percent: 0.0,
          reason: 'البيليروبين فوق الحد الأعلى، يُمنع الإعطاء (صندوق أسود)'),
      DoseRule(applies: _astAlpHigh, percent: 0.0,
          reason: 'AST/ALT >1.5× مع ALP >2.5×، يُمنع الإعطاء (صندوق أسود)'),
    ],
  ),
  ChemoDrug(
    name: 'Cisplatin',
    nameAr: 'سيسبلاتين',
    standardDose: '50–100 mg/m² كل ٢١ يوماً',
    organ: Organ.renal,
    source: 'FDA label · NCCN',
    rules: [
      DoseRule(applies: _crclUnder30, percent: 0.0,
          reason: 'CrCl <30 mL/min، يُمنع الإعطاء'),
      DoseRule(applies: _crcl30to45, percent: 0.5,
          reason: 'CrCl 30–45 mL/min، ٥٠٪ مع إماهة مكثّفة أو بديل كاربوبلاتين'),
      DoseRule(applies: _crcl45to60, percent: 0.75,
          reason: 'CrCl 45–60 mL/min، ٧٥٪ مع إماهة ومراقبة المغنيسيوم'),
    ],
  ),
  ChemoDrug(
    name: 'Carboplatin',
    nameAr: 'كاربوبلاتين',
    standardDose: 'معادلة Calvert: AUC × (GFR + 25)',
    organ: Organ.renal,
    source: 'Calvert et al. JCO 1989 · FDA label',
    isCalvert: true,
    rules: [],
  ),
  ChemoDrug(
    name: 'Capecitabine',
    nameAr: 'كابيسيتابين',
    standardDose: '1250 mg/m² مرتين يومياً × ١٤ يوماً',
    organ: Organ.renal,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _crclUnder30, percent: 0.0,
          reason: 'CrCl <30 mL/min، يُمنع الإعطاء'),
      DoseRule(applies: _crcl30to50, percent: 0.75,
          reason: 'CrCl 30–50 mL/min، ٧٥٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Methotrexate',
    nameAr: 'ميثوتريكسيت',
    standardDose: 'حسب البروتوكول',
    organ: Organ.renal,
    source: 'FDA label · Lexicomp',
    rules: [
      DoseRule(applies: _crclUnder10, percent: 0.0,
          reason: 'CrCl <10 mL/min، يُمنع الإعطاء'),
      DoseRule(applies: _crcl10to50, percent: 0.5,
          reason: 'CrCl 10–50 mL/min، ٥٠٪ مع قلونة البول وليوكوفورين'),
      DoseRule(applies: _crcl50to60, percent: 0.7,
          reason: 'CrCl 51–60 mL/min، ٧٠٪ من الجرعة'),
      DoseRule(applies: _crcl60to80, percent: 0.75,
          reason: 'CrCl 61–80 mL/min، ٧٥٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Etoposide',
    nameAr: 'إيتوبوسيد',
    standardDose: '100 mg/m² × ٣–٥ أيام',
    organ: Organ.both,
    source: 'FDA label · BC Cancer',
    rules: [
      DoseRule(applies: _crclUnder15, percent: 0.0,
          reason: 'CrCl <15 mL/min، لا توجد توصية؛ يُتجنّب'),
      DoseRule(applies: _bili15to3, percent: 0.5,
          reason: 'البيليروبين 1.5–3 mg/dL، ٥٠٪ من الجرعة'),
      DoseRule(applies: _crcl15to50, percent: 0.75,
          reason: 'CrCl 15–50 mL/min، ٧٥٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Irinotecan',
    nameAr: 'إيرينوتيكان',
    standardDose: '180 mg/m² كل أسبوعين',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver3, percent: 0.0,
          reason: 'البيليروبين >3 mg/dL، يُتجنّب'),
      DoseRule(applies: _bili15to3, percent: 0.5,
          reason: 'البيليروبين 1.5–3 mg/dL، خفض الجرعة ومراقبة الإسهال'),
    ],
  ),
  ChemoDrug(
    name: 'Pemetrexed',
    nameAr: 'بيميتريكسيد',
    standardDose: '500 mg/m² كل ٢١ يوماً',
    organ: Organ.renal,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _crclUnder45, percent: 0.0,
          reason: 'CrCl <45 mL/min، يُمنع الإعطاء'),
    ],
  ),
  ChemoDrug(
    name: 'Oxaliplatin',
    nameAr: 'أوكزاليبلاتين',
    standardDose: '85 mg/m² كل أسبوعين',
    organ: Organ.renal,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _crclUnder30, percent: 0.65,
          reason: 'CrCl <30 mL/min، خفض الجرعة الابتدائية ومراقبة السمّية'),
    ],
  ),
  ChemoDrug(
    name: 'Bleomycin',
    nameAr: 'بليومايسين',
    standardDose: '10–20 units/m²',
    organ: Organ.renal,
    source: 'Lexicomp · BC Cancer',
    rules: [
      DoseRule(applies: _crcl20to30, percent: 0.45,
          reason: 'CrCl 20–30 mL/min، ٤٥٪ من الجرعة'),
      DoseRule(applies: _crcl30to40, percent: 0.60,
          reason: 'CrCl 30–40 mL/min، ٦٠٪ من الجرعة'),
      DoseRule(applies: _crcl40to50, percent: 0.70,
          reason: 'CrCl 40–50 mL/min، ٧٠٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Cyclophosphamide',
    nameAr: 'سايكلوفوسفاميد',
    standardDose: '500–1000 mg/m²',
    organ: Organ.renal,
    source: 'Lexicomp',
    rules: [
      DoseRule(applies: _crclUnder10, percent: 0.75,
          reason: 'CrCl <10 mL/min، ٧٥٪ من الجرعة'),
    ],
  ),
  ChemoDrug(
    name: 'Fluorouracil (5-FU)',
    nameAr: 'فلورويوراسيل',
    standardDose: 'حسب البروتوكول',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _biliOver5, percent: 0.0,
          reason: 'البيليروبين >5 mg/dL، يُمنع الإعطاء'),
    ],
  ),
  ChemoDrug(
    name: 'Gemcitabine',
    nameAr: 'جيمسيتابين',
    standardDose: '1000 mg/m² أسبوعياً',
    organ: Organ.hepatic,
    source: 'FDA label',
    rules: [
      DoseRule(applies: _bili16plus, percent: 0.8,
          reason: 'البيليروبين >1.6 mg/dL، البدء بـ 800 mg/m²'),
    ],
  ),
];

// ── شروط مُسمّاة (دوال ثابتة ليبقى الجدول const) ────────────────────────────
bool _biliOverULN(ChemoLabs l) => l.bilirubin > 1.0;
bool _bili12to3(ChemoLabs l) => l.bilirubin >= 1.2 && l.bilirubin <= 3.0;
bool _bili15to3(ChemoLabs l) => l.bilirubin >= 1.5 && l.bilirubin <= 3.0;
bool _bili2to3(ChemoLabs l) => l.bilirubin > 2.0 && l.bilirubin <= 3.0;
bool _bili2to5(ChemoLabs l) => l.bilirubin > 2.0 && l.bilirubin <= 5.0;
bool _bili3to5(ChemoLabs l) => l.bilirubin > 3.0 && l.bilirubin <= 5.0;
bool _biliOver3(ChemoLabs l) => l.bilirubin > 3.0;
bool _biliOver5(ChemoLabs l) => l.bilirubin > 5.0;
bool _bili16plus(ChemoLabs l) => l.bilirubin > 1.6;
bool _astHigh(ChemoLabs l) => l.ast > 1.5;
bool _astAlpHigh(ChemoLabs l) => l.ast > 1.5 && l.alp > 2.5;

bool _crclUnder10(ChemoLabs l) => l.crCl < 10;
bool _crclUnder15(ChemoLabs l) => l.crCl < 15;
bool _crclUnder30(ChemoLabs l) => l.crCl < 30;
bool _crclUnder45(ChemoLabs l) => l.crCl < 45;
bool _crcl10to50(ChemoLabs l) => l.crCl >= 10 && l.crCl <= 50;
bool _crcl15to50(ChemoLabs l) => l.crCl >= 15 && l.crCl <= 50;
bool _crcl20to30(ChemoLabs l) => l.crCl >= 20 && l.crCl < 30;
bool _crcl30to40(ChemoLabs l) => l.crCl >= 30 && l.crCl < 40;
bool _crcl30to45(ChemoLabs l) => l.crCl >= 30 && l.crCl < 45;
bool _crcl30to50(ChemoLabs l) => l.crCl >= 30 && l.crCl <= 50;
bool _crcl40to50(ChemoLabs l) => l.crCl >= 40 && l.crCl < 50;
bool _crcl45to60(ChemoLabs l) => l.crCl >= 45 && l.crCl < 60;
bool _crcl50to60(ChemoLabs l) => l.crCl > 50 && l.crCl <= 60;
bool _crcl60to80(ChemoLabs l) => l.crCl > 60 && l.crCl <= 80;
