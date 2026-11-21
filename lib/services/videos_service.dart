import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/training_video.dart';
import '../data/models/video_source.dart';

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
    // المنصّة تُستنتج من الرابط: يوتيوب، Vimeo، فيسبوك، تيك توك،
    // إنستغرام، ملف mp4 مباشر، أو رابط خارجي.
    final src = VideoSource.detect(videoUrl);
    await _db.from('training_videos').insert({
      'title_ar': titleAr,
      'description_ar': descriptionAr,
      'app_category': appCategory,
      'provider': src.provider,
      'video_url': videoUrl,
      'video_ref': src.ref,
      'thumbnail_url': src.thumbnail,
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
