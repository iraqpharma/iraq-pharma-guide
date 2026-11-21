import 'package:supabase_flutter/supabase_flutter.dart';

/// طلب إضافة دواء من مستخدم.
class DrugRequest {
  final String id;
  final String drugName;
  final String category;
  final String notes;
  final String status;   // new | reviewing | added | rejected | duplicate
  final DateTime createdAt;

  const DrugRequest({
    required this.id,
    required this.drugName,
    required this.category,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory DrugRequest.fromMap(Map<String, dynamic> m) => DrugRequest(
        id: _s(m['id']),
        drugName: _s(m['drug_name']),
        category: _s(m['category']),
        notes: _s(m['notes']),
        status: _s(m['status']).isEmpty ? 'new' : _s(m['status']),
        createdAt:
            DateTime.tryParse(_s(m['created_at']))?.toLocal() ?? DateTime.now(),
      );

  static const statusLabels = <String, String>{
    'new':       'جديد',
    'reviewing': 'قيد المراجعة',
    'added':     'أُضيف',
    'duplicate': 'موجود مسبقاً',
    'rejected':  'مرفوض',
  };

  String get statusAr => statusLabels[status] ?? status;
}

/// خدمات مركز «إعدادات التطبيق» الإداري.
class AppAdminService {
  AppAdminService._();
  static final instance = AppAdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── طلبات إضافة الأدوية ────────────────────────────────────────────────

  Future<List<DrugRequest>> drugRequests({String? status}) async {
    var q = _db.from('drug_requests').select();
    if (status != null && status.isNotEmpty) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false).limit(500);
    return (rows as List)
        .map((e) => DrugRequest.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> newRequestsCount() async {
    try {
      final rows =
          await _db.from('drug_requests').select('id').eq('status', 'new');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setRequestStatus(String id, String status) async {
    await _db.from('drug_requests').update({'status': status}).eq('id', id);
  }

  // ── الإعلانات التجارية ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> advertisements() async {
    final rows = await _db
        .from('advertisements')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> setAdActive(String id, bool active) async {
    await _db
        .from('advertisements')
        .update({'is_active': active}).eq('id', id);
  }
}
