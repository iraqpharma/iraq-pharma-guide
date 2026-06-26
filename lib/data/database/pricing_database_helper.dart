import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/local_pricing_entry.dart';

/// Separate writable database — never overwritten from assets.
/// Stores local commercial pricing data (no clinical data).
class PricingDatabaseHelper {
  static PricingDatabaseHelper? _instance;
  static Database? _db;

  PricingDatabaseHelper._();
  static PricingDatabaseHelper get instance =>
      _instance ??= PricingDatabaseHelper._();

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'pricing.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS local_pricing (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode       TEXT UNIQUE,
            trade_name    TEXT NOT NULL,
            cost_price    REAL,
            selling_price REAL
          )
        ''');
      },
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<LocalPricingEntry>> getAll() async {
    final db = await database;
    final rows = await db.query('local_pricing', orderBy: 'trade_name ASC');
    return rows.map(LocalPricingEntry.fromMap).toList();
  }

  Future<List<LocalPricingEntry>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final db = await database;
    final q = '%${query.trim()}%';
    final rows = await db.rawQuery(
      '''SELECT * FROM local_pricing
         WHERE trade_name LIKE ? OR barcode LIKE ?
         ORDER BY trade_name ASC''',
      [q, q],
    );
    return rows.map(LocalPricingEntry.fromMap).toList();
  }

  Future<int> insert(LocalPricingEntry entry) async {
    final db = await database;
    return db.insert(
      'local_pricing',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(LocalPricingEntry entry) async {
    final db = await database;
    return db.update(
      'local_pricing',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('local_pricing', where: 'id = ?', whereArgs: [id]);
  }

  Future<LocalPricingEntry?> getByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query('local_pricing',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    return rows.isEmpty ? null : LocalPricingEntry.fromMap(rows.first);
  }
}
