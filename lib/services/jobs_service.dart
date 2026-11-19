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
    return (rows as List)
        .map((e) => JobPost.fromMap(e as Map<String, dynamic>))
        .toList();
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

  Future<void> approve(int id) async {
    await _db.from('job_posts').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
      'reject_reason': '',
    }).eq('id', id);
  }

  Future<void> reject(int id, String reason) async {
    await _db.from('job_posts').update({
      'status': 'rejected',
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': _db.auth.currentUser?.email ?? '',
    }).eq('id', id);
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
