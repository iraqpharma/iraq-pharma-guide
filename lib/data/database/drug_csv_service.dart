import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

/// All editable columns of the `drugs` table, in a fixed order used for
/// both CSV export and import. `id` is included so updates can match
/// existing rows; if left blank on import, a new drug is inserted.
const List<String> kCsvColumns = [
  'id',
  'generic_name', 'generic_name_ar',
  'trade_names',
  'pharmacological_class', 'pharmacological_class_ar',
  'app_category',
  'mechanism_of_action', 'mechanism_of_action_ar',
  'indications', 'indications_ar',
  'adult_dosage', 'adult_dosage_ar',
  'pediatric_dosage',
  'renal_adjustment',
  'hepatic_adjustment',
  'administration_notes',
  'contraindications', 'contraindications_ar',
  'side_effects', 'side_effects_ar',
  'drug_interactions', 'drug_interactions_ar',
  'monitoring_notes',
  'counseling_note', 'counseling_note_ar',
  'pregnancy_category',
  'lactation_safety',
  'is_refrigerated',
  'is_lasa',
  'lasa_names',
  'black_box',
  'rx_otc',
  'iraq_market_note', 'iraq_market_note_ar',
  'iv_reconstitution',
  'image_asset',
];

class ImportResult {
  final int inserted;
  final int updated;
  final int skipped;
  final List<String> errors;
  ImportResult({required this.inserted, required this.updated, required this.skipped, required this.errors});
}

class DrugCsvService {
  /// Exports the full drugs table to a CSV file (UTF-8 with BOM so Excel
  /// renders Arabic correctly) and returns the file path.
  static Future<File> exportToCsv() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('drugs', orderBy: 'id');

    final data = <List<dynamic>>[kCsvColumns];
    for (final row in rows) {
      data.add(kCsvColumns.map((c) => row[c] ?? '').toList());
    }

    final csv = const ListToCsvConverter().convert(data);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/iraq_pharma_drugs_$timestamp.csv');
    // UTF-8 BOM (﻿) so Excel opens Arabic text correctly.
    await file.writeAsBytes([0xEF, 0xBB, 0xBF] + utf8.encode(csv));
    return file;
  }

  /// Imports drugs from a CSV file produced by [exportToCsv] (or matching
  /// its column headers). Rows with a matching `id` update the existing
  /// drug; rows with blank/unknown `id` are inserted as new drugs.
  static Future<ImportResult> importFromCsv(File file) async {
    final bytes = await file.readAsBytes();
    String content = utf8.decode(bytes, allowMalformed: true);
    if (content.startsWith('﻿')) content = content.substring(1);

    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content, eol: '\n');
    if (rows.isEmpty) {
      return ImportResult(inserted: 0, updated: 0, skipped: 0, errors: ['الملف فارغ']);
    }

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final colIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      colIndex[header[i]] = i;
    }
    if (!colIndex.containsKey('generic_name')) {
      return ImportResult(inserted: 0, updated: 0, skipped: 0,
          errors: ['الملف لا يحتوي عمود generic_name المطلوب']);
    }

    final db = await DatabaseHelper.instance.database;
    int inserted = 0, updated = 0, skipped = 0;
    final errors = <String>[];

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      String get(String col) {
        final idx = colIndex[col];
        if (idx == null || idx >= row.length) return '';
        return row[idx].toString();
      }

      final genericName = get('generic_name').trim();
      if (genericName.isEmpty) {
        skipped++;
        errors.add('سطر ${r + 1}: لا يحتوي اسم دواء');
        continue;
      }

      final data = <String, dynamic>{};
      for (final col in kCsvColumns) {
        if (col == 'id') continue;
        if (col == 'is_refrigerated' || col == 'is_lasa') {
          final v = get(col).trim();
          data[col] = (v == '1' || v.toLowerCase() == 'true') ? 1 : 0;
        } else {
          data[col] = get(col);
        }
      }
      if ((data['trade_names'] as String).trim().isEmpty) data['trade_names'] = '[]';
      if ((data['app_category'] as String).trim().isEmpty) data['app_category'] = 'other';
      if ((data['rx_otc'] as String).trim().isEmpty) data['rx_otc'] = 'Rx';

      try {
        final idStr = get('id').trim();
        final id = int.tryParse(idStr);
        if (id != null) {
          final existing = await db.query('drugs', where: 'id = ?', whereArgs: [id], limit: 1);
          if (existing.isNotEmpty) {
            await db.update('drugs', data, where: 'id = ?', whereArgs: [id]);
            updated++;
            continue;
          }
        }
        await db.insert('drugs', data);
        inserted++;
      } catch (e) {
        skipped++;
        errors.add('سطر ${r + 1} ($genericName): $e');
      }
    }

    return ImportResult(inserted: inserted, updated: updated, skipped: skipped, errors: errors);
  }
}
