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
      version: 1,
      onCreate: _onCreate,
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
    // 1. مضادات التقيؤ — 5-HT3 Antagonists
    // ══════════════════════════════════════════════════════════════════
    final c1 = await db.insert('drug_classes', {'class_name': '5-HT3 Antagonists (مضادات التقيؤ)'});
    final ondansetron = await db.insert('active_ingredients', {'scientific_name': 'Ondansetron', 'class_id': c1});
    final granisetron = await db.insert('active_ingredients', {'scientific_name': 'Granisetron', 'class_id': c1});
    final metoclopramide = await db.insert('active_ingredients', {'scientific_name': 'Metoclopramide', 'class_id': c1});

    for (final b in [
      {'brand_name': 'Zofran',      'company': 'GSK',          'ingredient_id': ondansetron},
      {'brand_name': 'Ondamet',     'company': 'Local',        'ingredient_id': ondansetron},
      {'brand_name': 'Emeset',      'company': 'Cipla',        'ingredient_id': ondansetron},
      {'brand_name': 'Vonau',       'company': 'Ranbaxy',      'ingredient_id': ondansetron},
      {'brand_name': 'Kytril',      'company': 'Roche',        'ingredient_id': granisetron},
      {'brand_name': 'Sancuso',     'company': 'ProStrakan',   'ingredient_id': granisetron},
      {'brand_name': 'Primperan',   'company': 'Sanofi',       'ingredient_id': metoclopramide},
      {'brand_name': 'Plasil',      'company': 'Pfizer',       'ingredient_id': metoclopramide},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 2. مثبطات مضخة البروتون — PPIs
    // ══════════════════════════════════════════════════════════════════
    final c2 = await db.insert('drug_classes', {'class_name': 'Proton Pump Inhibitors - PPIs (مثبطات مضخة البروتون)'});
    final omeprazole   = await db.insert('active_ingredients', {'scientific_name': 'Omeprazole',   'class_id': c2});
    final pantoprazole = await db.insert('active_ingredients', {'scientific_name': 'Pantoprazole', 'class_id': c2});
    final esomeprazole = await db.insert('active_ingredients', {'scientific_name': 'Esomeprazole', 'class_id': c2});
    final lansoprazole = await db.insert('active_ingredients', {'scientific_name': 'Lansoprazole', 'class_id': c2});

    for (final b in [
      {'brand_name': 'Losec',       'company': 'AstraZeneca',  'ingredient_id': omeprazole},
      {'brand_name': 'Prilosec',    'company': 'P&G',          'ingredient_id': omeprazole},
      {'brand_name': 'Omez',        'company': 'Dr. Reddy\'s', 'ingredient_id': omeprazole},
      {'brand_name': 'Protonix',    'company': 'Pfizer',       'ingredient_id': pantoprazole},
      {'brand_name': 'Pantopan',    'company': 'Local',        'ingredient_id': pantoprazole},
      {'brand_name': 'Nexium',      'company': 'AstraZeneca',  'ingredient_id': esomeprazole},
      {'brand_name': 'Esotrex',     'company': 'Local',        'ingredient_id': esomeprazole},
      {'brand_name': 'Prevacid',    'company': 'Takeda',       'ingredient_id': lansoprazole},
      {'brand_name': 'Lansec',      'company': 'Local',        'ingredient_id': lansoprazole},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 3. حاصرات بيتا — Beta Blockers
    // ══════════════════════════════════════════════════════════════════
    final c3 = await db.insert('drug_classes', {'class_name': 'Beta Blockers (حاصرات بيتا)'});
    final atenolol    = await db.insert('active_ingredients', {'scientific_name': 'Atenolol',    'class_id': c3});
    final metoprolol  = await db.insert('active_ingredients', {'scientific_name': 'Metoprolol',  'class_id': c3});
    final bisoprolol  = await db.insert('active_ingredients', {'scientific_name': 'Bisoprolol',  'class_id': c3});
    final carvedilol  = await db.insert('active_ingredients', {'scientific_name': 'Carvedilol',  'class_id': c3});

    for (final b in [
      {'brand_name': 'Tenormin',    'company': 'AstraZeneca',  'ingredient_id': atenolol},
      {'brand_name': 'Aten',        'company': 'Local',        'ingredient_id': atenolol},
      {'brand_name': 'Lopressor',   'company': 'Novartis',     'ingredient_id': metoprolol},
      {'brand_name': 'Betaloc',     'company': 'AstraZeneca',  'ingredient_id': metoprolol},
      {'brand_name': 'Concor',      'company': 'Merck',        'ingredient_id': bisoprolol},
      {'brand_name': 'Bisocor',     'company': 'Local',        'ingredient_id': bisoprolol},
      {'brand_name': 'Coreg',       'company': 'GSK',          'ingredient_id': carvedilol},
      {'brand_name': 'Carvid',      'company': 'Local',        'ingredient_id': carvedilol},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 4. مثبطات ACE — ACE Inhibitors
    // ══════════════════════════════════════════════════════════════════
    final c4 = await db.insert('drug_classes', {'class_name': 'ACE Inhibitors (مثبطات الإنزيم المحول)'});
    final enalapril   = await db.insert('active_ingredients', {'scientific_name': 'Enalapril',   'class_id': c4});
    final lisinopril  = await db.insert('active_ingredients', {'scientific_name': 'Lisinopril',  'class_id': c4});
    final ramipril    = await db.insert('active_ingredients', {'scientific_name': 'Ramipril',    'class_id': c4});
    final captopril   = await db.insert('active_ingredients', {'scientific_name': 'Captopril',   'class_id': c4});

    for (final b in [
      {'brand_name': 'Vasotec',     'company': 'Merck',        'ingredient_id': enalapril},
      {'brand_name': 'Enalapril',   'company': 'Local',        'ingredient_id': enalapril},
      {'brand_name': 'Zestril',     'company': 'AstraZeneca',  'ingredient_id': lisinopril},
      {'brand_name': 'Prinivil',    'company': 'Merck',        'ingredient_id': lisinopril},
      {'brand_name': 'Tritace',     'company': 'Sanofi',       'ingredient_id': ramipril},
      {'brand_name': 'Ramace',      'company': 'Local',        'ingredient_id': ramipril},
      {'brand_name': 'Capoten',     'company': 'BMS',          'ingredient_id': captopril},
      {'brand_name': 'Captopril',   'company': 'Local',        'ingredient_id': captopril},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 5. ستاتينات — Statins
    // ══════════════════════════════════════════════════════════════════
    final c5 = await db.insert('drug_classes', {'class_name': 'Statins - HMG-CoA Reductase Inhibitors (الستاتينات)'});
    final atorvastatin  = await db.insert('active_ingredients', {'scientific_name': 'Atorvastatin',  'class_id': c5});
    final rosuvastatin  = await db.insert('active_ingredients', {'scientific_name': 'Rosuvastatin',  'class_id': c5});
    final simvastatin   = await db.insert('active_ingredients', {'scientific_name': 'Simvastatin',   'class_id': c5});

    for (final b in [
      {'brand_name': 'Lipitor',     'company': 'Pfizer',       'ingredient_id': atorvastatin},
      {'brand_name': 'Atorva',      'company': 'Local',        'ingredient_id': atorvastatin},
      {'brand_name': 'Crestor',     'company': 'AstraZeneca',  'ingredient_id': rosuvastatin},
      {'brand_name': 'Rosulip',     'company': 'Local',        'ingredient_id': rosuvastatin},
      {'brand_name': 'Zocor',       'company': 'Merck',        'ingredient_id': simvastatin},
      {'brand_name': 'Simvast',     'company': 'Local',        'ingredient_id': simvastatin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 6. مضادات الهيستامين — Antihistamines
    // ══════════════════════════════════════════════════════════════════
    final c6 = await db.insert('drug_classes', {'class_name': 'Antihistamines H1 (مضادات الهيستامين)'});
    final cetirizine    = await db.insert('active_ingredients', {'scientific_name': 'Cetirizine',    'class_id': c6});
    final loratadine    = await db.insert('active_ingredients', {'scientific_name': 'Loratadine',    'class_id': c6});
    final fexofenadine  = await db.insert('active_ingredients', {'scientific_name': 'Fexofenadine',  'class_id': c6});
    final levocetirizine= await db.insert('active_ingredients', {'scientific_name': 'Levocetirizine','class_id': c6});

    for (final b in [
      {'brand_name': 'Zyrtec',      'company': 'UCB',          'ingredient_id': cetirizine},
      {'brand_name': 'Cetrine',     'company': 'Local',        'ingredient_id': cetirizine},
      {'brand_name': 'Claritin',    'company': 'Bayer',        'ingredient_id': loratadine},
      {'brand_name': 'Loratin',     'company': 'Local',        'ingredient_id': loratadine},
      {'brand_name': 'Allegra',     'company': 'Sanofi',       'ingredient_id': fexofenadine},
      {'brand_name': 'Fexo',        'company': 'Local',        'ingredient_id': fexofenadine},
      {'brand_name': 'Xyzal',       'company': 'UCB',          'ingredient_id': levocetirizine},
      {'brand_name': 'Levozine',    'company': 'Local',        'ingredient_id': levocetirizine},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 7. مضادات السكري — Metformin/Biguanides
    // ══════════════════════════════════════════════════════════════════
    final c7 = await db.insert('drug_classes', {'class_name': 'Biguanides - Oral Antidiabetics (البيغوانيدات)'});
    final metformin   = await db.insert('active_ingredients', {'scientific_name': 'Metformin',   'class_id': c7});

    for (final b in [
      {'brand_name': 'Glucophage',  'company': 'Merck',        'ingredient_id': metformin},
      {'brand_name': 'Fortamet',    'company': 'Shionogi',     'ingredient_id': metformin},
      {'brand_name': 'Glucomet',    'company': 'Local',        'ingredient_id': metformin},
      {'brand_name': 'Riomet',      'company': 'Sun Pharma',   'ingredient_id': metformin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 8. مضادات الالتهاب — NSAIDs
    // ══════════════════════════════════════════════════════════════════
    final c8 = await db.insert('drug_classes', {'class_name': 'NSAIDs (مضادات الالتهاب غير الستيرويدية)'});
    final ibuprofen    = await db.insert('active_ingredients', {'scientific_name': 'Ibuprofen',    'class_id': c8});
    final diclofenac   = await db.insert('active_ingredients', {'scientific_name': 'Diclofenac',   'class_id': c8});
    final naproxen     = await db.insert('active_ingredients', {'scientific_name': 'Naproxen',     'class_id': c8});
    final meloxicam    = await db.insert('active_ingredients', {'scientific_name': 'Meloxicam',    'class_id': c8});

    for (final b in [
      {'brand_name': 'Advil',       'company': 'Pfizer',       'ingredient_id': ibuprofen},
      {'brand_name': 'Brufen',      'company': 'Abbott',       'ingredient_id': ibuprofen},
      {'brand_name': 'Nurofen',     'company': 'Reckitt',      'ingredient_id': ibuprofen},
      {'brand_name': 'Voltaren',    'company': 'Novartis',     'ingredient_id': diclofenac},
      {'brand_name': 'Cataflam',    'company': 'Novartis',     'ingredient_id': diclofenac},
      {'brand_name': 'Diclogesic',  'company': 'Local',        'ingredient_id': diclofenac},
      {'brand_name': 'Naprosyn',    'company': 'Roche',        'ingredient_id': naproxen},
      {'brand_name': 'Aleve',       'company': 'Bayer',        'ingredient_id': naproxen},
      {'brand_name': 'Mobic',       'company': 'Boehringer',   'ingredient_id': meloxicam},
      {'brand_name': 'Melox',       'company': 'Local',        'ingredient_id': meloxicam},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 9. مضادات حيوية — Fluoroquinolones
    // ══════════════════════════════════════════════════════════════════
    final c9 = await db.insert('drug_classes', {'class_name': 'Fluoroquinolones (الفلوروكينولونات)'});
    final ciprofloxacin  = await db.insert('active_ingredients', {'scientific_name': 'Ciprofloxacin',  'class_id': c9});
    final levofloxacin   = await db.insert('active_ingredients', {'scientific_name': 'Levofloxacin',   'class_id': c9});
    final moxifloxacin   = await db.insert('active_ingredients', {'scientific_name': 'Moxifloxacin',   'class_id': c9});

    for (final b in [
      {'brand_name': 'Cipro',       'company': 'Bayer',        'ingredient_id': ciprofloxacin},
      {'brand_name': 'Ciproxin',    'company': 'Bayer',        'ingredient_id': ciprofloxacin},
      {'brand_name': 'Ciplox',      'company': 'Cipla',        'ingredient_id': ciprofloxacin},
      {'brand_name': 'Levaquin',    'company': 'J&J',          'ingredient_id': levofloxacin},
      {'brand_name': 'Tavanic',     'company': 'Sanofi',       'ingredient_id': levofloxacin},
      {'brand_name': 'Avelox',      'company': 'Bayer',        'ingredient_id': moxifloxacin},
      {'brand_name': 'Moxif',       'company': 'Local',        'ingredient_id': moxifloxacin},
    ]) { await db.insert('commercial_brands', b); }

    // ══════════════════════════════════════════════════════════════════
    // 10. مسكنات — Paracetamol
    // ══════════════════════════════════════════════════════════════════
    final c10 = await db.insert('drug_classes', {'class_name': 'Analgesics - Paracetamol (مسكنات الألم)'});
    final paracetamol   = await db.insert('active_ingredients', {'scientific_name': 'Paracetamol (Acetaminophen)', 'class_id': c10});
    final tramadol      = await db.insert('active_ingredients', {'scientific_name': 'Tramadol',      'class_id': c10});

    for (final b in [
      {'brand_name': 'Panadol',     'company': 'GSK',          'ingredient_id': paracetamol},
      {'brand_name': 'Tylenol',     'company': 'J&J',          'ingredient_id': paracetamol},
      {'brand_name': 'Calpol',      'company': 'GSK',          'ingredient_id': paracetamol},
      {'brand_name': 'Paracet',     'company': 'Local',        'ingredient_id': paracetamol},
      {'brand_name': 'Tramal',      'company': 'Grunenthal',   'ingredient_id': tramadol},
      {'brand_name': 'Ultram',      'company': 'J&J',          'ingredient_id': tramadol},
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
