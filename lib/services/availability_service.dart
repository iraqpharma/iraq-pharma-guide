import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/availability_post.dart';

/// إعلانات توفّر الأدوية في الصيدليات.
///
/// الصلاحيات في قاعدة البيانات عبر RLS لا في التطبيق: الإعلان لا يظهر
/// قبل الموافقة، وصاحبه وحده يراه قبلها، والموافقة محصورة بحسابات
/// `database_admins`.
class AvailabilityService {
  AvailabilityService._();
  static final instance = AvailabilityService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<AvailabilityPost>> listLive({String? city, String? query}) async {
    var q = _db.from('availability_posts').select().eq('status', 'approved');
    if (city != null && city.isNotEmpty) q = q.eq('city', city);
    if (query != null && query.trim().length >= 2) {
      q = q.ilike('drug_name', '%${query.trim()}%');
    }
    final rows = await q.order('created_at', ascending: false).limit(200);
    return (rows as List)
        .map((e) => AvailabilityPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> cityCounts() async {
    try {
      final rows = await _db
          .from('availability_posts')
          .select('city')
          .eq('status', 'approved');
      final out = <String, int>{};
      for (final r in (rows as List)) {
        final c = ((r as Map)['city'] ?? '').toString().trim();
        if (c.isEmpty) continue;
        out[c] = (out[c] ?? 0) + 1;
      }
      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<List<AvailabilityPost>> listMine() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('availability_posts')
        .select()
        .eq('posted_by', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AvailabilityPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilityPost>> listPending() async {
    final rows = await _db
        .from('availability_posts')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => AvailabilityPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> pendingCount() async {
    try {
      final rows = await _db
          .from('availability_posts')
          .select('id')
          .eq('status', 'pending');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> create(AvailabilityPost post) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('يجب تسجيل الدخول لنشر إعلان');
    await _db.from('availability_posts').insert(post.toInsertMap(uid));
  }

  Future<void> approve(int id) async {
    await _db.from('availability_posts').update({
      'status': 'approved',
      'reject_reason': '',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
    }).eq('id', id);
  }

  Future<void> reject(int id, String reason) async {
    await _db.from('availability_posts').update({
      'status': 'rejected',
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
    }).eq('id', id);
  }

  /// يُغلقه صاحبه عند نفاد الكمية.
  Future<void> close(int id) async {
    await _db.from('availability_posts').update({'status': 'closed'}).eq('id', id);
  }
}
