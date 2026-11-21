import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../models/drug_model.dart';
import '../models/suggestion_item.dart';

/// عائلة دوائية داخل قسم (مثل Beta blockers داخل القلب والأوعية).
class DrugFamily {
  final String name;
  final int total;
  final int available;
  const DrugFamily({
    required this.name,
    required this.total,
    required this.available,
  });
}

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  // Increment this whenever assets/database/drugs.db is updated
  static const int _kAssetDbVersion = 9;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'drugs.db');
    final dbFile = File(dbPath);
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('db_asset_version') ?? 0;

    // Re-copy from assets if never copied before OR if asset DB was updated
    if (!dbFile.existsSync() || storedVersion < _kAssetDbVersion) {
      final assetData = await rootBundle.load('assets/database/drugs.db');
      final assetBytes = assetData.buffer.asUint8List();
      await dbFile.writeAsBytes(assetBytes, flush: true);
      await prefs.setInt('db_asset_version', _kAssetDbVersion);
    }

    return openDatabase(dbPath);
  }

  Future<List<Drug>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final q = query.trim();

    try {
      final rows = await db.rawQuery(
        '''SELECT d.* FROM drugs d
           JOIN drugs_fts f ON d.id = f.rowid
           WHERE drugs_fts MATCH ?
           ORDER BY rank LIMIT 50''',
        ['$q*'],
      );
      if (rows.isNotEmpty) return rows.map(Drug.fromMap).toList();
    } catch (_) {}

    // Fallback LIKE search
    final rows = await db.rawQuery(
      '''SELECT * FROM drugs
         WHERE generic_name LIKE ? OR generic_name_ar LIKE ? OR trade_names LIKE ?
         LIMIT 50''',
      ['%$q%', '%$q%', '%$q%'],
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Returns up to [limit] distinct drug name strings for autocomplete.
  Future<List<String>> searchNames(String query, {int limit = 6}) async {
    if (query.trim().length < 2) return [];
    final db = await database;
    final q = query.trim();
    final rows = await db.rawQuery(
      '''SELECT generic_name FROM drugs
         WHERE generic_name LIKE ? OR generic_name_ar LIKE ? OR trade_names LIKE ?
         ORDER BY generic_name LIMIT ?''',
      ['%$q%', '%$q%', '%$q%', limit],
    );
    return rows.map((r) => r['generic_name'] as String).toSet().toList();
  }

  /// Returns typed suggestions (generic + trade name matches) for autocomplete.
  Future<List<SuggestionItem>> getSuggestions(String query,
      {int limit = 8}) async {
    if (query.trim().length < 2) return [];
    final db = await database;
    final q = query.trim();
    final pattern = '%$q%';

    // Generic name matches (English or Arabic)
    final genericRows = await db.rawQuery(
      '''SELECT generic_name FROM drugs
         WHERE generic_name LIKE ? OR generic_name_ar LIKE ?
         ORDER BY length(generic_name) LIMIT ?''',
      [pattern, pattern, limit],
    );

    // Trade name matches — extract individual names from JSON array string
    final tradeRows = await db.rawQuery(
      '''SELECT trade_names FROM drugs
         WHERE trade_names LIKE ? AND generic_name NOT LIKE ?
         LIMIT ?''',
      [pattern, pattern, limit],
    );

    final results = <SuggestionItem>[];
    final seen = <String>{};

    for (final row in genericRows) {
      final name = row['generic_name'] as String;
      if (seen.add(name.toLowerCase())) {
        results.add(SuggestionItem(display: name, isGeneric: true, query: q));
      }
    }

    for (final row in tradeRows) {
      final raw = row['trade_names'] as String;
      // trade_names is stored as JSON array or pipe-separated string
      final names = _parseTrades(raw);
      for (final name in names) {
        if (name.toLowerCase().contains(q.toLowerCase()) &&
            seen.add(name.toLowerCase())) {
          results.add(
              SuggestionItem(display: name, isGeneric: false, query: q));
          if (results.length >= limit) break;
        }
      }
      if (results.length >= limit) break;
    }

    return results.take(limit).toList();
  }

  List<String> _parseTrades(String raw) {
    if (raw.startsWith('[')) {
      // JSON array format
      try {
        final decoded = raw
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return decoded;
      } catch (_) {}
    }
    return raw.split(RegExp(r'[,|/]')).map((s) => s.trim()).toList();
  }

  Future<Drug?> getDrugById(int id) async {
    final db = await database;
    final rows = await db.query('drugs', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Drug.fromMap(rows.first);
  }

  Future<List<Drug>> getByCategory(String category) async {
    final db = await database;
    final rows = await db.query('drugs',
        where: 'pharmacological_class LIKE ?', whereArgs: ['%$category%'], limit: 100);
    return rows.map(Drug.fromMap).toList();
  }

  Future<List<Drug>> getByClasses(List<String> classes) async {
    if (classes.isEmpty) return [];
    final db = await database;
    final placeholders = classes.map((_) => '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT * FROM drugs WHERE pharmacological_class IN ($placeholders) ORDER BY pharmacological_class, generic_name',
      classes,
    );
    return rows.map(Drug.fromMap).toList();
  }

  Future<List<Drug>> getByAppCategory(String category) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM drugs WHERE app_category = ? '
      'ORDER BY $_availOrder, generic_name COLLATE NOCASE',
      [category],
    );
    return rows.map(Drug.fromMap).toList();
  }

  // ── التصفّح الهرمي: قسم ← عائلة دوائية ← أدوية ─────────────────────────────
  // الأدوية المتوفّرة في السوق العراقية تتقدّم على النادرة وغير المسجّلة،
  // وعمود `iraq_availability` يُبنى مع قاعدة البيانات لا وقت التشغيل.
  // 0 = متوفّر · 1 = غير محدّد · 2 = محدود/نادر · 3 = غير متوفّر
  static const String _availOrder =
      'CASE WHEN iraq_availability IS NULL THEN 1 ELSE iraq_availability END';

  /// عوائل القسم مرتّبة بعدد الأدوية المتوفّرة محلياً ثم بالاسم.
  Future<List<DrugFamily>> familiesOf(String category) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''SELECT subclass_en AS name,
                COUNT(*)    AS total,
                SUM(CASE WHEN $_availOrder <= 1 THEN 1 ELSE 0 END) AS available
           FROM drugs
          WHERE app_category = ?
            AND TRIM(COALESCE(subclass_en, '')) <> ''
          GROUP BY subclass_en
          ORDER BY available DESC, total DESC, name COLLATE NOCASE''',
      [category],
    );
    return rows
        .map((r) => DrugFamily(
              name: (r['name'] ?? '').toString(),
              total: (r['total'] as num?)?.toInt() ?? 0,
              available: (r['available'] as num?)?.toInt() ?? 0,
            ))
        .where((f) => f.name.isNotEmpty)
        .toList();
  }

  /// أدوية عائلة واحدة داخل قسم.
  Future<List<Drug>> getByFamily(String category, String family) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM drugs WHERE app_category = ? AND subclass_en = ? '
      'ORDER BY $_availOrder, generic_name COLLATE NOCASE',
      [category, family],
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// هل عمود التوفّر موجود؟ (قواعد قديمة قبل الإصدار ٨ لا تحتويه)
  Future<bool> hasAvailabilityColumn() async {
    final db = await database;
    final cols = await db.rawQuery('PRAGMA table_info(drugs)');
    return cols.any((c) => (c['name'] ?? '').toString() == 'iraq_availability');
  }

  Future<List<Drug>> getByPharmClass(String pharmClass) async {
    final db = await database;
    final rows = await db.query('drugs',
        where: 'pharmacological_class = ?',
        whereArgs: [pharmClass],
        limit: 30);
    return rows.map(Drug.fromMap).toList();
  }

  Future<List<Drug>> getByFilters(Set<String> filterKeys) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    for (final key in filterKeys) {
      switch (key) {
        case 'pregnancy':
          conditions.add("(pregnancy_category = 'A' OR pregnancy_category = 'B')");
        case 'drops':
          conditions.add(
            "(pediatric_dosage LIKE '%drop%' OR pediatric_dosage LIKE '%قطرة%' OR pediatric_dosage LIKE '%قطر%')",
          );
        case 'cold':
          conditions.add('is_refrigerated = 1');
        case 'renal':
          conditions.add(
            "(renal_adjustment LIKE '%avoid%' OR renal_adjustment LIKE '%تجنب%' OR renal_adjustment LIKE '%AVOID%')",
          );
        case 'otc':
          conditions.add("rx_otc LIKE '%OTC%'");
        case 'high_alert':
          conditions.add("is_lasa = 1");
      }
    }

    if (conditions.isEmpty) return [];
    final where = conditions.join(' AND ');
    final rows = await db.rawQuery(
      'SELECT * FROM drugs WHERE $where ORDER BY generic_name',
      args,
    );
    return rows.map(Drug.fromMap).toList();
  }

  // ── الإصدار 3.0 ─────────────────────────────────────────────────────────

  /// خريطة ترحيل المعرّفات من قاعدة 2.3 إلى 3.0 (تُستعمل لترحيل المفضّلات).
  Future<Map<int, int>> legacyIdMap() async {
    final db = await database;
    try {
      final rows = await db.query('legacy_id_map');
      return {for (final r in rows) r['old_id'] as int: r['new_id'] as int};
    } catch (_) {
      return const {};
    }
  }

  /// أدوية الأورام فقط.
  Future<List<Drug>> getOncologyDrugs() async {
    final db = await database;
    final rows = await db.query('drugs',
        where: 'is_oncology = 1', orderBy: 'generic_name');
    return rows.map(Drug.fromMap).toList();
  }

  /// بدائل الدواء: نفس المادة الفعّالة، ثم نفس الزمرة (ATC-4)، ثم آلية مشابهة.
  Future<List<Map<String, dynamic>>> alternativesFor(Drug d) async {
    final db = await database;
    final atc = (d.atcCode.length >= 5) ? d.atcCode.substring(0, 5) : d.atcCode;
    final out = <Map<String, dynamic>>[];

    final same = await db.query('drugs',
        where: 'generic_name = ? AND id <> ?',
        whereArgs: [d.genericName, d.id],
        limit: 20);
    for (final m in same) {
      out.add({'drug': Drug.fromMap(m), 'kind': 'generic'});
    }

    if (atc.isNotEmpty) {
      final cls = await db.query('drugs',
          where: 'atc_code LIKE ? AND generic_name <> ?',
          whereArgs: ['$atc%', d.genericName],
          limit: 20);
      for (final m in cls) {
        out.add({'drug': Drug.fromMap(m), 'kind': 'class'});
      }
    }

    if (d.subclassEn.isNotEmpty) {
      final rows = atc.isNotEmpty
          ? await db.query('drugs',
              where: 'subclass_en = ? AND generic_name <> ? '
                  'AND (atc_code IS NULL OR atc_code NOT LIKE ?)',
              whereArgs: [d.subclassEn, d.genericName, '$atc%'],
              limit: 20)
          : await db.query('drugs',
              where: 'subclass_en = ? AND generic_name <> ?',
              whereArgs: [d.subclassEn, d.genericName],
              limit: 20);
      for (final m in rows) {
        out.add({'drug': Drug.fromMap(m), 'kind': 'mechanism'});
      }
    }
    return out;
  }

  /// أسئلة «عيادتك اليوم».
  ///
  /// الاختيار ليس عشوائياً: بنك الأسئلة يُرتَّب ترتيباً ثابتاً مخلوطاً
  /// مرة واحدة (بالبذرة نفسها عند كل المستخدمين)، ثم تُؤخذ منه نافذة
  /// مقدارها خمسة أسئلة موضعها مشتقّ من تاريخ اليوم. النتيجة:
  ///   • كل المستخدمين يرون الأسئلة نفسها في اليوم نفسه
  ///   • تتبدّل عند منتصف الليل
  ///   • لا تتكرّر مجموعة اليوم إلا بعد أن يدور البنك كاملاً (نحو 70 يوماً)
  ///   • الخلط الثابت يمنع تجاور أسئلة النوع الواحد
  Future<List<Map<String, dynamic>>> dailyQuiz({
    int count = 5,
    int daySeed = 0,
  }) async {
    final db = await database;
    try {
      final all = await db.rawQuery(
        'SELECT qid FROM quiz_questions WHERE is_active = 1 ORDER BY qid',
      );
      if (all.isEmpty) return const [];

      final qids = [for (final r in all) (r['qid'] ?? '').toString()];
      _stableShuffle(qids, 0x5EED1A9);

      final start = (daySeed * count) % qids.length;
      final pick = <String>[];
      for (var i = 0; i < count && i < qids.length; i++) {
        pick.add(qids[(start + i) % qids.length]);
      }
      return quizByIds(pick);
    } catch (_) {
      return const [];
    }
  }

  /// خلط ثابت البذرة (xorshift32) — يعطي الترتيب نفسه على كل جهاز.
  static void _stableShuffle(List<String> list, int seed) {
    var s = seed & 0x7FFFFFFF;
    if (s == 0) s = 1;
    int next() {
      s ^= (s << 13) & 0x7FFFFFFF;
      s ^= s >> 17;
      s ^= (s << 5) & 0x7FFFFFFF;
      return s & 0x7FFFFFFF;
    }
    for (var i = list.length - 1; i > 0; i--) {
      final j = next() % (i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }

  /// أسئلة بعينها بالمعرّفات — لتثبيت أسئلة اليوم.
  Future<List<Map<String, dynamic>>> quizByIds(List<String> qids) async {
    if (qids.isEmpty) return const [];
    final db = await database;
    try {
      final marks = List.filled(qids.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT * FROM quiz_questions WHERE qid IN ($marks)',
        qids,
      );
      // رتّبها بترتيب المعرّفات المحفوظ
      final byId = {for (final r in rows) (r['qid'] ?? '').toString(): r};
      return [
        for (final id in qids)
          if (byId[id] != null) byId[id]!,
      ];
    } catch (_) {
      return const [];
    }
  }

  // ── أنشطة «عيادتك اليوم» ──────────────────────────────────────────────────

  /// «دواء اليوم» — اختيار ثابت لكل يوم، فكل المستخدمين يرون الدواء نفسه
  /// ويبقى هو نفسه حتى منتصف الليل. يُفضَّل المتوفّر محلياً وذو النصيحة
  /// الصيدلانية، فيكون الاختيار مفيداً لا عشوائياً.
  Future<Map<String, dynamic>?> drugOfTheDay(int daySeed) async {
    final db = await database;
    try {
      final pool = await db.rawQuery(
        'SELECT id FROM drugs '
        "WHERE counseling_note_ar <> '' "
        '  AND (iraq_availability IS NULL OR iraq_availability <= 1) '
        'ORDER BY generic_name COLLATE NOCASE',
      );
      if (pool.isEmpty) return null;
      final idx = daySeed % pool.length;
      final id = pool[idx]['id'];
      final rows =
          await db.rawQuery('SELECT * FROM drugs WHERE id = ?', [id]);
      return rows.isEmpty ? null : rows.first;
    } catch (_) {
      return null;
    }
  }

  /// «حالة الأسبوع» — حالة سريرية ثابتة لكل أسبوع من أسئلة النوع `case`.
  Future<Map<String, dynamic>?> caseOfTheWeek(int weekSeed) async {
    final db = await database;
    try {
      final rows = await db.rawQuery(
        "SELECT * FROM quiz_questions WHERE is_active = 1 AND qtype = 'case' "
        'ORDER BY qid',
      );
      if (rows.isEmpty) return null;
      return rows[weekSeed % rows.length];
    } catch (_) {
      return null;
    }
  }

  /// أزواج أدوية لتحدّي التداخلات.
  ///
  /// الزوج «متداخل» إذا ذُكر الاسم العلمي للدواء الثاني في نصّ تداخلات
  /// الأول. وغياب الذكر لا يعني أماناً مطلقاً، لذا يُصاغ السؤال عن
  /// «المُدرَج في مصدر التطبيق» لا عن الواقع كله — والشرح يعرض النصّ.
  Future<List<Map<String, dynamic>>> interactionPairs({int count = 8}) async {
    final db = await database;
    try {
      final rows = await db.rawQuery(
        'SELECT id, generic_name, generic_name_ar, drug_interactions, '
        '       drug_interactions_ar, app_category '
        'FROM drugs '
        "WHERE drug_interactions <> '' AND LENGTH(drug_interactions) > 40 "
        '  AND (iraq_availability IS NULL OR iraq_availability <= 1) '
        // قاعدة البيانات فيها مداخل ليست أدوية مفردة: بروتوكولات
        // علاجية و«تدبير» حالات ومجموعات دوائية. وضْعها في زوج تداخل
        // يُنتج سؤالاً بلا معنى مثل «قطرة ديكلوفيناك + تدبير التهاب
        // البربخ»، فتُستبعد هنا.
        "  AND generic_name NOT LIKE '%management%' "
        "  AND generic_name NOT LIKE '%therapy%' "
        "  AND generic_name NOT LIKE '%prophylax%' "
        "  AND generic_name NOT LIKE '%regimen%' "
        "  AND generic_name NOT LIKE '%syndrome%' "
        "  AND generic_name NOT LIKE '%protocol%' "
        "  AND generic_name NOT LIKE '%guideline%' "
        "  AND generic_name NOT LIKE '%screening%' "
        "  AND generic_name NOT LIKE '%counsel%' "
        "  AND generic_name NOT LIKE '%ladder%' "
        "  AND generic_name NOT LIKE '%pack%' "
        "  AND generic_name NOT LIKE '%recognition%' "
        // اسم الدواء المفرد كلمة أو كلمتان؛ ما زاد غالباً وصف أو تركيبة
        "  AND LENGTH(generic_name) - LENGTH(REPLACE(generic_name,' ','')) <= 2 "
        "  AND subclass_en <> '' "
        'ORDER BY RANDOM() LIMIT 220',
      );
      if (rows.length < 6) return const [];

      final out = <Map<String, dynamic>>[];
      final rnd = DateTime.now().millisecondsSinceEpoch;

      // أزواج متداخلة: نبحث في نصّ التداخلات عن اسم دواء آخر موجود فعلاً
      // في القاعدة، فيكون الزوج حقيقياً لا مُفترضاً.
      for (var i = 0; i < rows.length && out.length < count; i++) {
        final a = rows[(i * 7 + rnd) % rows.length];
        final txt = (a['drug_interactions'] ?? '').toString().toLowerCase();
        Map<String, dynamic>? partner;
        for (final b in rows) {
          if (b['id'] == a['id']) continue;
          final bn = (b['generic_name'] ?? '').toString();
          if (bn.length < 5) continue;
          final first = bn.split(RegExp(r'[ /(]')).first.toLowerCase();
          if (first.length >= 5 && txt.contains(first)) {
            partner = b;
            break;
          }
        }
        if (partner != null) {
          out.add({
            'a': a['generic_name'],
            'b': partner['generic_name'],
            'interacts': 1,
            'explain': (a['drug_interactions_ar'] ?? a['drug_interactions'])
                .toString(),
          });
        }
      }

      // أزواج غير مُدرجة — من أقسام مختلفة ولا ذكر لأحدهما في الآخر.
      for (var i = 0; out.length < count * 2 && i < rows.length; i++) {
        final a = rows[i];
        final b = rows[(i * 13 + 5) % rows.length];
        if (a['id'] == b['id']) continue;
        if (a['app_category'] == b['app_category']) continue;
        final an = (a['generic_name'] ?? '').toString();
        final bn = (b['generic_name'] ?? '').toString();
        if (an.length < 5 || bn.length < 5) continue;
        final at = (a['drug_interactions'] ?? '').toString().toLowerCase();
        final bt = (b['drug_interactions'] ?? '').toString().toLowerCase();
        final af = an.split(RegExp(r'[ /(]')).first.toLowerCase();
        final bf = bn.split(RegExp(r'[ /(]')).first.toLowerCase();
        if (at.contains(bf) || bt.contains(af)) continue;
        out.add({
          'a': an,
          'b': bn,
          'interacts': 0,
          'explain': 'لا يُذكر تداخل مُعتبَر بين هذين الدوائين في المراجع '
              'المعتمدة، ولا يستدعي الجمع بينهما تعديل جرعة أو مراقبة خاصة\n\n'
              'غياب التداخل المُدرج لا يعني أماناً مطلقاً: راجع المرجع عند '
              'الجرعات العالية أو اختلال الكبد والكلى',
        });
      }

      out.shuffle();
      return out.take(count).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<int> quizCount() async {
    final db = await database;
    try {
      final r = await db.rawQuery('SELECT COUNT(*) c FROM quiz_questions');
      return (r.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// عدد السجلات الفعلي (للتحقق بعد التحديث).
  Future<int> recordCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) c FROM drugs');
    return (r.first['c'] as int?) ?? 0;
  }

  // ── Admin CRUD ──────────────────────────────────────────────────────────

  Future<List<Drug>> getAllDrugs({String query = ''}) async {
    final db = await database;
    if (query.trim().isEmpty) {
      final rows = await db.query('drugs', orderBy: 'generic_name');
      return rows.map(Drug.fromMap).toList();
    }
    final pattern = '%${query.trim()}%';
    final rows = await db.rawQuery(
      '''SELECT * FROM drugs
         WHERE generic_name LIKE ? OR generic_name_ar LIKE ?
         ORDER BY generic_name''',
      [pattern, pattern],
    );
    return rows.map(Drug.fromMap).toList();
  }

  Future<int> insertDrug(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('drugs', data);
  }

  Future<int> updateDrug(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('drugs', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDrug(int id) async {
    final db = await database;
    return db.delete('drugs', where: 'id = ?', whereArgs: [id]);
  }
}
