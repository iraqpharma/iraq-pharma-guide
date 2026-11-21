import 'video_source.dart';

/// فيديو تعليمي — الاستضافة خارجية والتطبيق يحفظ الرابط فقط.
class TrainingVideo {
  final int id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String appCategory;
  final String provider;      // youtube | vimeo | other
  final String videoUrl;
  final String videoRef;      // معرّف الفيديو المستخرج من الرابط
  final String thumbnailUrl;
  final int? durationSec;
  final DateTime publishedAt;
  final bool isPublished;
  final int sortOrder;

  const TrainingVideo({
    required this.id,
    required this.titleAr,
    this.titleEn = '',
    this.descriptionAr = '',
    this.appCategory = '',
    this.provider = 'youtube',
    required this.videoUrl,
    this.videoRef = '',
    this.thumbnailUrl = '',
    this.durationSec,
    required this.publishedAt,
    this.isPublished = false,
    this.sortOrder = 0,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory TrainingVideo.fromMap(Map<String, dynamic> m) => TrainingVideo(
        id: (m['id'] as num).toInt(),
        titleAr: _s(m['title_ar']),
        titleEn: _s(m['title_en']),
        descriptionAr: _s(m['description_ar']),
        appCategory: _s(m['app_category']),
        provider: _s(m['provider']).isEmpty ? 'youtube' : _s(m['provider']),
        videoUrl: _s(m['video_url']),
        videoRef: _s(m['video_ref']),
        thumbnailUrl: _s(m['thumbnail_url']),
        durationSec:
            m['duration_sec'] == null ? null : (m['duration_sec'] as num).toInt(),
        publishedAt: DateTime.tryParse(_s(m['published_at']))?.toLocal() ??
            DateTime.now(),
        isPublished: m['is_published'] == true,
        sortOrder: m['sort_order'] == null ? 0 : (m['sort_order'] as num).toInt(),
      );

  /// يستخرج معرّف فيديو يوتيوب من أي صيغة رابط شائعة.
  static String youtubeId(String url) {
    final u = url.trim();
    final patterns = <RegExp>[
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})'),
      RegExp(r'[?&]v=([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{6,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(u);
      if (m != null) return m.group(1)!;
    }
    return '';
  }

  String get thumb {
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    return source.thumbnail;
  }

  /// معرّف يوتيوب الجاهز للمشغّل المدمج — فارغ إذا لم يكن الفيديو من يوتيوب.
  String get ytId =>
      videoRef.isNotEmpty ? videoRef : youtubeId(videoUrl);

  /// المنصّة والمشغّل المناسبان — يُستنتجان من الرابط، فأي منصّة جديدة
  /// تعمل بمجرّد لصق رابطها بلا تعديل على قاعدة البيانات.
  VideoSource get source => VideoSource.detect(videoUrl);

  bool get canPlayInline => source.isInline;

  String get durationAr {
    final d = durationSec;
    if (d == null || d <= 0) return '';
    final m = d ~/ 60;
    final s = d % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// «جديد هذا الأسبوع»
  bool get isNew =>
      DateTime.now().difference(publishedAt).inDays <= 7;
}
