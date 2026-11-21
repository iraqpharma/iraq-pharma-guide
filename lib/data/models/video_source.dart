/// كيف يُشغَّل الفيديو داخل التطبيق.
///
/// القاعدة: المنصّة التي تعطي رابط «embed» عاماً بلا تسجيل دخول تُشغَّل
/// داخل التطبيق، والتي تطلب تسجيل دخول تُفتح خارجياً. لا شيء يُحمَّل
/// قبل أن يضغط المستخدم زر التشغيل، فالتمرير على القائمة لا يصرف داتا.
enum VideoKind {
  /// مشغّل يوتيوب الرسمي (IFrame API).
  youtube,

  /// صفحة embed للمنصّة تُعرض في WebView — Vimeo وفيسبوك وتيك توك…
  iframe,

  /// ملف فيديو مباشر (mp4 / m3u8) يُشغَّل بمشغّل النظام.
  file,

  /// لا يمكن تشغيله داخلياً — يُفتح في تطبيق المنصّة أو المتصفّح.
  external,
}

class VideoSource {
  final VideoKind kind;

  /// المنصّة كما تُخزَّن في العمود `provider`.
  final String provider;

  /// معرّف الفيديو على المنصّة (يوتيوب / Vimeo).
  final String ref;

  /// رابط العرض المستخدَم فعلاً: صفحة embed أو رابط الملف.
  final String playUrl;

  /// صورة مصغّرة إن أمكن استنتاجها من الرابط.
  final String thumbnail;

  /// اسم المنصّة للعرض على البطاقة.
  final String label;

  const VideoSource({
    required this.kind,
    required this.provider,
    this.ref = '',
    this.playUrl = '',
    this.thumbnail = '',
    this.label = '',
  });

  bool get isInline => kind != VideoKind.external;

  // ── الكشف من الرابط ────────────────────────────────────────────────────────

  static const _ytPatterns = <String>[
    r'youtu\.be/([A-Za-z0-9_-]{6,})',
    r'youtube\.com/watch\?(?:.*&)?v=([A-Za-z0-9_-]{6,})',
    r'youtube\.com/embed/([A-Za-z0-9_-]{6,})',
    r'youtube\.com/shorts/([A-Za-z0-9_-]{6,})',
    r'youtube\.com/live/([A-Za-z0-9_-]{6,})',
  ];

  static const _fileExts = <String>[
    '.mp4', '.m4v', '.mov', '.webm', '.mkv', '.m3u8',
  ];

  /// يستنتج المنصّة والمشغّل المناسب من الرابط وحده — الإداري يلصق
  /// الرابط ولا يختار شيئاً.
  static VideoSource detect(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      return const VideoSource(kind: VideoKind.external, provider: 'external');
    }
    final low = url.toLowerCase();

    // ── يوتيوب ───────────────────────────────────────────────────────────
    for (final p in _ytPatterns) {
      final m = RegExp(p).firstMatch(url);
      if (m != null) {
        final id = m.group(1)!;
        return VideoSource(
          kind: VideoKind.youtube,
          provider: 'youtube',
          ref: id,
          playUrl: url,
          thumbnail: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
          label: 'YouTube',
        );
      }
    }

    // ── Vimeo ────────────────────────────────────────────────────────────
    final vimeo = RegExp(r'vimeo\.com/(?:video/)?(\d{6,})').firstMatch(url);
    if (vimeo != null) {
      final id = vimeo.group(1)!;
      return VideoSource(
        kind: VideoKind.iframe,
        provider: 'vimeo',
        ref: id,
        // dnt=1 يمنع تتبّع المستخدم.
        playUrl: 'https://player.vimeo.com/video/$id?dnt=1&title=0&byline=0',
        label: 'Vimeo',
      );
    }

    // ── تيك توك ──────────────────────────────────────────────────────────
    final tiktok = RegExp(r'tiktok\.com/.*?/video/(\d{6,})').firstMatch(url);
    if (tiktok != null) {
      final id = tiktok.group(1)!;
      return VideoSource(
        kind: VideoKind.iframe,
        provider: 'tiktok',
        ref: id,
        playUrl: 'https://www.tiktok.com/embed/v2/$id',
        label: 'TikTok',
      );
    }

    // ── إنستغرام ─────────────────────────────────────────────────────────
    // إنستغرام يُظهر كثيراً جدار تسجيل دخول داخل الـ embed، فنجعل زر
    // «فتح في إنستغرام» ظاهراً دائماً على هذه البطاقات.
    final insta =
        RegExp(r'instagram\.com/(p|reel|reels|tv)/([A-Za-z0-9_-]+)')
            .firstMatch(url);
    if (insta != null) {
      final type = insta.group(1) == 'reels' ? 'reel' : insta.group(1)!;
      final code = insta.group(2)!;
      return VideoSource(
        kind: VideoKind.iframe,
        provider: 'instagram',
        ref: code,
        playUrl: 'https://www.instagram.com/$type/$code/embed/',
        label: 'Instagram',
      );
    }

    // ── فيسبوك ───────────────────────────────────────────────────────────
    if (low.contains('facebook.com/') || low.contains('fb.watch/')) {
      return VideoSource(
        kind: VideoKind.iframe,
        provider: 'facebook',
        playUrl: 'https://www.facebook.com/plugins/video.php'
            '?href=${Uri.encodeComponent(url)}&show_text=false&autoplay=false',
        label: 'Facebook',
      );
    }

    // ── Dailymotion ──────────────────────────────────────────────────────
    final dm = RegExp(r'dailymotion\.com/video/([A-Za-z0-9]+)').firstMatch(url);
    if (dm != null) {
      return VideoSource(
        kind: VideoKind.iframe,
        provider: 'dailymotion',
        ref: dm.group(1)!,
        playUrl: 'https://www.dailymotion.com/embed/video/${dm.group(1)!}',
        label: 'Dailymotion',
      );
    }

    // ── ملف فيديو مباشر ──────────────────────────────────────────────────
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? low;
    if (_fileExts.any(path.endsWith)) {
      return VideoSource(
        kind: VideoKind.file,
        provider: 'file',
        playUrl: url,
        label: 'ملف فيديو',
      );
    }

    // ── غير معروف ────────────────────────────────────────────────────────
    return VideoSource(
      kind: VideoKind.external,
      provider: 'external',
      playUrl: url,
      label: Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'رابط',
    );
  }
}
