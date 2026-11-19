import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/training_video.dart';

/// الفيديوهات التعليمية — القراءة للجميع والإدارة للمدراء فقط (RLS).
class VideosService {
  VideosService._();
  static final instance = VideosService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<TrainingVideo>> listPublished() async {
    final rows = await _db
        .from('training_videos')
        .select()
        .eq('is_published', true)
        .order('sort_order', ascending: true)
        .order('published_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((e) => TrainingVideo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// كل الفيديوهات بما فيها غير المنشور — تنجح للمدراء فقط.
  Future<List<TrainingVideo>> listAll() async {
    final rows = await _db
        .from('training_videos')
        .select()
        .order('published_at', ascending: false)
        .limit(300);
    return (rows as List)
        .map((e) => TrainingVideo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String titleAr,
    required String videoUrl,
    String descriptionAr = '',
    String appCategory = '',
    int? durationSec,
    bool publish = false,
  }) async {
    final ref = TrainingVideo.youtubeId(videoUrl);
    await _db.from('training_videos').insert({
      'title_ar': titleAr,
      'description_ar': descriptionAr,
      'app_category': appCategory,
      'provider': ref.isEmpty ? 'other' : 'youtube',
      'video_url': videoUrl,
      'video_ref': ref,
      'thumbnail_url':
          ref.isEmpty ? '' : 'https://img.youtube.com/vi/$ref/hqdefault.jpg',
      'duration_sec': durationSec,
      'is_published': publish,
      'created_by': _db.auth.currentUser?.email ?? '',
    });
  }

  Future<void> setPublished(int id, bool value) async {
    await _db
        .from('training_videos')
        .update({'is_published': value}).eq('id', id);
  }

  Future<void> remove(int id) async {
    await _db.from('training_videos').delete().eq('id', id);
  }
}
