import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pricing_entry.dart';

class PricingRepository {
  final _client = Supabase.instance.client;
  static const _table = 'drug_pricing';
  static const _cacheKey = 'pricing_cache';

  Future<void> _saveCache(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(rows));
  }

  /// الصفوف المخفيّة أسماء عبثية أو مستلزمات ليست أدوية، فلا تصل
  /// للمستخدم في أي مسار: لا من السيرفر ولا من الذاكرة المحليّة.
  static List<PricingEntry> _visible(Iterable<PricingEntry> rows) =>
      rows.where((e) => !e.isHidden).toList();

  Future<List<PricingEntry>> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return _visible(list.map((e) => PricingEntry.fromJson(e)));
    } catch (_) {
      return [];
    }
  }

  // جلب فوري للتحديث اليدوي
  Future<List<PricingEntry>> fetchFresh() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('is_hidden', false)
        .order('view_count', ascending: false)
        .order('trade_name', ascending: true);
    final rows = List<Map<String, dynamic>>.from(data);
    await _saveCache(rows);
    return _visible(rows.map(PricingEntry.fromJson));
  }

  // stream مرتّب حسب الأكثر مشاهدة
  Stream<List<PricingEntry>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('view_count', ascending: false)
        .map((rows) {
          _saveCache(rows);
          return _visible(rows.map(PricingEntry.fromJson));
        });
  }

  Stream<List<PricingEntry>> watchSearch(String query) {
    final q = query.trim().toLowerCase();
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('view_count', ascending: false)
        .map((rows) => _visible(rows.map(PricingEntry.fromJson)).where((e) =>
            e.tradeName.toLowerCase().contains(q) ||
            e.barcode.toLowerCase().contains(q)).toList());
  }

  // زيادة عداد المشاهدة عند فتح التفاصيل
  Future<void> incrementViewCount(String id) async {
    try {
      await _client.rpc('increment_view_count', params: {'entry_id': id});
    } catch (_) {}
  }
}
