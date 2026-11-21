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

  // ── المسجّلون والتفاعل ─────────────────────────────────────────────────
  //
  // القراءة تمرّ على دالّة محميّة في القاعدة تتحقّق من أن الحساب في
  // database_admins، فلا تُقرأ بيانات المستخدمين من حساب عادي حتى لو
  // عُدّل التطبيق.

  /// p_period: today أو week أو month
  Future<List<Registrant>> registrants(String period) async {
    final rows = await _db
        .rpc('get_recent_registrants', params: {'p_period': period});
    return (rows as List)
        .map((e) => Registrant.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> engagement() async {
    final res = await _db.rpc('get_engagement_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  // ── مراجعة دليل الأسعار ────────────────────────────────────────────────

  /// الصفوف المخفيّة بانتظار القرار: حذف نهائي أو إعادة إظهار.
  Future<List<Map<String, dynamic>>> hiddenPricing() async {
    final rows = await _db
        .from('drug_pricing')
        .select()
        .eq('is_hidden', true)
        .order('trade_name')
        .limit(500);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> setPricingHidden(dynamic id, bool hidden,
      {String reason = ''}) async {
    await _db.from('drug_pricing').update({
      'is_hidden': hidden,
      'hidden_reason': hidden ? reason : '',
    }).eq('id', id);
  }

  Future<void> deletePricing(dynamic id) async {
    await _db.from('drug_pricing').delete().eq('id', id);
  }

  /// فحص اسم منتج قبل قبوله: يمنع الأسماء العبثية والمواد غير الدوائية.
  ///
  /// يرجع سبب الرفض بالعربية، أو null إن كان الاسم مقبولاً.
  static String? validateProductName(String raw) {
    final n = raw.trim();
    if (n.length < 3) return 'الاسم قصير جداً';
    if (RegExp(r'^[0-9\s\-_.]+$').hasMatch(n)) return 'الاسم أرقام فقط';

    final lower = n.toLowerCase();

    // حرف واحد مكرّر أو ضربات لوحة مفاتيح
    if (RegExp(r'^(.)\1+$').hasMatch(lower.replaceAll(' ', ''))) {
      return 'الاسم حرف مكرّر';
    }
    if (RegExp(r'(.)\1{3,}').hasMatch(lower)) return 'تكرار غير طبيعي للحروف';
    if (RegExp(r'^(test|tst|xxx+|asd|qwe|zxc|aaa|bbb)').hasMatch(lower)) {
      return 'اسم تجريبي';
    }
    // اسم بلا أي حرف متحرّك ولا حرف عربي
    if (RegExp(r'^[a-z\s]+$').hasMatch(lower) &&
        !RegExp(r'[aeiouy]').hasMatch(lower)) {
      return 'الاسم ليس كلمة مفهومة';
    }

    // مستلزمات لا تخصّ دليل الأدوية
    const nonDrug = [
      'كانولا', 'سرنجة', 'سيرنجة', 'جبسون', 'شاش', 'قطن', 'كفوف', 'كمامة',
      'ميزان', 'بيوريت', 'خيط', 'condom', 'dettol', 'syringe', 'cannula',
      'gauze', 'glove', 'mask', 'plaster', 'thermometer',
    ];
    for (final w in nonDrug) {
      if (lower.contains(w.toLowerCase())) {
        return 'مستلزم طبّي لا دواء';
      }
    }
    return null;
  }
}

/// مستخدم مسجّل كما تعرضه لوحة الإحصائيات.
class Registrant {
  final String name;
  final String role;
  final String specialty;
  final String city;
  final String avatarUrl;
  final String email;
  final DateTime createdAt;
  final int searches;
  final int toolUses;

  const Registrant({
    required this.name,
    required this.role,
    required this.specialty,
    required this.city,
    required this.avatarUrl,
    required this.email,
    required this.createdAt,
    required this.searches,
    required this.toolUses,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();
  static int _i(dynamic v) =>
      v is int ? v : int.tryParse(_s(v)) ?? 0;

  factory Registrant.fromMap(Map<String, dynamic> m) => Registrant(
        name: _s(m['full_name']),
        role: _s(m['role']),
        specialty: _s(m['specialty']),
        city: _s(m['address']),
        avatarUrl: _s(m['avatar_url']),
        email: _s(m['email']),
        createdAt:
            DateTime.tryParse(_s(m['created_at']))?.toLocal() ?? DateTime.now(),
        searches: _i(m['drug_search_count']),
        toolUses: _i(m['tool_usage_count']),
      );

  /// الحرفان الأوّلان من الاسم، لمن لا صورة له
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    String head(String w) => w.runes.isEmpty
        ? ''
        : String.fromCharCode(w.runes.first);
    if (parts.length == 1) {
      final r = parts.first.runes.take(2).toList();
      return String.fromCharCodes(r);
    }
    return '${head(parts[0])}${head(parts[1])}';
  }

  String get subtitle {
    final bits = [
      if (role.trim().isNotEmpty) role.trim(),
      if (specialty.trim().isNotEmpty) specialty.trim(),
      if (city.trim().isNotEmpty) city.trim(),
    ];
    return bits.isEmpty ? 'لم يُكمل ملفه' : bits.join('  ·  ');
  }
}
