import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/job_post.dart';

/// فرص العمل — القراءة والنشر والمراجعة الإدارية.
///
/// الصلاحيات مفروضة في قاعدة البيانات عبر RLS لا في التطبيق:
/// الإعلان لا يظهر لأحد قبل الموافقة، وصاحبه وحده يراه قبلها،
/// والموافقة محصورة بحسابات `database_admins`.
class JobsService {
  JobsService._();
  static final instance = JobsService._();

  SupabaseClient get _db => Supabase.instance.client;

  static const iraqCities = <String>[
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كربلاء', 'ذي قار',
    'بابل', 'ديالى', 'الأنبار', 'كركوك', 'واسط', 'صلاح الدين', 'ميسان',
    'المثنى', 'القادسية', 'دهوك', 'السليمانية',
  ];

  /// الإعلانات المنشورة (بعد الموافقة وغير المنتهية).
  Future<List<JobPost>> listLive({String? city, String? workType}) async {
    var q = _db.from('job_posts').select().eq('status', 'approved');
    if (city != null && city.isNotEmpty) q = q.eq('city', city);
    if (workType != null && workType.isNotEmpty) {
      q = q.eq('work_type', workType);
    }
    final rows = await q.order('created_at', ascending: false).limit(200);
    final list = (rows as List)
        .map((e) => JobPost.fromMap(e as Map<String, dynamic>))
        .toList();
    // الأكثر إعجاباً أولاً ثم الأحدث. الترتيب هنا لا في الاستعلام حتى
    // يبقى التطبيق عاملاً لو لم يُضَف عمود الإعجابات بعد.
    list.sort((a, b) {
      final l = b.likes.compareTo(a.likes);
      return l != 0 ? l : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  // ── الإعجاب ────────────────────────────────────────────────────────────

  /// معرّفات الإعلانات التي أعجب بها المستخدم الحالي.
  Future<Set<int>> myLikes() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return <int>{};
    try {
      final rows =
          await _db.from('job_likes').select('job_id').eq('user_id', uid);
      return {
        for (final r in (rows as List)) ((r as Map)['job_id'] as num).toInt(),
      };
    } catch (_) {
      return <int>{};
    }
  }

  /// يُبدّل الإعجاب ويُرجع الحالة الجديدة.
  Future<bool> toggleLike(int jobId, bool liked) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('سجّل الدخول لتتمكّن من الإعجاب');
    if (liked) {
      await _db.from('job_likes').delete().match({
        'job_id': jobId,
        'user_id': uid,
      });
      return false;
    }
    await _db.from('job_likes').insert({'job_id': jobId, 'user_id': uid});
    return true;
  }

  /// يُسجّل أن أحدهم ضغط اتصال أو واتساب.
  Future<void> bumpContact(int id) async {
    try {
      await _db.rpc('bump_job_contact', params: {'p_id': id});
    } catch (_) {/* العدّاد ليس حرجاً */}
  }

  /// عدد الإعلانات المنشورة في كل محافظة — يُظهر الرقم تحت أيقونة المحافظة.
  /// يُنقل عمود المدينة وحده لا الصفوف كاملة، فالتكلفة بضعة كيلوبايتات.
  Future<Map<String, int>> cityCounts() async {
    try {
      final rows =
          await _db.from('job_posts').select('city').eq('status', 'approved');
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

  /// إعلانات المستخدم الحالي بكل حالاتها.
  Future<List<JobPost>> listMine() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('job_posts')
        .select()
        .eq('posted_by', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => JobPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// الإعلانات بانتظار المراجعة — للمدراء فقط (RLS يمنع غيرهم).
  Future<List<JobPost>> listPending() async {
    final rows = await _db
        .from('job_posts')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => JobPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> pendingCount() async {
    try {
      final rows = await _db.from('job_posts').select('id').eq('status', 'pending');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> create(JobPost post) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('يجب تسجيل الدخول لنشر إعلان');
    }
    await _db.from('job_posts').insert(post.toInsertMap(uid));
  }

  /// كل الإعلانات بكل حالاتها — للمدراء فقط (RLS يُرجع لغيرهم إعلاناتهم
  /// والمنشور فقط).
  Future<List<JobPost>> listAllForAdmin() async {
    final rows = await _db
        .from('job_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(500);
    return (rows as List)
        .map((e) => JobPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// قاعدة البيانات لا ترمي خطأً حين تمنع RLS التعديل، بل تُعدّل صفر صفوف.
  /// نطلب الصف المعدَّل ونتحقّق منه حتى لا يُقال «تمّ» ولم يتمّ شيء.
  void _ensureChanged(dynamic rows) {
    if (rows is List && rows.isEmpty) {
      throw Exception('لم يُنفَّذ: لا صلاحية أو الإعلان غير موجود');
    }
  }

  /// نشر الإعلان (أو إعادة نشره). المدّة تبدأ من لحظة النشر لا من لحظة
  /// الإرسال، فلا تضيع أيام الانتظار من مدّة ظهوره.
  Future<void> approve(int id) async {
    final now = DateTime.now().toUtc();
    final rows = await _db.from('job_posts').update({
      'status': 'approved',
      'reviewed_at': now.toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
      'reject_reason': '',
      'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
    }).eq('id', id).select('id');
    _ensureChanged(rows);
  }

  /// إخفاء إعلان منشور دون حذفه — يمكن إعادة نشره لاحقاً.
  Future<void> hide(int id) async {
    final rows = await _db.from('job_posts').update({
      'status': 'closed',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
    }).eq('id', id).select('id');
    _ensureChanged(rows);
  }

  /// حذف نهائي لا رجعة فيه (تُحذف معه الإعجابات والبلاغات).
  Future<void> deletePermanently(int id) async {
    final rows =
        await _db.from('job_posts').delete().eq('id', id).select('id');
    _ensureChanged(rows);
  }

  Future<void> reject(int id, String reason) async {
    final rows = await _db.from('job_posts').update({
      'status': 'rejected',
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
    }).eq('id', id).select('id');
    _ensureChanged(rows);
  }

  /// يُغلقه صاحبه عند شغل الوظيفة.
  Future<void> close(int id) async {
    await _db.from('job_posts').update({'status': 'closed'}).eq('id', id);
  }

  Future<void> bumpView(int id) async {
    try {
      await _db.rpc('bump_job_view', params: {'p_id': id});
    } catch (_) {/* العدّاد ليس حرجاً */}
  }

  Future<void> report(int jobId, String reason) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('job_reports').insert({
      'job_id': jobId,
      'user_id': uid,
      'reason': reason,
    });
  }
}
