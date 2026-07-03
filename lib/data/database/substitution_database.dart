import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DrugClass {
  final int id;
  final String className;
  const DrugClass({required this.id, required this.className});
}

class ActiveIngredient {
  final int id;
  final String scientificName;
  final int classId;
  const ActiveIngredient(
      {required this.id,
      required this.scientificName,
      required this.classId});
}

class CommercialBrand {
  final int id;
  final String brandName;
  final String company;
  final int ingredientId;
  const CommercialBrand(
      {required this.id,
      required this.brandName,
      required this.company,
      required this.ingredientId});
}

class SubstitutionResult {
  final String searchedBrand;
  final String activeIngredient;
  final String drugClass;
  final List<CommercialBrand> directAlternatives;   // نفس المادة الفعالة
  final List<_TherapeuticGroup> therapeuticGroups;  // نفس العائلة، مادة مختلفة

  const SubstitutionResult({
    required this.searchedBrand,
    required this.activeIngredient,
    required this.drugClass,
    required this.directAlternatives,
    required this.therapeuticGroups,
  });

  bool get hasResults =>
      directAlternatives.isNotEmpty || therapeuticGroups.isNotEmpty;
}

class _TherapeuticGroup {
  final String ingredientName;
  final List<CommercialBrand> brands;
  const _TherapeuticGroup(
      {required this.ingredientName, required this.brands});
}

// ── Database Helper ───────────────────────────────────────────────────────────

class SubstitutionDatabase {
  static SubstitutionDatabase? _instance;
  static Database? _db;

  SubstitutionDatabase._();
  static SubstitutionDatabase get instance =>
      _instance ??= SubstitutionDatabase._();

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'substitution.db');
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS commercial_brands');
        await db.execute('DROP TABLE IF EXISTS active_ingredients');
        await db.execute('DROP TABLE IF EXISTS drug_classes');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drug_classes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE active_ingredients (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        scientific_name TEXT NOT NULL,
        class_id        INTEGER NOT NULL,
        FOREIGN KEY (class_id) REFERENCES drug_classes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE commercial_brands (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_name    TEXT NOT NULL,
        ingredient_id INTEGER NOT NULL,
        company       TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (ingredient_id) REFERENCES active_ingredients(id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // ══════════════════════════════════════════════════════════════════
    // 1. مضادات التقيؤ — Antiemetics
    // ══════════════════════════════════════════════════════════════════
    final c1 = await db.insert('drug_classes', {'class_name': 'Antiemetics (مضادات التقيؤ)'});
    final ondansetron    = await db.insert('active_ingredients', {'scientific_name': 'Ondansetron',    'class_id': c1});
    final metoclopramide = await db.insert('active_ingredients', {'scientific_name': 'Metoclopramide', 'class_id': c1});
    final domperidone    = await db.insert('active_ingredients', {'scientific_name': 'Domperidone',    'class_id': c1});
    final granisetron    = await db.insert('active_ingredients', {'scientific_name': 'Granisetron',    'class_id': c1});

    for (final b in [
      {'brand_name': 'Zofran',          'company': 'GSK',                   'ingredient_id': ondansetron},
      {'brand_name': 'Emidoxyn',        'company': 'Pharmacare/UAE',        'ingredient_id': ondansetron},
      {'brand_name': 'Onsia',           'company': 'Julphar',               'ingredient_id': ondansetron},
      {'brand_name': 'Ondancen-8',      'company': 'Ocean Pharma',          'ingredient_id': ondansetron},
      {'brand_name': 'Ondacet',         'company': 'Jamjoom',               'ingredient_id': ondansetron},
      {'brand_name': 'Vomitrol',        'company': 'Hikma',                 'ingredient_id': ondansetron},
      {'brand_name': 'Primperan',       'company': 'Sanofi',                'ingredient_id': metoclopramide},
      {'brand_name': 'Plasil',          'company': 'Sanofi',                'ingredient_id': metoclopramide},
      {'brand_name': 'Motilium',        'company': 'J&J / Janssen',         'ingredient_id': domperidone},
      {'brand_name': 'Domperidone SDI', 'company': 'SDI (Samarra - Iraq)',  'ingredient_id': domperidone},
      {'brand_name': 'Kytril',          'company': 'Roche',                 'ingredient_id': granisetron},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 2. مثبطات مضخة البروتون — PPIs
    // ══════════════════════════════════════════════════════════════════
    final c2 = await db.insert('drug_classes', {'class_name': 'Proton Pump Inhibitors - PPIs (مثبطات مضخة البروتون)'});
    final omeprazole    = await db.insert('active_ingredients', {'scientific_name': 'Omeprazole',    'class_id': c2});
    final pantoprazole  = await db.insert('active_ingredients', {'scientific_name': 'Pantoprazole',  'class_id': c2});
    final esomeprazole  = await db.insert('active_ingredients', {'scientific_name': 'Esomeprazole',  'class_id': c2});
    final lansoprazole  = await db.insert('active_ingredients', {'scientific_name': 'Lansoprazole',  'class_id': c2});
    final rabeprazole   = await db.insert('active_ingredients', {'scientific_name': 'Rabeprazole',   'class_id': c2});
    final dexlansoprazole = await db.insert('active_ingredients', {'scientific_name': 'Dexlansoprazole', 'class_id': c2});

    for (final b in [
      {'brand_name': 'Losec',        'company': 'AstraZeneca',          'ingredient_id': omeprazole},
      {'brand_name': 'Omez',         'company': "Dr. Reddy's",          'ingredient_id': omeprazole},
      {'brand_name': 'Gasec',        'company': 'Julphar',              'ingredient_id': omeprazole},
      {'brand_name': 'Omeprazole SDI','company': 'SDI (Samarra - Iraq)','ingredient_id': omeprazole},
      {'brand_name': 'Prilosec',     'company': 'P&G / AstraZeneca',   'ingredient_id': omeprazole},
      {'brand_name': 'Protonix',     'company': 'Pfizer',               'ingredient_id': pantoprazole},
      {'brand_name': 'Pantoloc',     'company': 'Takeda',               'ingredient_id': pantoprazole},
      {'brand_name': 'Controloc',    'company': 'Takeda',               'ingredient_id': pantoprazole},
      {'brand_name': 'Pantaz',       'company': 'Julphar',              'ingredient_id': pantoprazole},
      {'brand_name': 'Nexium',       'company': 'AstraZeneca',          'ingredient_id': esomeprazole},
      {'brand_name': 'Esoz',         'company': 'Julphar',              'ingredient_id': esomeprazole},
      {'brand_name': 'Emanera',      'company': 'Krka',                 'ingredient_id': esomeprazole},
      {'brand_name': 'Lanzor',       'company': 'Abbott',               'ingredient_id': lansoprazole},
      {'brand_name': 'Lupizole',     'company': 'Lupin',                'ingredient_id': lansoprazole},
      {'brand_name': 'Pariet',       'company': 'Eisai / Janssen',      'ingredient_id': rabeprazole},
      {'brand_name': 'Dexilant',     'company': 'Takeda',               'ingredient_id': dexlansoprazole},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 3. حاصرات بيتا — Beta Blockers
    // ══════════════════════════════════════════════════════════════════
    final c3 = await db.insert('drug_classes', {'class_name': 'Beta Blockers (حاصرات بيتا)'});
    final atenolol    = await db.insert('active_ingredients', {'scientific_name': 'Atenolol',    'class_id': c3});
    final metoprolol  = await db.insert('active_ingredients', {'scientific_name': 'Metoprolol',  'class_id': c3});
    final bisoprolol  = await db.insert('active_ingredients', {'scientific_name': 'Bisoprolol',  'class_id': c3});
    final carvedilol  = await db.insert('active_ingredients', {'scientific_name': 'Carvedilol',  'class_id': c3});
    final propranolol = await db.insert('active_ingredients', {'scientific_name': 'Propranolol', 'class_id': c3});

    for (final b in [
      {'brand_name': 'Tenormin',    'company': 'AstraZeneca',          'ingredient_id': atenolol},
      {'brand_name': 'Lopressor',   'company': 'Novartis',             'ingredient_id': metoprolol},
      {'brand_name': 'Betaloc',     'company': 'AstraZeneca',          'ingredient_id': metoprolol},
      {'brand_name': 'Concor',      'company': 'Merck',                'ingredient_id': bisoprolol},
      {'brand_name': 'Bisogamma',   'company': 'Worwag/Hikma',         'ingredient_id': bisoprolol},
      {'brand_name': 'Coreg',       'company': 'GSK',                  'ingredient_id': carvedilol},
      {'brand_name': 'Dilatrend',   'company': 'Roche',                'ingredient_id': carvedilol},
      {'brand_name': 'Inderal',     'company': 'AstraZeneca',          'ingredient_id': propranolol},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 4. مثبطات ACE وحاصرات الأنجيوتنسين — ACE Inhibitors & ARBs
    // ══════════════════════════════════════════════════════════════════
    final c4 = await db.insert('drug_classes', {'class_name': 'ACE Inhibitors & ARBs (مثبطات الإنزيم المحول وحاصرات الأنجيوتنسين)'});
    final enalapril    = await db.insert('active_ingredients', {'scientific_name': 'Enalapril',    'class_id': c4});
    final lisinopril   = await db.insert('active_ingredients', {'scientific_name': 'Lisinopril',   'class_id': c4});
    final captopril    = await db.insert('active_ingredients', {'scientific_name': 'Captopril',    'class_id': c4});
    final perindopril  = await db.insert('active_ingredients', {'scientific_name': 'Perindopril',  'class_id': c4});
    final losartan     = await db.insert('active_ingredients', {'scientific_name': 'Losartan',     'class_id': c4});
    final valsartan    = await db.insert('active_ingredients', {'scientific_name': 'Valsartan',    'class_id': c4});
    final telmisartan  = await db.insert('active_ingredients', {'scientific_name': 'Telmisartan',  'class_id': c4});
    final candesartan  = await db.insert('active_ingredients', {'scientific_name': 'Candesartan',  'class_id': c4});
    final irbesartan   = await db.insert('active_ingredients', {'scientific_name': 'Irbesartan',   'class_id': c4});
    final olmesartan   = await db.insert('active_ingredients', {'scientific_name': 'Olmesartan',   'class_id': c4});
    final valsartanAml = await db.insert('active_ingredients', {'scientific_name': 'Valsartan/Amlodipine (combo)', 'class_id': c4});

    for (final b in [
      {'brand_name': 'Renitec',      'company': 'Merck',                 'ingredient_id': enalapril},
      {'brand_name': 'Ednyt',        'company': 'Hikma',                 'ingredient_id': enalapril},
      {'brand_name': 'Vasotec',      'company': 'Valeant',               'ingredient_id': enalapril},
      {'brand_name': 'Zestril',      'company': 'AstraZeneca',           'ingredient_id': lisinopril},
      {'brand_name': 'Prinivil',     'company': 'Merck',                 'ingredient_id': lisinopril},
      {'brand_name': 'Capoten',      'company': 'BMS',                   'ingredient_id': captopril},
      {'brand_name': 'Coversyl',     'company': 'Servier',               'ingredient_id': perindopril},
      {'brand_name': 'Prestarium',   'company': 'Servier',               'ingredient_id': perindopril},
      {'brand_name': 'Cozaar',       'company': 'Merck',                 'ingredient_id': losartan},
      {'brand_name': 'Lifezar',      'company': 'Hikma',                 'ingredient_id': losartan},
      {'brand_name': 'Lozapin',      'company': 'Julphar',               'ingredient_id': losartan},
      {'brand_name': 'Diovan',       'company': 'Novartis',              'ingredient_id': valsartan},
      {'brand_name': 'Tareg',        'company': 'Novartis',              'ingredient_id': valsartan},
      {'brand_name': 'Micardis',     'company': 'Boehringer Ingelheim',  'ingredient_id': telmisartan},
      {'brand_name': 'Pritor',       'company': 'Bayer',                 'ingredient_id': telmisartan},
      {'brand_name': 'Atacand',      'company': 'AstraZeneca',           'ingredient_id': candesartan},
      {'brand_name': 'Avapro',       'company': 'Sanofi',                'ingredient_id': irbesartan},
      {'brand_name': 'Aprovel',      'company': 'Sanofi',                'ingredient_id': irbesartan},
      {'brand_name': 'Olmetec',      'company': 'Daiichi Sankyo',        'ingredient_id': olmesartan},
      {'brand_name': 'Exforge',      'company': 'Novartis',              'ingredient_id': valsartanAml},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 5. ستاتينات — Statins
    // ══════════════════════════════════════════════════════════════════
    final c5 = await db.insert('drug_classes', {'class_name': 'Statins - HMG-CoA Reductase Inhibitors (الستاتينات)'});
    final atorvastatin  = await db.insert('active_ingredients', {'scientific_name': 'Atorvastatin',  'class_id': c5});
    final rosuvastatin  = await db.insert('active_ingredients', {'scientific_name': 'Rosuvastatin',  'class_id': c5});
    final simvastatin   = await db.insert('active_ingredients', {'scientific_name': 'Simvastatin',   'class_id': c5});

    for (final b in [
      {'brand_name': 'Lipitor',     'company': 'Pfizer',               'ingredient_id': atorvastatin},
      {'brand_name': 'Atorlip',     'company': 'Cipla',                'ingredient_id': atorvastatin},
      {'brand_name': 'Avastatin',   'company': 'Julphar',              'ingredient_id': atorvastatin},
      {'brand_name': 'Crestor',     'company': 'AstraZeneca',          'ingredient_id': rosuvastatin},
      {'brand_name': 'Rosuzet',     'company': 'MSD',                  'ingredient_id': rosuvastatin},
      {'brand_name': 'Zocor',       'company': 'Merck',                'ingredient_id': simvastatin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 6. مضادات الهيستامين — Antihistamines
    // ══════════════════════════════════════════════════════════════════
    final c6 = await db.insert('drug_classes', {'class_name': 'Antihistamines H1 (مضادات الهيستامين)'});
    final cetirizine    = await db.insert('active_ingredients', {'scientific_name': 'Cetirizine',    'class_id': c6});
    final loratadine    = await db.insert('active_ingredients', {'scientific_name': 'Loratadine',    'class_id': c6});
    final fexofenadine  = await db.insert('active_ingredients', {'scientific_name': 'Fexofenadine',  'class_id': c6});
    final chlorpheniramine = await db.insert('active_ingredients', {'scientific_name': 'Chlorpheniramine', 'class_id': c6});

    for (final b in [
      {'brand_name': 'Zyrtec',      'company': 'GSK',                  'ingredient_id': cetirizine},
      {'brand_name': 'Alerid',      'company': 'Cipla',                'ingredient_id': cetirizine},
      {'brand_name': 'Cetryn',      'company': 'Hikma',                'ingredient_id': cetirizine},
      {'brand_name': 'Claritine',   'company': 'Bayer',                'ingredient_id': loratadine},
      {'brand_name': 'Allergyl',    'company': 'Julphar',              'ingredient_id': loratadine},
      {'brand_name': 'Telfast',     'company': 'Sanofi',               'ingredient_id': fexofenadine},
      {'brand_name': 'Allegra',     'company': 'Sanofi',               'ingredient_id': fexofenadine},
      {'brand_name': 'Piriton',     'company': 'GSK',                  'ingredient_id': chlorpheniramine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 7. مضادات السكري — Oral Antidiabetics
    // ══════════════════════════════════════════════════════════════════
    final c7 = await db.insert('drug_classes', {'class_name': 'Oral Antidiabetics (أدوية السكري الفموية)'});
    final metformin      = await db.insert('active_ingredients', {'scientific_name': 'Metformin',       'class_id': c7});
    final gliclazide     = await db.insert('active_ingredients', {'scientific_name': 'Gliclazide',      'class_id': c7});
    final glibenclamide  = await db.insert('active_ingredients', {'scientific_name': 'Glibenclamide',   'class_id': c7});
    final glimepiride    = await db.insert('active_ingredients', {'scientific_name': 'Glimepiride',     'class_id': c7});
    final sitagliptin    = await db.insert('active_ingredients', {'scientific_name': 'Sitagliptin',     'class_id': c7});
    final vildagliptin   = await db.insert('active_ingredients', {'scientific_name': 'Vildagliptin',    'class_id': c7});
    final saxagliptin    = await db.insert('active_ingredients', {'scientific_name': 'Saxagliptin',     'class_id': c7});
    final empagliflozin  = await db.insert('active_ingredients', {'scientific_name': 'Empagliflozin',   'class_id': c7});
    final dapagliflozin  = await db.insert('active_ingredients', {'scientific_name': 'Dapagliflozin',   'class_id': c7});
    final pioglitazone   = await db.insert('active_ingredients', {'scientific_name': 'Pioglitazone',    'class_id': c7});
    final linagliptin    = await db.insert('active_ingredients', {'scientific_name': 'Linagliptin',     'class_id': c7});

    for (final b in [
      {'brand_name': 'Glucophage',    'company': 'Merck',                  'ingredient_id': metformin},
      {'brand_name': 'Cidophage',     'company': 'Hikma',                  'ingredient_id': metformin},
      {'brand_name': 'Diabamyl',      'company': 'Julphar',                'ingredient_id': metformin},
      {'brand_name': 'Glucomet',      'company': 'SDI (Samarra - Iraq)',   'ingredient_id': metformin},
      {'brand_name': 'Fortamet',      'company': 'Andrx',                  'ingredient_id': metformin},
      {'brand_name': 'Diamicron',     'company': 'Servier',                'ingredient_id': gliclazide},
      {'brand_name': 'Diamicron MR',  'company': 'Servier',                'ingredient_id': gliclazide},
      {'brand_name': 'Daonil',        'company': 'Sanofi',                 'ingredient_id': glibenclamide},
      {'brand_name': 'Gliben SDI',    'company': 'SDI (Samarra - Iraq)',   'ingredient_id': glibenclamide},
      {'brand_name': 'Amaryl',        'company': 'Sanofi',                 'ingredient_id': glimepiride},
      {'brand_name': 'Glimepil',      'company': 'Hikma',                  'ingredient_id': glimepiride},
      {'brand_name': 'Januvia',       'company': 'MSD',                    'ingredient_id': sitagliptin},
      {'brand_name': 'Galvus',        'company': 'Novartis',               'ingredient_id': vildagliptin},
      {'brand_name': 'Onglyza',       'company': 'AstraZeneca',            'ingredient_id': saxagliptin},
      {'brand_name': 'Jardiance',     'company': 'Boehringer Ingelheim',   'ingredient_id': empagliflozin},
      {'brand_name': 'Forxiga',       'company': 'AstraZeneca',            'ingredient_id': dapagliflozin},
      {'brand_name': 'Actos',         'company': 'Takeda',                 'ingredient_id': pioglitazone},
      {'brand_name': 'Trajenta',      'company': 'Boehringer Ingelheim',   'ingredient_id': linagliptin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 8. مضادات الالتهاب — NSAIDs
    // ══════════════════════════════════════════════════════════════════
    final c8 = await db.insert('drug_classes', {'class_name': 'NSAIDs (مضادات الالتهاب غير الستيرويدية)'});
    final ibuprofen    = await db.insert('active_ingredients', {'scientific_name': 'Ibuprofen',      'class_id': c8});
    final diclofenac   = await db.insert('active_ingredients', {'scientific_name': 'Diclofenac',     'class_id': c8});
    final naproxen     = await db.insert('active_ingredients', {'scientific_name': 'Naproxen',       'class_id': c8});
    final mefenamic    = await db.insert('active_ingredients', {'scientific_name': 'Mefenamic Acid', 'class_id': c8});
    final celecoxib    = await db.insert('active_ingredients', {'scientific_name': 'Celecoxib',      'class_id': c8});
    final meloxicam    = await db.insert('active_ingredients', {'scientific_name': 'Meloxicam',      'class_id': c8});
    final aceclofenac  = await db.insert('active_ingredients', {'scientific_name': 'Aceclofenac',    'class_id': c8});
    final piroxicam    = await db.insert('active_ingredients', {'scientific_name': 'Piroxicam',      'class_id': c8});
    final indomethacin = await db.insert('active_ingredients', {'scientific_name': 'Indomethacin',   'class_id': c8});
    final ketorolac    = await db.insert('active_ingredients', {'scientific_name': 'Ketorolac',      'class_id': c8});

    for (final b in [
      {'brand_name': 'Brufen',       'company': 'Abbott',                'ingredient_id': ibuprofen},
      {'brand_name': 'Advil',        'company': 'Pfizer',                'ingredient_id': ibuprofen},
      {'brand_name': 'Profinal',     'company': 'SDI (Samarra - Iraq)',  'ingredient_id': ibuprofen},
      {'brand_name': 'Nurofen',      'company': 'Reckitt Benckiser',    'ingredient_id': ibuprofen},
      {'brand_name': 'Voltaren',     'company': 'Novartis',              'ingredient_id': diclofenac},
      {'brand_name': 'Cataflam',     'company': 'Novartis',              'ingredient_id': diclofenac},
      {'brand_name': 'Diclofen SDI', 'company': 'SDI (Samarra - Iraq)', 'ingredient_id': diclofenac},
      {'brand_name': 'Naprosyn',     'company': 'Roche',                 'ingredient_id': naproxen},
      {'brand_name': 'Ponstan',      'company': 'Pfizer',                'ingredient_id': mefenamic},
      {'brand_name': 'Celebrex',     'company': 'Pfizer',                'ingredient_id': celecoxib},
      {'brand_name': 'Mobic',        'company': 'Boehringer Ingelheim',  'ingredient_id': meloxicam},
      {'brand_name': 'Melox',        'company': 'Julphar',               'ingredient_id': meloxicam},
      {'brand_name': 'Airtal',       'company': 'Almirall',              'ingredient_id': aceclofenac},
      {'brand_name': 'Bristaflam',   'company': 'BMS',                   'ingredient_id': aceclofenac},
      {'brand_name': 'Feldene',      'company': 'Pfizer',                'ingredient_id': piroxicam},
      {'brand_name': 'Indocid',      'company': 'MSD',                   'ingredient_id': indomethacin},
      {'brand_name': 'Toradol',      'company': 'Roche',                 'ingredient_id': ketorolac},
      {'brand_name': 'Ketolac',      'company': 'Julphar',               'ingredient_id': ketorolac},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 9. مضادات حيوية — Fluoroquinolones
    // ══════════════════════════════════════════════════════════════════
    final c9 = await db.insert('drug_classes', {'class_name': 'Fluoroquinolones (الفلوروكينولونات)'});
    final ciprofloxacin  = await db.insert('active_ingredients', {'scientific_name': 'Ciprofloxacin',  'class_id': c9});
    final levofloxacin   = await db.insert('active_ingredients', {'scientific_name': 'Levofloxacin',   'class_id': c9});
    final moxifloxacin   = await db.insert('active_ingredients', {'scientific_name': 'Moxifloxacin',   'class_id': c9});

    for (final b in [
      {'brand_name': 'Ciprobay',    'company': 'Bayer',                'ingredient_id': ciprofloxacin},
      {'brand_name': 'Ciprodar',    'company': 'Julphar',              'ingredient_id': ciprofloxacin},
      {'brand_name': 'Tavanic',     'company': 'Sanofi',               'ingredient_id': levofloxacin},
      {'brand_name': 'Cravit',      'company': 'Daiichi Sankyo',       'ingredient_id': levofloxacin},
      {'brand_name': 'Avelox',      'company': 'Bayer',                'ingredient_id': moxifloxacin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 10. مسكنات — Paracetamol & Opioid Analgesics
    // ══════════════════════════════════════════════════════════════════
    final c10 = await db.insert('drug_classes', {'class_name': 'Analgesics - Paracetamol & Opioids (مسكنات الألم)'});
    final paracetamol   = await db.insert('active_ingredients', {'scientific_name': 'Paracetamol (Acetaminophen)', 'class_id': c10});
    final tramadol      = await db.insert('active_ingredients', {'scientific_name': 'Tramadol',      'class_id': c10});

    for (final b in [
      {'brand_name': 'Panadol',     'company': 'GSK',                  'ingredient_id': paracetamol},
      {'brand_name': 'Adol',        'company': 'SPIMACO/Saudi',        'ingredient_id': paracetamol},
      {'brand_name': 'Fevadol',     'company': 'SPIMACO/Saudi',        'ingredient_id': paracetamol},
      {'brand_name': 'Paracetamol SDI', 'company': 'SDI (Samarra - Iraq)', 'ingredient_id': paracetamol},
      {'brand_name': 'Tramal',      'company': 'Grunenthal',           'ingredient_id': tramadol},
      {'brand_name': 'Tramadex',    'company': 'Julphar',              'ingredient_id': tramadol},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 11. مضادات حيوية بنسلينية — Penicillins
    // ══════════════════════════════════════════════════════════════════
    final c11 = await db.insert('drug_classes', {'class_name': 'Penicillins (البنسلينات)'});
    final amoxicillin = await db.insert('active_ingredients', {'scientific_name': 'Amoxicillin', 'class_id': c11});
    final coAmoxiclav = await db.insert('active_ingredients', {'scientific_name': 'Amoxicillin/Clavulanate', 'class_id': c11});

    for (final b in [
      {'brand_name': 'Amoxil',      'company': 'GSK',                  'ingredient_id': amoxicillin},
      {'brand_name': 'Hiconcil',    'company': 'Krka',                 'ingredient_id': amoxicillin},
      {'brand_name': 'Amoxicillin SDI', 'company': 'SDI (Samarra - Iraq)', 'ingredient_id': amoxicillin},
      {'brand_name': 'Augmentin',   'company': 'GSK',                  'ingredient_id': coAmoxiclav},
      {'brand_name': 'Curam',       'company': 'Sandoz',               'ingredient_id': coAmoxiclav},
      {'brand_name': 'Megamox',     'company': 'Julphar',              'ingredient_id': coAmoxiclav},
      {'brand_name': 'Clavimox',    'company': 'Hikma',                'ingredient_id': coAmoxiclav},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 12. ماكروليدات — Macrolides
    // ══════════════════════════════════════════════════════════════════
    final c12 = await db.insert('drug_classes', {'class_name': 'Macrolides (الماكروليدات)'});
    final azithromycin   = await db.insert('active_ingredients', {'scientific_name': 'Azithromycin',   'class_id': c12});
    final clarithromycin = await db.insert('active_ingredients', {'scientific_name': 'Clarithromycin', 'class_id': c12});
    final erythromycin   = await db.insert('active_ingredients', {'scientific_name': 'Erythromycin',   'class_id': c12});
    final spiramycin     = await db.insert('active_ingredients', {'scientific_name': 'Spiramycin',     'class_id': c12});

    for (final b in [
      {'brand_name': 'Zithromax',    'company': 'Pfizer',               'ingredient_id': azithromycin},
      {'brand_name': 'Azomax',       'company': 'Hikma',                'ingredient_id': azithromycin},
      {'brand_name': 'Azithrocin',   'company': 'Julphar',              'ingredient_id': azithromycin},
      {'brand_name': 'Azitro SDI',   'company': 'SDI (Samarra - Iraq)', 'ingredient_id': azithromycin},
      {'brand_name': 'Klacid',       'company': 'Abbott',               'ingredient_id': clarithromycin},
      {'brand_name': 'Clarihexal',   'company': 'Sandoz',               'ingredient_id': clarithromycin},
      {'brand_name': 'Biaxin',       'company': 'AbbVie',               'ingredient_id': clarithromycin},
      {'brand_name': 'Erythrocin',   'company': 'Abbott',               'ingredient_id': erythromycin},
      {'brand_name': 'Rovamycine',   'company': 'Sanofi',               'ingredient_id': spiramycin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 13. سيفالوسبورينات — Cephalosporins
    // ══════════════════════════════════════════════════════════════════
    final c13 = await db.insert('drug_classes', {'class_name': 'Cephalosporins (السيفالوسبورينات)'});
    final cefalexin   = await db.insert('active_ingredients', {'scientific_name': 'Cefalexin (1st gen)',   'class_id': c13});
    final cefuroxime  = await db.insert('active_ingredients', {'scientific_name': 'Cefuroxime (2nd gen)',  'class_id': c13});
    final cefixime    = await db.insert('active_ingredients', {'scientific_name': 'Cefixime (3rd gen)',    'class_id': c13});
    final ceftriaxone = await db.insert('active_ingredients', {'scientific_name': 'Ceftriaxone (3rd gen)','class_id': c13});
    final cefpodoxime = await db.insert('active_ingredients', {'scientific_name': 'Cefpodoxime (3rd gen)','class_id': c13});
    final cefdinir    = await db.insert('active_ingredients', {'scientific_name': 'Cefdinir (3rd gen)',    'class_id': c13});

    for (final b in [
      {'brand_name': 'Keflex',       'company': 'Eli Lilly',            'ingredient_id': cefalexin},
      {'brand_name': 'Ospexin',      'company': 'Sandoz',               'ingredient_id': cefalexin},
      {'brand_name': 'Zinnat',       'company': 'GSK',                  'ingredient_id': cefuroxime},
      {'brand_name': 'Suprax',       'company': 'Sanofi',               'ingredient_id': cefixime},
      {'brand_name': 'Cefimax',      'company': 'Julphar',              'ingredient_id': cefixime},
      {'brand_name': 'Fixim',        'company': 'Hikma',                'ingredient_id': cefixime},
      {'brand_name': 'Rocephin',     'company': 'Roche',                'ingredient_id': ceftriaxone},
      {'brand_name': 'Tradexon',     'company': 'Julphar',              'ingredient_id': ceftriaxone},
      {'brand_name': 'Omnicef',      'company': 'Abbott',               'ingredient_id': cefdinir},
      {'brand_name': 'Vantin',       'company': 'Pfizer',               'ingredient_id': cefpodoxime},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 14. مضادات اللاهوائيات/الطفيليات — Metronidazole & relatives
    // ══════════════════════════════════════════════════════════════════
    final c14 = await db.insert('drug_classes', {'class_name': 'Anaerobic/Antiprotozoal (مضادات اللاهوائيات والطفيليات)'});
    final metronidazole = await db.insert('active_ingredients', {'scientific_name': 'Metronidazole', 'class_id': c14});
    final tinidazole     = await db.insert('active_ingredients', {'scientific_name': 'Tinidazole',    'class_id': c14});

    for (final b in [
      {'brand_name': 'Flagyl',      'company': 'Sanofi',               'ingredient_id': metronidazole},
      {'brand_name': 'Metrozine',   'company': 'Hikma',                'ingredient_id': metronidazole},
      {'brand_name': 'Fasigyn',     'company': 'Pfizer',               'ingredient_id': tinidazole},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 15. توسيع القصبات — Bronchodilators / Asthma
    // ══════════════════════════════════════════════════════════════════
    final c15 = await db.insert('drug_classes', {'class_name': 'Bronchodilators & Asthma (موسعات القصبات وأدوية الربو)'});
    final salbutamol   = await db.insert('active_ingredients', {'scientific_name': 'Salbutamol',   'class_id': c15});
    final ipratropium  = await db.insert('active_ingredients', {'scientific_name': 'Ipratropium',  'class_id': c15});
    final montelukast  = await db.insert('active_ingredients', {'scientific_name': 'Montelukast',  'class_id': c15});
    final budesonide   = await db.insert('active_ingredients', {'scientific_name': 'Budesonide',   'class_id': c15});

    for (final b in [
      {'brand_name': 'Ventolin',    'company': 'GSK',                  'ingredient_id': salbutamol},
      {'brand_name': 'Salbulin',    'company': 'Julphar',              'ingredient_id': salbutamol},
      {'brand_name': 'Atrovent',    'company': 'Boehringer Ingelheim', 'ingredient_id': ipratropium},
      {'brand_name': 'Singulair',   'company': 'MSD',                  'ingredient_id': montelukast},
      {'brand_name': 'Monten',      'company': 'Sun Pharma',           'ingredient_id': montelukast},
      {'brand_name': 'Pulmicort',   'company': 'AstraZeneca',          'ingredient_id': budesonide},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 16. مضادات التشنج المعوي — Antispasmodics
    // ══════════════════════════════════════════════════════════════════
    final c16 = await db.insert('drug_classes', {'class_name': 'GI Antispasmodics (مضادات التشنج المعوي)'});
    final hyoscine   = await db.insert('active_ingredients', {'scientific_name': 'Hyoscine Butylbromide', 'class_id': c16});
    final mebeverine = await db.insert('active_ingredients', {'scientific_name': 'Mebeverine', 'class_id': c16});
    final simethicone = await db.insert('active_ingredients', {'scientific_name': 'Simethicone', 'class_id': c16});

    for (final b in [
      {'brand_name': 'Buscopan',    'company': 'Boehringer Ingelheim', 'ingredient_id': hyoscine},
      {'brand_name': 'Spasmo Relax','company': 'Julphar',              'ingredient_id': hyoscine},
      {'brand_name': 'Duspatalin',  'company': 'Abbott',               'ingredient_id': mebeverine},
      {'brand_name': 'Disflatyl',   'company': 'Mepha',                'ingredient_id': simethicone},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 17. علاج الإسهال والإماهة — Antidiarrheal & Rehydration
    // ══════════════════════════════════════════════════════════════════
    final c17 = await db.insert('drug_classes', {'class_name': 'Antidiarrheal & Rehydration (الإسهال والإماهة)'});
    final loperamide = await db.insert('active_ingredients', {'scientific_name': 'Loperamide', 'class_id': c17});
    final ors        = await db.insert('active_ingredients', {'scientific_name': 'Oral Rehydration Salts', 'class_id': c17});

    for (final b in [
      {'brand_name': 'Imodium',     'company': 'J&J',                  'ingredient_id': loperamide},
      {'brand_name': 'Rehydran',    'company': 'Julphar',              'ingredient_id': ors},
      {'brand_name': 'Recolyte',    'company': 'Pharmacare/UAE',       'ingredient_id': ors},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 18. فيتامينات ومعادن — Vitamins & Minerals
    // ══════════════════════════════════════════════════════════════════
    final c18 = await db.insert('drug_classes', {'class_name': 'Vitamins & Minerals (الفيتامينات والمعادن)'});
    final vitB = await db.insert('active_ingredients', {'scientific_name': 'Vitamin B Complex', 'class_id': c18});
    final vitD = await db.insert('active_ingredients', {'scientific_name': 'Vitamin D3', 'class_id': c18});
    final multivit = await db.insert('active_ingredients', {'scientific_name': 'Multivitamin', 'class_id': c18});
    final ferrousSulfate = await db.insert('active_ingredients', {'scientific_name': 'Ferrous Sulfate / Iron', 'class_id': c18});

    for (final b in [
      {'brand_name': 'Neurobion',   'company': 'Merck/P&G Health',     'ingredient_id': vitB},
      {'brand_name': 'Devarol-S',   'company': 'SPIMACO/Saudi',        'ingredient_id': vitD},
      {'brand_name': 'Centrum',     'company': 'Pfizer',               'ingredient_id': multivit},
      {'brand_name': 'Supradyn',    'company': 'Bayer',                'ingredient_id': multivit},
      {'brand_name': 'Ferose',      'company': 'Julphar',              'ingredient_id': ferrousSulfate},
      {'brand_name': 'Fefol',       'company': 'GSK',                  'ingredient_id': ferrousSulfate},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 19. مضادات الفطريات — Antifungals
    // ══════════════════════════════════════════════════════════════════
    final c19 = await db.insert('drug_classes', {'class_name': 'Antifungals (مضادات الفطريات)'});
    final fluconazole  = await db.insert('active_ingredients', {'scientific_name': 'Fluconazole',  'class_id': c19});
    final clotrimazole = await db.insert('active_ingredients', {'scientific_name': 'Clotrimazole (topical)', 'class_id': c19});

    for (final b in [
      {'brand_name': 'Diflucan',    'company': 'Pfizer',               'ingredient_id': fluconazole},
      {'brand_name': 'Flucoric',    'company': 'Julphar',              'ingredient_id': fluconazole},
      {'brand_name': 'Canesten',    'company': 'Bayer',                'ingredient_id': clotrimazole},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 20. كورتيزون موضعي — Topical Corticosteroids
    // ══════════════════════════════════════════════════════════════════
    final c20 = await db.insert('drug_classes', {'class_name': 'Topical Corticosteroids (الكورتيزون الموضعي)'});
    final betamethasone = await db.insert('active_ingredients', {'scientific_name': 'Betamethasone (topical)', 'class_id': c20});
    final hydrocortisoneTop = await db.insert('active_ingredients', {'scientific_name': 'Hydrocortisone (topical)', 'class_id': c20});

    for (final b in [
      {'brand_name': 'Betnovate',   'company': 'GSK',                  'ingredient_id': betamethasone},
      {'brand_name': 'Diprosone',   'company': 'MSD',                  'ingredient_id': betamethasone},
      {'brand_name': 'Cortizone',   'company': 'Pfizer',               'ingredient_id': hydrocortisoneTop},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 21. مهدئات ومنومات — Benzodiazepines / Anxiolytics
    // ══════════════════════════════════════════════════════════════════
    final c21 = await db.insert('drug_classes', {'class_name': 'Benzodiazepines & Anxiolytics (المهدئات والمنومات)'});
    final diazepam   = await db.insert('active_ingredients', {'scientific_name': 'Diazepam',   'class_id': c21});
    final alprazolam = await db.insert('active_ingredients', {'scientific_name': 'Alprazolam', 'class_id': c21});
    final clonazepam = await db.insert('active_ingredients', {'scientific_name': 'Clonazepam', 'class_id': c21});

    for (final b in [
      {'brand_name': 'Valium',      'company': 'Roche',                'ingredient_id': diazepam},
      {'brand_name': 'Xanax',       'company': 'Pfizer',               'ingredient_id': alprazolam},
      {'brand_name': 'Rivotril',    'company': 'Roche',                'ingredient_id': clonazepam},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 22. مضادات الاكتئاب — Antidepressants
    // ══════════════════════════════════════════════════════════════════
    final c22 = await db.insert('drug_classes', {'class_name': 'Antidepressants - SSRIs (مضادات الاكتئاب)'});
    final sertraline   = await db.insert('active_ingredients', {'scientific_name': 'Sertraline',   'class_id': c22});
    final escitalopram = await db.insert('active_ingredients', {'scientific_name': 'Escitalopram', 'class_id': c22});
    final fluoxetine   = await db.insert('active_ingredients', {'scientific_name': 'Fluoxetine',   'class_id': c22});

    for (final b in [
      {'brand_name': 'Zoloft',      'company': 'Pfizer',               'ingredient_id': sertraline},
      {'brand_name': 'Lustral',     'company': 'Pfizer',               'ingredient_id': sertraline},
      {'brand_name': 'Cipralex',    'company': 'Lundbeck/Servier',     'ingredient_id': escitalopram},
      {'brand_name': 'Prozac',      'company': 'Eli Lilly',            'ingredient_id': fluoxetine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 23. هرمون الغدة الدرقية — Thyroid Hormone
    // ══════════════════════════════════════════════════════════════════
    final c23 = await db.insert('drug_classes', {'class_name': 'Thyroid Hormone (هرمون الغدة الدرقية)'});
    final levothyroxine = await db.insert('active_ingredients', {'scientific_name': 'Levothyroxine', 'class_id': c23});

    for (final b in [
      {'brand_name': 'Euthyrox',    'company': 'Merck',                'ingredient_id': levothyroxine},
      {'brand_name': 'Eltroxin',    'company': 'Aspen',                'ingredient_id': levothyroxine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 24. مدرات البول — Diuretics
    // ══════════════════════════════════════════════════════════════════
    final c24 = await db.insert('drug_classes', {'class_name': 'Diuretics (مدرات البول)'});
    final furosemide    = await db.insert('active_ingredients', {'scientific_name': 'Furosemide',    'class_id': c24});
    final spironolactone= await db.insert('active_ingredients', {'scientific_name': 'Spironolactone','class_id': c24});

    for (final b in [
      {'brand_name': 'Lasix',       'company': 'Sanofi',               'ingredient_id': furosemide},
      {'brand_name': 'Aldactone',   'company': 'Pfizer',               'ingredient_id': spironolactone},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 25. حاصرات قنوات الكالسيوم — Calcium Channel Blockers
    // ══════════════════════════════════════════════════════════════════
    final c25 = await db.insert('drug_classes', {'class_name': 'Calcium Channel Blockers (حاصرات قنوات الكالسيوم)'});
    final amlodipine = await db.insert('active_ingredients', {'scientific_name': 'Amlodipine', 'class_id': c25});

    for (final b in [
      {'brand_name': 'Norvasc',     'company': 'Pfizer',               'ingredient_id': amlodipine},
      {'brand_name': 'Amlor',       'company': 'Pfizer',               'ingredient_id': amlodipine},
      {'brand_name': 'Amlodac',     'company': 'Zydus',                'ingredient_id': amlodipine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 26. مضادات التخثر والصفائح — Anticoagulants & Antiplatelets
    // ══════════════════════════════════════════════════════════════════
    final c26 = await db.insert('drug_classes', {'class_name': 'Anticoagulants & Antiplatelets (مضادات التخثر والصفائح)'});
    final clopidogrel = await db.insert('active_ingredients', {'scientific_name': 'Clopidogrel', 'class_id': c26});
    final aspirin     = await db.insert('active_ingredients', {'scientific_name': 'Aspirin (low-dose)', 'class_id': c26});
    final warfarin    = await db.insert('active_ingredients', {'scientific_name': 'Warfarin', 'class_id': c26});

    for (final b in [
      {'brand_name': 'Plavix',      'company': 'Sanofi',               'ingredient_id': clopidogrel},
      {'brand_name': 'Clopilet',    'company': 'Sun Pharma',           'ingredient_id': clopidogrel},
      {'brand_name': 'Aspocid',     'company': 'Julphar',              'ingredient_id': aspirin},
      {'brand_name': 'Aspirin Protect', 'company': 'Bayer',            'ingredient_id': aspirin},
      {'brand_name': 'Marevan',     'company': 'Goldshield',           'ingredient_id': warfarin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 27. مرخيات العضلات — Muscle Relaxants
    // ══════════════════════════════════════════════════════════════════
    final c27 = await db.insert('drug_classes', {'class_name': 'Muscle Relaxants (مرخيات العضلات)'});
    final tizanidine = await db.insert('active_ingredients', {'scientific_name': 'Tizanidine', 'class_id': c27});
    final baclofen   = await db.insert('active_ingredients', {'scientific_name': 'Baclofen', 'class_id': c27});

    for (final b in [
      {'brand_name': 'Sirdalud',    'company': 'Novartis',             'ingredient_id': tizanidine},
      {'brand_name': 'Lioresal',    'company': 'Novartis',             'ingredient_id': baclofen},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 28. مضادات الفيروسات الهربسية — Antivirals
    // ══════════════════════════════════════════════════════════════════
    final c28 = await db.insert('drug_classes', {'class_name': 'Antivirals - Herpes (مضادات فيروس الهربس)'});
    final acyclovir   = await db.insert('active_ingredients', {'scientific_name': 'Acyclovir',   'class_id': c28});
    final valacyclovir= await db.insert('active_ingredients', {'scientific_name': 'Valacyclovir','class_id': c28});

    for (final b in [
      {'brand_name': 'Zovirax',     'company': 'GSK',                  'ingredient_id': acyclovir},
      {'brand_name': 'Acyrax',      'company': 'Julphar',              'ingredient_id': acyclovir},
      {'brand_name': 'Valtrex',     'company': 'GSK',                  'ingredient_id': valacyclovir},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 29. الأنسولين — Insulin & Injectable Antidiabetics
    // ══════════════════════════════════════════════════════════════════
    final c29 = await db.insert('drug_classes', {'class_name': 'Insulin & Injectable Antidiabetics (الأنسولين والأدوية الحقنية للسكري)'});
    final insulinGlargine  = await db.insert('active_ingredients', {'scientific_name': 'Insulin Glargine (long-acting)',   'class_id': c29});
    final insulinDetemir   = await db.insert('active_ingredients', {'scientific_name': 'Insulin Detemir (long-acting)',    'class_id': c29});
    final insulinDegludec  = await db.insert('active_ingredients', {'scientific_name': 'Insulin Degludec (ultra-long)',    'class_id': c29});
    final insulinAspart    = await db.insert('active_ingredients', {'scientific_name': 'Insulin Aspart (rapid-acting)',    'class_id': c29});
    final insulinLispro    = await db.insert('active_ingredients', {'scientific_name': 'Insulin Lispro (rapid-acting)',    'class_id': c29});
    final insulinGlulisine = await db.insert('active_ingredients', {'scientific_name': 'Insulin Glulisine (rapid-acting)', 'class_id': c29});
    final insulinRegular   = await db.insert('active_ingredients', {'scientific_name': 'Regular Insulin (short-acting)',   'class_id': c29});
    final insulinNPH       = await db.insert('active_ingredients', {'scientific_name': 'NPH Insulin (intermediate)',       'class_id': c29});
    final insulinMix       = await db.insert('active_ingredients', {'scientific_name': 'Premixed Insulin 70/30',           'class_id': c29});
    final semaglutide      = await db.insert('active_ingredients', {'scientific_name': 'Semaglutide (GLP-1 agonist)',      'class_id': c29});
    final liraglutide      = await db.insert('active_ingredients', {'scientific_name': 'Liraglutide (GLP-1 agonist)',      'class_id': c29});

    for (final b in [
      {'brand_name': 'Lantus',       'company': 'Sanofi',               'ingredient_id': insulinGlargine},
      {'brand_name': 'Toujeo',       'company': 'Sanofi',               'ingredient_id': insulinGlargine},
      {'brand_name': 'Basaglar',     'company': 'Eli Lilly',            'ingredient_id': insulinGlargine},
      {'brand_name': 'Levemir',      'company': 'Novo Nordisk',         'ingredient_id': insulinDetemir},
      {'brand_name': 'Tresiba',      'company': 'Novo Nordisk',         'ingredient_id': insulinDegludec},
      {'brand_name': 'NovoRapid',    'company': 'Novo Nordisk',         'ingredient_id': insulinAspart},
      {'brand_name': 'Novolog',      'company': 'Novo Nordisk',         'ingredient_id': insulinAspart},
      {'brand_name': 'Humalog',      'company': 'Eli Lilly',            'ingredient_id': insulinLispro},
      {'brand_name': 'Apidra',       'company': 'Sanofi',               'ingredient_id': insulinGlulisine},
      {'brand_name': 'Actrapid',     'company': 'Novo Nordisk',         'ingredient_id': insulinRegular},
      {'brand_name': 'Humulin R',    'company': 'Eli Lilly',            'ingredient_id': insulinRegular},
      {'brand_name': 'Insulatard',   'company': 'Novo Nordisk',         'ingredient_id': insulinNPH},
      {'brand_name': 'Humulin N',    'company': 'Eli Lilly',            'ingredient_id': insulinNPH},
      {'brand_name': 'Mixtard 30',   'company': 'Novo Nordisk',         'ingredient_id': insulinMix},
      {'brand_name': 'Humulin M3',   'company': 'Eli Lilly',            'ingredient_id': insulinMix},
      {'brand_name': 'NovoMix 30',   'company': 'Novo Nordisk',         'ingredient_id': insulinMix},
      {'brand_name': 'Ozempic',      'company': 'Novo Nordisk',         'ingredient_id': semaglutide},
      {'brand_name': 'Rybelsus',     'company': 'Novo Nordisk',         'ingredient_id': semaglutide},
      {'brand_name': 'Victoza',      'company': 'Novo Nordisk',         'ingredient_id': liraglutide},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 30. تتراسيكلينات — Tetracyclines & Doxycycline
    // ══════════════════════════════════════════════════════════════════
    final c30 = await db.insert('drug_classes', {'class_name': 'Tetracyclines (التتراسيكلينات)'});
    final doxycycline  = await db.insert('active_ingredients', {'scientific_name': 'Doxycycline',  'class_id': c30});
    final tetracycline = await db.insert('active_ingredients', {'scientific_name': 'Tetracycline', 'class_id': c30});
    final minocycline  = await db.insert('active_ingredients', {'scientific_name': 'Minocycline',  'class_id': c30});

    for (final b in [
      {'brand_name': 'Vibramycin',   'company': 'Pfizer',               'ingredient_id': doxycycline},
      {'brand_name': 'Doxylin',      'company': 'Hikma',                'ingredient_id': doxycycline},
      {'brand_name': 'Doxy SDI',     'company': 'SDI (Samarra - Iraq)', 'ingredient_id': doxycycline},
      {'brand_name': 'Achromycin',   'company': 'Pfizer',               'ingredient_id': tetracycline},
      {'brand_name': 'Minocin',      'company': 'Wyeth',                'ingredient_id': minocycline},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 31. كورتيزون جهازي — Systemic Corticosteroids
    // ══════════════════════════════════════════════════════════════════
    final c31 = await db.insert('drug_classes', {'class_name': 'Systemic Corticosteroids (الكورتيزون الجهازي)'});
    final prednisolone      = await db.insert('active_ingredients', {'scientific_name': 'Prednisolone',                  'class_id': c31});
    final dexamethasone     = await db.insert('active_ingredients', {'scientific_name': 'Dexamethasone',                 'class_id': c31});
    final methylprednisolone= await db.insert('active_ingredients', {'scientific_name': 'Methylprednisolone',            'class_id': c31});
    final hydrocortisone    = await db.insert('active_ingredients', {'scientific_name': 'Hydrocortisone (systemic)',     'class_id': c31});

    for (final b in [
      {'brand_name': 'Predsol',       'company': 'GSK',                  'ingredient_id': prednisolone},
      {'brand_name': 'Deltacortril',  'company': 'Pfizer',               'ingredient_id': prednisolone},
      {'brand_name': 'Prednisolone SDI','company': 'SDI (Samarra - Iraq)','ingredient_id': prednisolone},
      {'brand_name': 'Decadron',      'company': 'MSD',                  'ingredient_id': dexamethasone},
      {'brand_name': 'Dexamethasone SDI','company': 'SDI (Samarra - Iraq)','ingredient_id': dexamethasone},
      {'brand_name': 'Fortecortin',   'company': 'Merck',                'ingredient_id': dexamethasone},
      {'brand_name': 'Medrol',        'company': 'Pfizer/Upjohn',        'ingredient_id': methylprednisolone},
      {'brand_name': 'Solu-Medrol',   'company': 'Pfizer/Upjohn',        'ingredient_id': methylprednisolone},
      {'brand_name': 'Solu-Cortef',   'company': 'Pfizer/Upjohn',        'ingredient_id': hydrocortisone},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 32. حاصرات H2 ومضادات الحموضة — H2 Blockers & Antacids
    // ══════════════════════════════════════════════════════════════════
    final c32 = await db.insert('drug_classes', {'class_name': 'H2 Blockers & Antacids (حاصرات H2 ومضادات الحموضة)'});
    final ranitidine   = await db.insert('active_ingredients', {'scientific_name': 'Ranitidine',              'class_id': c32});
    final famotidine   = await db.insert('active_ingredients', {'scientific_name': 'Famotidine',              'class_id': c32});
    final aluminumMg   = await db.insert('active_ingredients', {'scientific_name': 'Aluminum/Magnesium antacid','class_id': c32});
    final sucralfate   = await db.insert('active_ingredients', {'scientific_name': 'Sucralfate',              'class_id': c32});

    for (final b in [
      {'brand_name': 'Zantac',       'company': 'Sanofi',               'ingredient_id': ranitidine},
      {'brand_name': 'Raniver',      'company': 'Hikma',                'ingredient_id': ranitidine},
      {'brand_name': 'Pepcid',       'company': 'J&J',                  'ingredient_id': famotidine},
      {'brand_name': 'Maalox',       'company': 'Sanofi',               'ingredient_id': aluminumMg},
      {'brand_name': 'Gaviscon',     'company': 'Reckitt',              'ingredient_id': aluminumMg},
      {'brand_name': 'Antepsin',     'company': 'Pfizer',               'ingredient_id': sucralfate},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 33. ملينات — Laxatives
    // ══════════════════════════════════════════════════════════════════
    final c33 = await db.insert('drug_classes', {'class_name': 'Laxatives (الملينات)'});
    final bisacodyl    = await db.insert('active_ingredients', {'scientific_name': 'Bisacodyl',   'class_id': c33});
    final lactulose    = await db.insert('active_ingredients', {'scientific_name': 'Lactulose',   'class_id': c33});
    final senna        = await db.insert('active_ingredients', {'scientific_name': 'Senna',       'class_id': c33});
    final macrogol     = await db.insert('active_ingredients', {'scientific_name': 'Macrogol (PEG)','class_id': c33});

    for (final b in [
      {'brand_name': 'Dulcolax',     'company': 'Boehringer Ingelheim', 'ingredient_id': bisacodyl},
      {'brand_name': 'Duphalac',     'company': 'Abbott',               'ingredient_id': lactulose},
      {'brand_name': 'Lactulose SDI','company': 'SDI (Samarra - Iraq)', 'ingredient_id': lactulose},
      {'brand_name': 'Senokot',      'company': 'Reckitt',              'ingredient_id': senna},
      {'brand_name': 'Forlax',       'company': 'Beaufour Ipsen',       'ingredient_id': macrogol},
      {'brand_name': 'Movicol',      'company': 'Norgine',              'ingredient_id': macrogol},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 34. مضادات الطفيليات المعوية — Antiparasitics
    // ══════════════════════════════════════════════════════════════════
    final c34 = await db.insert('drug_classes', {'class_name': 'Antiparasitics - Intestinal (مضادات الطفيليات المعوية)'});
    final albendazole  = await db.insert('active_ingredients', {'scientific_name': 'Albendazole',  'class_id': c34});
    final mebendazole  = await db.insert('active_ingredients', {'scientific_name': 'Mebendazole',  'class_id': c34});
    final ivermectin   = await db.insert('active_ingredients', {'scientific_name': 'Ivermectin',   'class_id': c34});
    final praziquantel = await db.insert('active_ingredients', {'scientific_name': 'Praziquantel', 'class_id': c34});

    for (final b in [
      {'brand_name': 'Zentel',       'company': 'GSK',                  'ingredient_id': albendazole},
      {'brand_name': 'Eskazole',     'company': 'GSK',                  'ingredient_id': albendazole},
      {'brand_name': 'Vermox',       'company': 'J&J',                  'ingredient_id': mebendazole},
      {'brand_name': 'Stromectol',   'company': 'MSD',                  'ingredient_id': ivermectin},
      {'brand_name': 'Biltricide',   'company': 'Bayer',                'ingredient_id': praziquantel},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 35. منقيات الشعب الهوائية — Mucolytics & Cough
    // ══════════════════════════════════════════════════════════════════
    final c35 = await db.insert('drug_classes', {'class_name': 'Mucolytics & Cough (منقيات البلغم وأدوية السعال)'});
    final nac          = await db.insert('active_ingredients', {'scientific_name': 'N-Acetylcysteine (NAC)',        'class_id': c35});
    final ambroxol     = await db.insert('active_ingredients', {'scientific_name': 'Ambroxol',                     'class_id': c35});
    final bromhexine   = await db.insert('active_ingredients', {'scientific_name': 'Bromhexine',                   'class_id': c35});
    final carbocysteine= await db.insert('active_ingredients', {'scientific_name': 'Carbocisteine',                'class_id': c35});
    final dextromethorphan = await db.insert('active_ingredients', {'scientific_name': 'Dextromethorphan (DXM)',   'class_id': c35});

    for (final b in [
      {'brand_name': 'Fluimucil',    'company': 'Zambon',               'ingredient_id': nac},
      {'brand_name': 'Mucosolvan',   'company': 'Boehringer Ingelheim', 'ingredient_id': ambroxol},
      {'brand_name': 'Ambrox SDI',   'company': 'SDI (Samarra - Iraq)', 'ingredient_id': ambroxol},
      {'brand_name': 'Bisolvon',     'company': 'Boehringer Ingelheim', 'ingredient_id': bromhexine},
      {'brand_name': 'Mucodyne',     'company': 'Sanofi',               'ingredient_id': carbocysteine},
      {'brand_name': 'Robitussin DM','company': 'Pfizer',               'ingredient_id': dextromethorphan},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 36. مضادات الذهان — Antipsychotics
    // ══════════════════════════════════════════════════════════════════
    final c36 = await db.insert('drug_classes', {'class_name': 'Antipsychotics (مضادات الذهان)'});
    final risperidone  = await db.insert('active_ingredients', {'scientific_name': 'Risperidone',  'class_id': c36});
    final olanzapine   = await db.insert('active_ingredients', {'scientific_name': 'Olanzapine',   'class_id': c36});
    final quetiapine   = await db.insert('active_ingredients', {'scientific_name': 'Quetiapine',   'class_id': c36});
    final haloperidol  = await db.insert('active_ingredients', {'scientific_name': 'Haloperidol',  'class_id': c36});
    final aripiprazole = await db.insert('active_ingredients', {'scientific_name': 'Aripiprazole', 'class_id': c36});
    final clozapine    = await db.insert('active_ingredients', {'scientific_name': 'Clozapine',    'class_id': c36});

    for (final b in [
      {'brand_name': 'Risperdal',    'company': 'Janssen',              'ingredient_id': risperidone},
      {'brand_name': 'Risperon',     'company': 'Hikma',                'ingredient_id': risperidone},
      {'brand_name': 'Zyprexa',      'company': 'Eli Lilly',            'ingredient_id': olanzapine},
      {'brand_name': 'Zalasta',      'company': 'Krka',                 'ingredient_id': olanzapine},
      {'brand_name': 'Seroquel',     'company': 'AstraZeneca',          'ingredient_id': quetiapine},
      {'brand_name': 'Haldol',       'company': 'Janssen',              'ingredient_id': haloperidol},
      {'brand_name': 'Abilify',      'company': 'BMS / Otsuka',        'ingredient_id': aripiprazole},
      {'brand_name': 'Leponex',      'company': 'Novartis',             'ingredient_id': clozapine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 37. مضادات الصرع — Anti-epileptics
    // ══════════════════════════════════════════════════════════════════
    final c37 = await db.insert('drug_classes', {'class_name': 'Anti-epileptics (مضادات الصرع)'});
    final carbamazepine  = await db.insert('active_ingredients', {'scientific_name': 'Carbamazepine',   'class_id': c37});
    final valproate      = await db.insert('active_ingredients', {'scientific_name': 'Valproic Acid',   'class_id': c37});
    final phenobarbital  = await db.insert('active_ingredients', {'scientific_name': 'Phenobarbital',   'class_id': c37});
    final phenytoin      = await db.insert('active_ingredients', {'scientific_name': 'Phenytoin',       'class_id': c37});
    final lamotrigine    = await db.insert('active_ingredients', {'scientific_name': 'Lamotrigine',     'class_id': c37});
    final levetiracetam  = await db.insert('active_ingredients', {'scientific_name': 'Levetiracetam',   'class_id': c37});
    final gabapentin     = await db.insert('active_ingredients', {'scientific_name': 'Gabapentin',      'class_id': c37});
    final pregabalin     = await db.insert('active_ingredients', {'scientific_name': 'Pregabalin',      'class_id': c37});

    for (final b in [
      {'brand_name': 'Tegretol',     'company': 'Novartis',             'ingredient_id': carbamazepine},
      {'brand_name': 'Depakine',     'company': 'Sanofi',               'ingredient_id': valproate},
      {'brand_name': 'Epilim',       'company': 'Sanofi',               'ingredient_id': valproate},
      {'brand_name': 'Phenobarb SDI','company': 'SDI (Samarra - Iraq)', 'ingredient_id': phenobarbital},
      {'brand_name': 'Epanutin',     'company': 'Pfizer',               'ingredient_id': phenytoin},
      {'brand_name': 'Lamictal',     'company': 'GSK',                  'ingredient_id': lamotrigine},
      {'brand_name': 'Keppra',       'company': 'UCB',                  'ingredient_id': levetiracetam},
      {'brand_name': 'Neurontin',    'company': 'Pfizer',               'ingredient_id': gabapentin},
      {'brand_name': 'Lyrica',       'company': 'Pfizer',               'ingredient_id': pregabalin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 38. النقرس وحمض البوليك — Gout & Uric Acid
    // ══════════════════════════════════════════════════════════════════
    final c38 = await db.insert('drug_classes', {'class_name': 'Gout & Uric Acid (النقرس وحمض البوليك)'});
    final allopurinol  = await db.insert('active_ingredients', {'scientific_name': 'Allopurinol',  'class_id': c38});
    final colchicine   = await db.insert('active_ingredients', {'scientific_name': 'Colchicine',   'class_id': c38});
    final febuxostat   = await db.insert('active_ingredients', {'scientific_name': 'Febuxostat',   'class_id': c38});
    final probenecid   = await db.insert('active_ingredients', {'scientific_name': 'Probenecid',   'class_id': c38});

    for (final b in [
      {'brand_name': 'Zyloric',      'company': 'GSK',                  'ingredient_id': allopurinol},
      {'brand_name': 'Allopurinol SDI','company': 'SDI (Samarra - Iraq)','ingredient_id': allopurinol},
      {'brand_name': 'Colchicine SDI','company': 'SDI (Samarra - Iraq)', 'ingredient_id': colchicine},
      {'brand_name': 'Adenuric',     'company': 'Menarini',             'ingredient_id': febuxostat},
      {'brand_name': 'Benemid',      'company': 'MSD',                  'ingredient_id': probenecid},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 39. الفيبرات وأوميغا-3 — Fibrates & Omega-3
    // ══════════════════════════════════════════════════════════════════
    final c39 = await db.insert('drug_classes', {'class_name': 'Fibrates & Omega-3 (الفيبرات وأوميغا-3)'});
    final fenofibrate  = await db.insert('active_ingredients', {'scientific_name': 'Fenofibrate',  'class_id': c39});
    final gemfibrozil  = await db.insert('active_ingredients', {'scientific_name': 'Gemfibrozil',  'class_id': c39});
    final omega3       = await db.insert('active_ingredients', {'scientific_name': 'Omega-3 Fatty Acids','class_id': c39});
    final ezetimibe    = await db.insert('active_ingredients', {'scientific_name': 'Ezetimibe',    'class_id': c39});

    for (final b in [
      {'brand_name': 'Lipanthyl',    'company': 'Solvay / Abbott',      'ingredient_id': fenofibrate},
      {'brand_name': 'Tricor',       'company': 'Abbott',               'ingredient_id': fenofibrate},
      {'brand_name': 'Lopid',        'company': 'Pfizer',               'ingredient_id': gemfibrozil},
      {'brand_name': 'Omacor',       'company': 'Pronova / Abbott',     'ingredient_id': omega3},
      {'brand_name': 'Ezetrol',      'company': 'MSD / Schering-Plough','ingredient_id': ezetimibe},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 40. مضادات التخثر الحديثة — DOACs & LMWH
    // ══════════════════════════════════════════════════════════════════
    final c40 = await db.insert('drug_classes', {'class_name': 'DOACs & Anticoagulants - Modern (مضادات التخثر الحديثة)'});
    final rivaroxaban  = await db.insert('active_ingredients', {'scientific_name': 'Rivaroxaban', 'class_id': c40});
    final apixaban     = await db.insert('active_ingredients', {'scientific_name': 'Apixaban',    'class_id': c40});
    final dabigatran   = await db.insert('active_ingredients', {'scientific_name': 'Dabigatran',  'class_id': c40});
    final enoxaparin   = await db.insert('active_ingredients', {'scientific_name': 'Enoxaparin (LMWH)','class_id': c40});
    final heparin      = await db.insert('active_ingredients', {'scientific_name': 'Unfractionated Heparin','class_id': c40});

    for (final b in [
      {'brand_name': 'Xarelto',      'company': 'Bayer / Janssen',      'ingredient_id': rivaroxaban},
      {'brand_name': 'Eliquis',      'company': 'BMS / Pfizer',         'ingredient_id': apixaban},
      {'brand_name': 'Pradaxa',      'company': 'Boehringer Ingelheim', 'ingredient_id': dabigatran},
      {'brand_name': 'Clexane',      'company': 'Sanofi',               'ingredient_id': enoxaparin},
      {'brand_name': 'Lovenox',      'company': 'Sanofi',               'ingredient_id': enoxaparin},
      {'brand_name': 'Heparin SDI',  'company': 'SDI (Samarra - Iraq)', 'ingredient_id': heparin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 41. بصريات — Eye Drops
    // ══════════════════════════════════════════════════════════════════
    final c41 = await db.insert('drug_classes', {'class_name': 'Eye Drops (قطرات العيون)'});
    final tobramycin    = await db.insert('active_ingredients', {'scientific_name': 'Tobramycin (antibiotic drops)',         'class_id': c41});
    final ciproEye      = await db.insert('active_ingredients', {'scientific_name': 'Ciprofloxacin (eye drops)',             'class_id': c41});
    final timolol       = await db.insert('active_ingredients', {'scientific_name': 'Timolol (glaucoma)',                    'class_id': c41});
    final latanoprost   = await db.insert('active_ingredients', {'scientific_name': 'Latanoprost (glaucoma)',                'class_id': c41});
    final dexEye        = await db.insert('active_ingredients', {'scientific_name': 'Dexamethasone (eye drops)',             'class_id': c41});
    final lubricantEye  = await db.insert('active_ingredients', {'scientific_name': 'Lubricant Eye Drops (artificial tears)','class_id': c41});
    final chlorEye      = await db.insert('active_ingredients', {'scientific_name': 'Chloramphenicol (eye drops)',           'class_id': c41});

    for (final b in [
      {'brand_name': 'Tobrex',       'company': 'Alcon',                'ingredient_id': tobramycin},
      {'brand_name': 'Ciloxan',      'company': 'Alcon',                'ingredient_id': ciproEye},
      {'brand_name': 'Timoptic',     'company': 'MSD',                  'ingredient_id': timolol},
      {'brand_name': 'Xalatan',      'company': 'Pfizer',               'ingredient_id': latanoprost},
      {'brand_name': 'Maxidex',      'company': 'Alcon',                'ingredient_id': dexEye},
      {'brand_name': 'Systane',      'company': 'Alcon',                'ingredient_id': lubricantEye},
      {'brand_name': 'Refresh Plus', 'company': 'Allergan',             'ingredient_id': lubricantEye},
      {'brand_name': 'Chloromycetin Eye','company': 'Pfizer',           'ingredient_id': chlorEye},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 42. تحضيرات الأنف — Nasal Preparations
    // ══════════════════════════════════════════════════════════════════
    final c42 = await db.insert('drug_classes', {'class_name': 'Nasal Preparations (تحضيرات الأنف)'});
    final fluticasoneNasal = await db.insert('active_ingredients', {'scientific_name': 'Fluticasone (nasal spray)',          'class_id': c42});
    final mometasoneNasal  = await db.insert('active_ingredients', {'scientific_name': 'Mometasone (nasal spray)',           'class_id': c42});
    final budesonideNasal  = await db.insert('active_ingredients', {'scientific_name': 'Budesonide (nasal spray)',           'class_id': c42});
    final xylometazoline   = await db.insert('active_ingredients', {'scientific_name': 'Xylometazoline (decongestant)',      'class_id': c42});
    final oxymetazoline    = await db.insert('active_ingredients', {'scientific_name': 'Oxymetazoline (decongestant)',       'class_id': c42});

    for (final b in [
      {'brand_name': 'Flixonase',    'company': 'GSK',                  'ingredient_id': fluticasoneNasal},
      {'brand_name': 'Avamys',       'company': 'GSK',                  'ingredient_id': fluticasoneNasal},
      {'brand_name': 'Nasonex',      'company': 'MSD',                  'ingredient_id': mometasoneNasal},
      {'brand_name': 'Rhinocort',    'company': 'AstraZeneca',          'ingredient_id': budesonideNasal},
      {'brand_name': 'Otrivin',      'company': 'Novartis',             'ingredient_id': xylometazoline},
      {'brand_name': 'Xylo SDI',     'company': 'SDI (Samarra - Iraq)', 'ingredient_id': xylometazoline},
      {'brand_name': 'Afrin',        'company': 'Bayer',                'ingredient_id': oxymetazoline},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 43. المسالك البولية والبروستات — Urology
    // ══════════════════════════════════════════════════════════════════
    final c43 = await db.insert('drug_classes', {'class_name': 'Urology - Prostate & ED (المسالك البولية والبروستات)'});
    final tamsulosin   = await db.insert('active_ingredients', {'scientific_name': 'Tamsulosin',  'class_id': c43});
    final finasteride  = await db.insert('active_ingredients', {'scientific_name': 'Finasteride', 'class_id': c43});
    final sildenafil   = await db.insert('active_ingredients', {'scientific_name': 'Sildenafil',  'class_id': c43});
    final tadalafil    = await db.insert('active_ingredients', {'scientific_name': 'Tadalafil',   'class_id': c43});
    final dutasteride  = await db.insert('active_ingredients', {'scientific_name': 'Dutasteride', 'class_id': c43});

    for (final b in [
      {'brand_name': 'Flomax',       'company': 'Boehringer Ingelheim', 'ingredient_id': tamsulosin},
      {'brand_name': 'Omnic',        'company': 'Astellas',             'ingredient_id': tamsulosin},
      {'brand_name': 'Proscar',      'company': 'MSD',                  'ingredient_id': finasteride},
      {'brand_name': 'Propecia',     'company': 'MSD',                  'ingredient_id': finasteride},
      {'brand_name': 'Viagra',       'company': 'Pfizer',               'ingredient_id': sildenafil},
      {'brand_name': 'Revatio',      'company': 'Pfizer',               'ingredient_id': sildenafil},
      {'brand_name': 'Cialis',       'company': 'Eli Lilly',            'ingredient_id': tadalafil},
      {'brand_name': 'Avodart',      'company': 'GSK',                  'ingredient_id': dutasteride},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 44. مضادات الفطريات الموضعية — Topical Antifungals
    // ══════════════════════════════════════════════════════════════════
    final c44 = await db.insert('drug_classes', {'class_name': 'Topical Antifungals (مضادات الفطريات الموضعية)'});
    final ketoconazole = await db.insert('active_ingredients', {'scientific_name': 'Ketoconazole (topical)',  'class_id': c44});
    final miconazole   = await db.insert('active_ingredients', {'scientific_name': 'Miconazole (topical)',    'class_id': c44});
    final terbinafine  = await db.insert('active_ingredients', {'scientific_name': 'Terbinafine (topical)',   'class_id': c44});
    final nystatin     = await db.insert('active_ingredients', {'scientific_name': 'Nystatin',                'class_id': c44});

    for (final b in [
      {'brand_name': 'Nizoral',      'company': 'J&J',                  'ingredient_id': ketoconazole},
      {'brand_name': 'Daktarin',     'company': 'J&J',                  'ingredient_id': miconazole},
      {'brand_name': 'Lamisil',      'company': 'Novartis',             'ingredient_id': terbinafine},
      {'brand_name': 'Terbix',       'company': 'Julphar',              'ingredient_id': terbinafine},
      {'brand_name': 'Mycostatin',   'company': 'BMS',                  'ingredient_id': nystatin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 45. الكالسيوم وصحة العظام — Calcium & Bone Health
    // ══════════════════════════════════════════════════════════════════
    final c45 = await db.insert('drug_classes', {'class_name': 'Calcium & Bone Health (الكالسيوم وصحة العظام)'});
    final calciumVitD  = await db.insert('active_ingredients', {'scientific_name': 'Calcium + Vitamin D3',     'class_id': c45});
    final calciumCarb  = await db.insert('active_ingredients', {'scientific_name': 'Calcium Carbonate (alone)','class_id': c45});
    final alendronate  = await db.insert('active_ingredients', {'scientific_name': 'Alendronate (bisphosphonate)','class_id': c45});
    final vitD3        = await db.insert('active_ingredients', {'scientific_name': 'Vitamin D3 (Cholecalciferol)','class_id': c45});

    for (final b in [
      {'brand_name': 'Caltrate',     'company': 'Pfizer',               'ingredient_id': calciumVitD},
      {'brand_name': 'Calcichew D3', 'company': 'Takeda',               'ingredient_id': calciumVitD},
      {'brand_name': 'Calcium SDI',  'company': 'SDI (Samarra - Iraq)', 'ingredient_id': calciumCarb},
      {'brand_name': 'Fosamax',      'company': 'MSD',                  'ingredient_id': alendronate},
      {'brand_name': 'Devarol',      'company': 'SPIMACO/Saudi',        'ingredient_id': vitD3},
      {'brand_name': 'Devarol-S',    'company': 'SPIMACO/Saudi',        'ingredient_id': vitD3},
      {'brand_name': 'Vigantol',     'company': 'Merck',                'ingredient_id': vitD3},
    ]) { await db.insert('commercial_brands', b); }
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Future<SubstitutionResult?> searchAlternatives(String query) async {
    final db = await database;
    final q  = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    // 1. ابحث في الأسماء التجارية أولاً
    final brandRows = await db.rawQuery('''
      SELECT cb.*, ai.scientific_name, ai.class_id
      FROM   commercial_brands cb
      JOIN   active_ingredients ai ON ai.id = cb.ingredient_id
      WHERE  LOWER(cb.brand_name) LIKE ?
      LIMIT  1
    ''', ['%$q%']);

    int? ingredientId;
    int? classId;
    String searchedBrand    = query;
    String activeIngredient = '';

    if (brandRows.isNotEmpty) {
      ingredientId    = brandRows.first['ingredient_id'] as int;
      classId         = brandRows.first['class_id'] as int;
      searchedBrand   = brandRows.first['brand_name'] as String;
      activeIngredient= brandRows.first['scientific_name'] as String;
    } else {
      // 2. ابحث في المواد الفعالة
      final ingRows = await db.rawQuery('''
        SELECT * FROM active_ingredients
        WHERE LOWER(scientific_name) LIKE ?
        LIMIT 1
      ''', ['%$q%']);

      if (ingRows.isEmpty) return null;

      ingredientId    = ingRows.first['id'] as int;
      classId         = ingRows.first['class_id'] as int;
      activeIngredient= ingRows.first['scientific_name'] as String;
      searchedBrand   = activeIngredient;
    }

    // 3. اسم العائلة الدوائية
    final classRows = await db.query('drug_classes',
        where: 'id = ?', whereArgs: [classId]);
    final drugClass = classRows.isEmpty
        ? ''
        : classRows.first['class_name'] as String;

    // 4. البدائل المباشرة — نفس المادة الفعالة
    final directRows = await db.rawQuery('''
      SELECT * FROM commercial_brands
      WHERE ingredient_id = ?
      ORDER BY brand_name
    ''', [ingredientId]);

    final directAlts = directRows
        .map((r) => CommercialBrand(
              id:           r['id'] as int,
              brandName:    r['brand_name'] as String,
              company:      r['company'] as String,
              ingredientId: r['ingredient_id'] as int,
            ))
        .toList();

    // 5. بدائل من نفس العائلة — مادة فعالة مختلفة
    final otherIngRows = await db.rawQuery('''
      SELECT * FROM active_ingredients
      WHERE class_id = ? AND id != ?
      ORDER BY scientific_name
    ''', [classId, ingredientId]);

    final therapeuticGroups = <_TherapeuticGroup>[];
    for (final ing in otherIngRows) {
      final ingId   = ing['id'] as int;
      final ingName = ing['scientific_name'] as String;

      final brandRows2 = await db.rawQuery('''
        SELECT * FROM commercial_brands
        WHERE ingredient_id = ?
        ORDER BY brand_name
      ''', [ingId]);

      if (brandRows2.isNotEmpty) {
        therapeuticGroups.add(_TherapeuticGroup(
          ingredientName: ingName,
          brands: brandRows2
              .map((r) => CommercialBrand(
                    id:           r['id'] as int,
                    brandName:    r['brand_name'] as String,
                    company:      r['company'] as String,
                    ingredientId: ingId,
                  ))
              .toList(),
        ));
      }
    }

    return SubstitutionResult(
      searchedBrand:       searchedBrand,
      activeIngredient:    activeIngredient,
      drugClass:           drugClass,
      directAlternatives:  directAlts,
      therapeuticGroups:   therapeuticGroups,
    );
  }
}
