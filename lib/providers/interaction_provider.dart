import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/drug_model.dart';

/// The list of drugs the user has added to the checker.
final checkerDrugsProvider =
    StateNotifierProvider<CheckerDrugsNotifier, List<Drug>>(
        (_) => CheckerDrugsNotifier());

class CheckerDrugsNotifier extends StateNotifier<List<Drug>> {
  CheckerDrugsNotifier() : super([]);

  void add(Drug drug) {
    if (state.any((d) => d.id == drug.id)) return;
    state = [...state, drug];
  }

  void remove(int drugId) =>
      state = state.where((d) => d.id != drugId).toList();

  void clear() => state = [];
}

// ── Severity levels ──────────────────────────────────────────────────────────

enum InteractionSeverity { major, moderate, minor }

class DrugInteraction {
  final String drug1;
  final String drug2;
  final InteractionSeverity severity;
  final String description;
  final String descriptionAr;

  const DrugInteraction({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    required this.descriptionAr,
  });
}

// ── Static interaction knowledge base ────────────────────────────────────────
// KEY RULE: each key is a pair of lowercase generic names sorted alphabetically
// and joined with '|'. The lookup code does the same sort, so order MUST match.
// To verify: for pair (A, B), key = ([A,B]..sort()).join('|')

const _kb = <String, (InteractionSeverity, String, String)>{
  // ── MAJOR ──────────────────────────────────────────────────────────────────

  // Serotonin syndrome group
  'amitriptyline|tramadol': (
    InteractionSeverity.major,
    'Both lower seizure threshold and both have serotonergic activity. Risk of serotonin syndrome and seizures.',
    'كلاهما يخفض عتبة التشنج ولهما نشاط سيروتونيني. خطر متلازمة السيروتونين والتشنجات.',
  ),
  'fluoxetine|tramadol': (
    InteractionSeverity.major,
    'Serotonin syndrome + fluoxetine inhibits CYP2D6 reducing tramadol active metabolite (M1), reducing analgesia.',
    'متلازمة السيروتونين + فلوكستين يثبط CYP2D6 فيقلل المستقلب النشط M1 ويضعف المسكن.',
  ),
  'paroxetine|tramadol': (
    InteractionSeverity.major,
    'Serotonin syndrome + CYP2D6 inhibition reduces tramadol efficacy. Avoid.',
    'متلازمة السيروتونين + تثبيط CYP2D6. تجنب.',
  ),
  'sertraline|tramadol': (
    InteractionSeverity.major,
    'Serotonin syndrome risk. Avoid combination. If required, monitor closely for agitation, tremor, hyperthermia, tachycardia.',
    'خطر متلازمة السيروتونين. تجنب الجمع. إذا اضطررت راقب التهيج، الرعشة، الحرارة المرتفعة، سرعة القلب.',
  ),

  // Warfarin interactions
  'aspirin|warfarin': (
    InteractionSeverity.major,
    'Dual anticoagulation + GI risk. Major bleeding risk (3-4x). Avoid unless cardiologist recommended.',
    'تضاعف مضادات التخثر + خطر هضمي. خطر نزيف كبير (3-4x). تجنب إلا بتوصية قلبية.',
  ),
  'ciprofloxacin|warfarin': (
    InteractionSeverity.major,
    'Ciprofloxacin inhibits CYP1A2/2C9, significantly elevating warfarin INR. Monitor INR closely, expect 30-50% dose reduction.',
    'سيبروفلوكساسين يثبط CYP1A2/2C9 ويرفع INR بشكل ملحوظ. راقب INR، قد تحتاج تقليل وارفارين 30-50%.',
  ),
  'clarithromycin|warfarin': (
    InteractionSeverity.major,
    'Clarithromycin (CYP3A4 inhibitor) significantly increases warfarin effect. Monitor INR every 2-3 days.',
    'كلاريثروميسين (مثبط CYP3A4) يرفع تأثير الوارفارين بشكل ملحوظ. راقب INR كل 2-3 أيام.',
  ),
  'metronidazole|warfarin': (
    InteractionSeverity.major,
    'Metronidazole strongly inhibits CYP2C9, raising warfarin levels significantly. INR may double. Monitor closely.',
    'ميترونيدازول يثبط CYP2C9 بقوة، يرفع الوارفارين بشكل ملحوظ. INR قد يتضاعف. راقب بدقة.',
  ),

  // Opioid + CNS depressant
  'diazepam|morphine': (
    InteractionSeverity.major,
    'CNS and respiratory depression synergy. Combination can be fatal. If both required, use lowest doses and monitor breathing.',
    'تآزر اكتئاب الجهاز العصبي والتنفسي. الجمع قد يكون مميتاً. إذا اضطررت استخدم أدنى الجرعات وراقب التنفس.',
  ),
  'lorazepam|morphine': (
    InteractionSeverity.major,
    'Additive CNS/respiratory depression. Increased risk of fatal respiratory depression. FDA boxed warning.',
    'اكتئاب تنفسي/CNS تراكمي. خطر اكتئاب تنفسي مميت. تحذير FDA.',
  ),
  'diazepam|tramadol': (
    InteractionSeverity.major,
    'Additive CNS and respiratory depression. Use with extreme caution; monitor for excessive sedation.',
    'اكتئاب CNS والتنفس تراكمي. استخدم بحذر شديد؛ راقب للتخدير المفرط.',
  ),
  'codeine|diazepam': (
    InteractionSeverity.major,
    'Opioid + benzodiazepine combination. Risk of fatal respiratory depression. FDA boxed warning.',
    'مخدر + بنزوديازيبين. خطر اكتئاب تنفسي مميت. تحذير FDA.',
  ),

  // Digoxin interactions
  'amiodarone|digoxin': (
    InteractionSeverity.major,
    'Amiodarone inhibits P-gp and CYP2D6, raising digoxin levels up to 70-100%. Reduce digoxin 50% and monitor levels.',
    'أميودارون يثبط P-gp وCYP2D6، يرفع الديجوكسين 70-100%. قلل الديجوكسين 50% وراقب المستويات.',
  ),
  'clarithromycin|digoxin': (
    InteractionSeverity.major,
    'Clarithromycin inhibits P-gp, raising digoxin levels. Risk of toxicity (nausea, arrhythmia, visual disturbance).',
    'كلاريثروميسين يثبط P-gp ويرفع الديجوكسين. خطر سمية (غثيان، اضطراب إيقاع، اضطراب بصري).',
  ),

  // Carbamazepine interactions
  'carbamazepine|clarithromycin': (
    InteractionSeverity.major,
    'Clarithromycin strongly inhibits CYP3A4 → carbamazepine levels rise dramatically → ataxia, diplopia, seizures.',
    'كلاريثروميسين يثبط CYP3A4 بقوة → ارتفاع حاد في كاربامازيبين → رنح، ازدواج رؤية، نوبات.',
  ),
  'carbamazepine|oral contraceptives': (
    InteractionSeverity.major,
    'Carbamazepine (CYP3A4 inducer) reduces oral contraceptive levels → contraceptive failure. Use alternative contraception.',
    'كاربامازيبين يُحرض CYP3A4 ويقلل مستويات حبوب منع الحمل → فشل منع الحمل. استخدم وسيلة بديلة.',
  ),
  'carbamazepine|valproate': (
    InteractionSeverity.major,
    'Carbamazepine induces valproate metabolism (reduces levels). Valproate increases carbamazepine epoxide (toxic metabolite). Monitor both.',
    'كاربامازيبين يحرض استقلاب فالبرويات (يقللها). فالبرويات ترفع مستقلب الإيبوكسيد السام لكاربامازيبين. راقب كليهما.',
  ),

  // Statin interactions
  'clarithromycin|simvastatin': (
    InteractionSeverity.major,
    'Clarithromycin inhibits CYP3A4 → simvastatin AUC increases 10-fold → rhabdomyolysis. AVOID. Use pravastatin instead.',
    'كلاريثروميسين يرفع سيمفاستاتين 10 أضعاف → انحلال عضلي. ممنوع. استخدم برافاستاتين بدلاً.',
  ),

  // QT-prolonging combinations
  'amiodarone|azithromycin': (
    InteractionSeverity.major,
    'Both prolong QTc. Risk of torsades de pointes. Avoid. If required, monitor ECG.',
    'كلاهما يُطيل QTc. خطر توترات النقاط. تجنب. إذا اضطررت راقب ECG.',
  ),
  'amiodarone|levofloxacin': (
    InteractionSeverity.major,
    'Both prolong QTc significantly. High risk of torsades de pointes. Avoid combination.',
    'كلاهما يُطيل QTc بشكل ملحوظ. خطر عالٍ لتوترات النقاط. تجنب الجمع.',
  ),
  'amiodarone|ciprofloxacin': (
    InteractionSeverity.major,
    'Both prolong QTc. Risk of torsades de pointes and fatal arrhythmia. Avoid.',
    'كلاهما يُطيل QTc. خطر توترات النقاط وعدم انتظام إيقاع مميت. تجنب.',
  ),

  // Anticoagulant + antiplatelet
  'aspirin|enoxaparin': (
    InteractionSeverity.major,
    'Additive bleeding risk. Dual anticoagulation/antiplatelet. Monitor closely for bleeding signs.',
    'خطر نزيف تراكمي. مراقبة علامات النزيف.',
  ),

  // Ototoxicity
  'furosemide|vancomycin': (
    InteractionSeverity.major,
    'Additive ototoxicity. Avoid combination if possible. If required, use lowest effective vancomycin dose and monitor hearing.',
    'سمية أذن تراكمية. تجنب الجمع إن أمكن. إذا اضطررت استخدم أدنى جرعة فانكوميسين وراقب السمع.',
  ),
  'furosemide|gentamicin': (
    InteractionSeverity.major,
    'Additive nephrotoxicity and ototoxicity. Both damage kidneys and hearing. Monitor renal function and hearing.',
    'سمية كلوية وسمعية تراكمية. كلاهما يتلف الكلى والسمع. راقب وظائف الكلى والسمع.',
  ),

  // CYP interactions
  'ciprofloxacin|tizanidine': (
    InteractionSeverity.major,
    'Ciprofloxacin inhibits CYP1A2 → tizanidine levels rise 10-fold → severe hypotension, sedation. ABSOLUTE CONTRAINDICATION.',
    'سيبروفلوكساسين يثبط CYP1A2 → ارتفاع تيزانيدين 10 أضعاف → انخفاض ضغط شديد، تخدير شديد. ممنوع تماماً.',
  ),
  'ciprofloxacin|theophylline': (
    InteractionSeverity.major,
    'Ciprofloxacin inhibits CYP1A2 → theophylline levels rise 2-3x → nausea, seizures, arrhythmia. Reduce theophylline 50%.',
    'سيبروفلوكساسين يثبط CYP1A2 → ارتفاع ثيوفيلين 2-3x → غثيان، تشنجات، اضطراب إيقاع. قلل ثيوفيلين 50%.',
  ),

  // Antiepileptic
  'meropenem|valproate': (
    InteractionSeverity.major,
    'Meropenem reduces valproate levels up to 80% within 24h. Switch anticonvulsant or choose alternative antibiotic.',
    'ميروبينيم يقلل فالبرويات حتى 80% خلال 24 ساعة. غيّر مضاد الصرع أو استخدم مضاداً حيوياً بديلاً.',
  ),
  'phenytoin|valproate': (
    InteractionSeverity.major,
    'Complex bidirectional interaction: valproate displaces phenytoin from protein binding then inhibits metabolism. Monitor free phenytoin levels.',
    'تفاعل ثنائي الاتجاه: فالبرويات تُزيح فينيتوين من ارتباطه البروتيني ثم تثبط استقلابه. راقب مستوى الفينيتوين الحر.',
  ),

  // Dermatology
  'doxycycline|isotretinoin': (
    InteractionSeverity.major,
    'Both can cause intracranial hypertension (pseudotumor cerebri). AVOID combination.',
    'كلاهما يمكن أن يسبب ارتفاع ضغط داخل الجمجمة. ممنوع الجمع.',
  ),

  // Metformin
  'contrast|metformin': (
    InteractionSeverity.major,
    'IV contrast may cause AKI → metformin accumulation → lactic acidosis. Hold metformin 48h before/after IV contrast.',
    'الصبغة الوريدية قد تسبب قصوراً كلوياً → تراكم ميتفورمين → حماض لاكتيكي. أوقف ميتفورمين 48 ساعة قبل وبعد.',
  ),

  // Alcohol
  'alcohol|metronidazole': (
    InteractionSeverity.major,
    'Disulfiram-like reaction: flushing, nausea, vomiting, tachycardia, hypotension. Avoid alcohol during and 48h after.',
    'تفاعل يشبه ديسلفيرام: احمرار، غثيان، قيء، سرعة قلب، انخفاض ضغط. تجنب الكحول أثناء وبعد 48 ساعة.',
  ),

  // Clopidogrel + PPI
  'clopidogrel|omeprazole': (
    InteractionSeverity.major,
    'Omeprazole inhibits CYP2C19, reducing clopidogrel activation by up to 50%. Use pantoprazole instead.',
    'أوميبرازول يثبط CYP2C19 ويقلل تفعيل كلوبيدوجريل حتى 50%. استخدم بانتوبرازول بدلاً.',
  ),

  // Methotrexate
  'ibuprofen|methotrexate': (
    InteractionSeverity.major,
    'NSAIDs reduce renal methotrexate clearance → severe toxicity (myelosuppression, mucositis). Avoid. Use paracetamol.',
    'NSAIDs تقلل إطراح الميثوتريكسيت الكلوي → سمية شديدة (كبت نقي، التهاب مخاطية). تجنب. استخدم باراسيتامول.',
  ),

  // ── MODERATE ───────────────────────────────────────────────────────────────

  'aspirin|ibuprofen': (
    InteractionSeverity.moderate,
    'Ibuprofen competitively blocks COX-1, reducing aspirin cardioprotective effect. Take aspirin 30 min before ibuprofen.',
    'إيبوبروفين يتنافس مع أسبرين على COX-1 ويقلل تأثيره الوقائي للقلب. تناول أسبرين قبل إيبوبروفين بـ 30 دقيقة.',
  ),
  'amoxicillin|warfarin': (
    InteractionSeverity.moderate,
    'Antibiotics reduce gut flora → less vitamin K production → INR rise. Monitor INR.',
    'المضادات الحيوية تقلل فلورا الأمعاء → أقل إنتاج لفيتامين K → ارتفاع INR. راقب.',
  ),
  'diclofenac|warfarin': (
    InteractionSeverity.moderate,
    'Diclofenac (CYP2C9 substrate/inhibitor) raises warfarin levels and GI risk.',
    'ديكلوفيناك يرفع وارفارين وخطر النزيف الهضمي.',
  ),
  'ibuprofen|warfarin': (
    InteractionSeverity.moderate,
    'NSAIDs increase INR and GI bleeding risk. Use paracetamol instead. If NSAID required, monitor INR closely.',
    'NSAIDs ترفع INR وخطر النزيف الهضمي. استخدم باراسيتامول. إذا احتجت NSAID راقب INR.',
  ),
  'naproxen|warfarin': (
    InteractionSeverity.moderate,
    'Same as ibuprofen-warfarin. Moderate INR increase + GI bleeding risk.',
    'مثل إيبوبروفين-وارفارين. ارتفاع INR متوسط + خطر نزيف هضمي.',
  ),
  'amlodipine|simvastatin': (
    InteractionSeverity.moderate,
    'Amlodipine (weak CYP3A4 inhibitor) raises simvastatin levels modestly. Simvastatin max dose 20 mg/day with amlodipine.',
    'أملوديبين يرفع سيمفاستاتين بشكل طفيف. الحد الأقصى لسيمفاستاتين 20 ملغ/يوم مع أملوديبين.',
  ),
  'carbamazepine|phenytoin': (
    InteractionSeverity.moderate,
    'Mutual induction: carbamazepine reduces phenytoin levels. Phenytoin may also reduce carbamazepine. Monitor both levels.',
    'تحريض متبادل: كاربامازيبين يقلل فينيتوين والعكس. راقب مستويات كليهما.',
  ),
  'cetirizine|lorazepam': (
    InteractionSeverity.moderate,
    'Additive CNS depression (sedation). Avoid driving. Use non-sedating antihistamine if needed.',
    'اكتئاب CNS تراكمي (تخدير). تجنب القيادة. استخدم مضاد الهيستامين غير المخدر إن أمكن.',
  ),
  'ciprofloxacin|glibenclamide': (
    InteractionSeverity.moderate,
    'Ciprofloxacin enhances sulfonylurea hypoglycemic effect. Monitor glucose closely.',
    'سيبروفلوكساسين يعزز تأثير نقص السكر للسلفونيلوريا. راقب السكر بدقة.',
  ),
  'ciprofloxacin|metformin': (
    InteractionSeverity.moderate,
    'Ciprofloxacin may cause hypoglycemia by direct insulin release stimulation. Monitor blood glucose.',
    'سيبروفلوكساسين قد يسبب نقص سكر عبر تحريض إفراز الأنسولين. راقب السكر.',
  ),
  'ciprofloxacin|simvastatin': (
    InteractionSeverity.moderate,
    'Minor CYP3A4 inhibition. Monitor for myopathy. Consider rosuvastatin (not CYP3A4 substrate).',
    'تثبيط طفيف لـ CYP3A4. راقب اعتلال العضل. فكر في روزوفاستاتين.',
  ),
  'digoxin|furosemide': (
    InteractionSeverity.moderate,
    'Furosemide causes hypokalemia which sensitizes the heart to digoxin toxicity. Monitor K+ and digoxin levels.',
    'فروسيميد يسبب نقص بوتاسيوم يُحسس القلب لسمية الديجوكسين. راقب K+ ومستوى الديجوكسين.',
  ),
  'digoxin|spironolactone': (
    InteractionSeverity.moderate,
    'Spironolactone reduces digoxin renal clearance → raised digoxin levels. Monitor digoxin.',
    'سبيرونولاكتون يقلل إطراح الديجوكسين → ارتفاع مستوياته. راقب الديجوكسين.',
  ),
  'furosemide|metformin': (
    InteractionSeverity.moderate,
    'Furosemide may increase metformin levels by reducing renal clearance. Risk of lactic acidosis in dehydration.',
    'فروسيميد قد يرفع مستويات ميتفورمين بتقليل الإطراح الكلوي. خطر حماض لاكتيكي مع الجفاف.',
  ),
  'ibuprofen|prednisolone': (
    InteractionSeverity.moderate,
    'Corticosteroids + NSAIDs: additive GI ulcer risk (up to 15x). Add PPI if combination unavoidable.',
    'كورتيكوستيرويدات + NSAIDs: خطر قرحة هضمية تراكمي (حتى 15x). أضف PPI إذا لزم الجمع.',
  ),
  'calcium|levothyroxine': (
    InteractionSeverity.moderate,
    'Calcium chelates levothyroxine reducing absorption by up to 40%. Separate by at least 4 hours.',
    'الكالسيوم يتخلط مع ليفوثيروكسين ويقلل امتصاصه حتى 40%. فصل بـ 4 ساعات على الأقل.',
  ),
  'iron|levothyroxine': (
    InteractionSeverity.moderate,
    'Iron reduces levothyroxine absorption by up to 50%. Separate by at least 4 hours.',
    'الحديد يقلل امتصاص ليفوثيروكسين حتى 50%. فصل 4 ساعات على الأقل.',
  ),
  'lisinopril|spironolactone': (
    InteractionSeverity.moderate,
    'Both raise potassium. Risk of life-threatening hyperkalemia, especially in CKD. Monitor K+ and renal function.',
    'كلاهما يرفع البوتاسيوم. خطر فرط بوتاسيوم مهدد للحياة خاصة في CKD. راقب K+ ووظائف الكلى.',
  ),
  'metformin|prednisolone': (
    InteractionSeverity.moderate,
    'Corticosteroids cause insulin resistance and hyperglycemia, antagonizing metformin. Monitor glucose, may need insulin.',
    'الكورتيكوستيرويدات تسبب مقاومة الأنسولين وارتفاع السكر، تضاد ميتفورمين. راقب السكر، قد تحتاج أنسولين.',
  ),
  'metronidazole|phenobarbital': (
    InteractionSeverity.moderate,
    'Phenobarbital (CYP inducer) reduces metronidazole levels. May require higher metronidazole doses.',
    'فينوباربيتال (محرض CYP) يقلل مستويات ميترونيدازول. قد تحتاج جرعة أعلى.',
  ),
  'ibuprofen|lithium': (
    InteractionSeverity.moderate,
    'NSAIDs reduce renal lithium clearance → lithium toxicity (tremor, ataxia, confusion). Use paracetamol instead.',
    'NSAIDs تقلل إطراح الليثيوم الكلوي → سمية ليثيوم (رعشة، رنح، ارتباك). استخدم باراسيتامول بدلاً.',
  ),

  // ── MINOR ──────────────────────────────────────────────────────────────────

  'amlodipine|atorvastatin': (
    InteractionSeverity.minor,
    'Amlodipine mildly raises atorvastatin levels. No dose adjustment needed. Monitor for muscle symptoms.',
    'أملوديبين يرفع أتورفاستاتين بشكل طفيف. لا تعديل جرعة. راقب أعراض العضل.',
  ),
  'furosemide|spironolactone': (
    InteractionSeverity.minor,
    'Complementary diuretic combination — used intentionally. Monitor electrolytes (opposite K+ effects may balance).',
    'تركيب مدرات تكاملي — يُستخدم قصداً. راقب الإلكتروليتات (تأثيرات K+ المتعاكسة قد تتوازن).',
  ),
  'insulin lispro|sitagliptin': (
    InteractionSeverity.minor,
    'Additive hypoglycemia when combined. Reduce insulin dose by 10-20% when adding sitagliptin.',
    'نقص سكر تراكمي عند الجمع. قلل جرعة الأنسولين 10-20% عند إضافة سيتاغليبتين.',
  ),
};

// ── Lookup helpers ───────────────────────────────────────────────────────────

/// Normalise a drug name to a canonical lookup form:
/// lowercase, collapse whitespace, strip hyphens.
String _norm(String name) =>
    name.toLowerCase().trim().replaceAll(RegExp(r'[-\s]+'), ' ');

/// Build the canonical sorted key from two normalised names.
String _key(String a, String b) => ([a, b]..sort()).join('|');

/// Check if name [a] "matches" a KB token [t]:
/// exact OR one contains the other (handles "insulin lispro" vs "lispro").
bool _matches(String a, String t) =>
    a == t || a.contains(t) || t.contains(a);

// ── Public API ───────────────────────────────────────────────────────────────

List<DrugInteraction> findInteractions(List<Drug> drugs) {
  final result = <DrugInteraction>[];

  for (int i = 0; i < drugs.length; i++) {
    for (int j = i + 1; j < drugs.length; j++) {
      final na = _norm(drugs[i].genericName);
      final nb = _norm(drugs[j].genericName);

      // ── 1. Exact key match (fast path) ────────────────────────────────────
      final exactKey = _key(na, nb);
      if (_kb.containsKey(exactKey)) {
        final (sev, en, ar) = _kb[exactKey]!;
        result.add(DrugInteraction(
          drug1: drugs[i].genericName,
          drug2: drugs[j].genericName,
          severity: sev,
          description: en,
          descriptionAr: ar,
        ));
        continue;
      }

      // ── 2. Token-based partial match ──────────────────────────────────────
      // Handles brand/INN name variations and multi-word generics.
      bool found = false;
      for (final kbKey in _kb.keys) {
        final parts = kbKey.split('|'); // already sorted
        final t0 = parts[0];
        final t1 = parts[1];

        // Try both orderings of (na, nb) against (t0, t1)
        final match =
            (_matches(na, t0) && _matches(nb, t1)) ||
            (_matches(na, t1) && _matches(nb, t0));

        if (match) {
          final (sev, en, ar) = _kb[kbKey]!;
          result.add(DrugInteraction(
            drug1: drugs[i].genericName,
            drug2: drugs[j].genericName,
            severity: sev,
            description: en,
            descriptionAr: ar,
          ));
          found = true;
          break;
        }
      }
      if (found) continue;
    }
  }

  // Sort by severity (major first)
  result.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return result;
}
