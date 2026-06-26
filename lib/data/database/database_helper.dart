import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../models/drug_model.dart';
import '../models/suggestion_item.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'drugs.db');

    // Always overwrite to pick up updated drug data
    final data = await rootBundle.load('assets/database/drugs.db');
    final bytes = data.buffer.asUint8List();
    await File(dbPath).writeAsBytes(bytes, flush: true);

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
         WHERE generic_name LIKE ? OR trade_names LIKE ?
         LIMIT 50''',
      ['%$q%', '%$q%'],
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
         WHERE generic_name LIKE ? OR trade_names LIKE ?
         ORDER BY generic_name LIMIT ?''',
      ['%$q%', '%$q%', limit],
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

    // Generic name matches
    final genericRows = await db.rawQuery(
      '''SELECT generic_name FROM drugs
         WHERE generic_name LIKE ?
         ORDER BY length(generic_name) LIMIT ?''',
      [pattern, limit],
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
}
