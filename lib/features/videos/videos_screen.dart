import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/training_video.dart';
import '../../data/models/video_source.dart';
import '../../services/admin_access_service.dart';
import '../../services/videos_service.dart';
import 'inline_players.dart';

/// الفيديوهات التعليمية — تُفتح في مشغّل الجهاز، والتطبيق يحفظ الرابط فقط.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  bool _isAdmin = false;
  late Future<List<TrainingVideo>> _future = VideosService.instance.listPublished();

  @override
  void initState() {
    super.initState();
    AdminAccessService.instance.hasAccess().then((v) {
      if (!mounted || !v) return;
      setState(() {
        _isAdmin = true;
        _future = VideosService.instance.listAll();
      });
    });
  }

  void _reload() {
    setState(() {
      _future = _isAdmin
          ? VideosService.instance.listAll()
          : VideosService.instance.listPublished();
    });
  }

  Future<void> _open(TrainingVideo v) async {
    final uri = Uri.tryParse(v.videoUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الفيديو')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فيديوهات تعليمية'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final added = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => const _AddVideoSheet(),
                );
                if (added == true) _reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة فيديو'),
            )
          : null,
      body: FutureBuilder<List<TrainingVideo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _msg(Icons.wifi_off_rounded, 'تعذّر تحميل الفيديوهات',
                'تأكّد من الاتصال بالإنترنت');
          }
          final vids = snap.data ?? const <TrainingVideo>[];
          if (vids.isEmpty) {
            return _msg(Icons.ondemand_video_outlined, 'لا توجد فيديوهات بعد',
                'سيُضاف محتوى تعليمي أسبوعياً');
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              itemCount: vids.length,
              itemBuilder: (_, i) => _VideoCard(
                video: vids[i],
                isAdmin: _isAdmin,
                onOpen: () => _open(vids[i]),
                onChanged: _reload,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _msg(IconData icon, String title, String body) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}

class _VideoCard extends StatefulWidget {
  final TrainingVideo video;
  final bool isAdmin;
  final VoidCallback onOpen;
  final VoidCallback onChanged;
  const _VideoCard({
    required this.video,
    required this.isAdmin,
    required this.onOpen,
    required this.onChanged,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  /// المشغّل لا يُنشأ إلا عند الضغط على زر التشغيل — فلا يُستهلك أي
  /// بايت من داتا المستخدم أثناء التمرير على القائمة.
  YoutubePlayerController? _ctrl;

  /// صار التشغيل داخلياً (يوتيوب أو embed أو ملف).
  bool _playing = false;

  TrainingVideo get video => widget.video;
  bool get isAdmin => widget.isAdmin;

  void _startInline() {
    final src = video.source;
    if (src.kind != VideoKind.youtube) {
      setState(() => _playing = true);
      return;
    }
    setState(() {
      _playing = true;
      _ctrl = YoutubePlayerController.fromVideoId(
        videoId: video.ytId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          // التطبيق مقفول على الوضع العمودي، فزر ملء الشاشة لا ينفع
          // داخله — من يريد ملء الشاشة يفتحه في يوتيوب من الزر أسفل
          // البطاقة.
          showFullscreenButton: false,
          playsInline: true,
          enableCaption: false,
          strictRelatedVideos: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── المشغّل المدمج بعد الضغط، أو الصورة المصغّرة قبله ──────────
        if (_playing)
          AspectRatio(
            aspectRatio: video.source.provider == 'tiktok' ||
                    video.source.provider == 'instagram'
                ? 9 / 14 // المقاطع العمودية تحتاج إطاراً طويلاً
                : 16 / 9,
            child: _ctrl != null
                ? YoutubePlayer(controller: _ctrl!, aspectRatio: 16 / 9)
                : (video.source.kind == VideoKind.file
                    ? FileVideoPlayer(url: video.source.playUrl)
                    : EmbedVideoPlayer(embedUrl: video.source.playUrl)),
          )
        else
        InkWell(
          onTap: video.canPlayInline ? _startInline : widget.onOpen,
          child: Stack(alignment: Alignment.center, children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: video.thumb.isEmpty
                  ? Container(color: theme.dividerColor.withOpacity(0.2))
                  : CachedNetworkImage(
                      imageUrl: video.thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: theme.dividerColor.withOpacity(0.15)),
                      errorWidget: (_, __, ___) => Container(
                          color: theme.dividerColor.withOpacity(0.15),
                          child: const Icon(Icons.ondemand_video_outlined)),
                    ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 34),
            ),
            if (video.isNew)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('جديد هذا الأسبوع',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (video.durationAr.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(video.durationAr,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.titleAr,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            if (video.descriptionAr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(video.descriptionAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            // ── بديل: الفتح في تطبيق يوتيوب ───────────────────────────
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: widget.onOpen,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: Text(
                    video.source.label.isEmpty
                        ? 'فتح الفيديو'
                        : 'فتح في ${video.source.label}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            if (isAdmin) ...[
              const Divider(height: 18),
              Row(children: [
                Icon(
                    video.isPublished
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 17,
                    color: video.isPublished
                        ? AppColors.successGreen
                        : AppColors.warningAmber),
                const SizedBox(width: 6),
                Text(video.isPublished ? 'منشور' : 'مخفي',
                    style: TextStyle(
                        fontSize: 12,
                        color: video.isPublished
                            ? AppColors.successGreen
                            : AppColors.warningAmber)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await VideosService.instance
                        .setPublished(video.id, !video.isPublished);
                    widget.onChanged();
                  },
                  child: Text(video.isPublished ? 'إخفاء' : 'نشر'),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف الفيديو'),
                        content: Text('حذف «${video.titleAr}»؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('إلغاء')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('حذف')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await VideosService.instance.remove(video.id);
                      widget.onChanged();
                    }
                  },
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.errorRed),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _AddVideoSheet extends StatefulWidget {
  const _AddVideoSheet();

  @override
  State<_AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<_AddVideoSheet> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _desc = TextEditingController();
  bool _publish = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final url = _url.text.trim();
    if (title.isEmpty || url.isEmpty) {
      setState(() => _error = 'العنوان والرابط مطلوبان');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _error = 'الرابط يجب أن يبدأ بـ https');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await VideosService.instance.create(
        titleAr: title,
        videoUrl: url,
        descriptionAr: _desc.text.trim(),
        publish: _publish,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'تعذّر الحفظ: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('إضافة فيديو تعليمي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
              labelText: 'العنوان *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'رابط الفيديو *',
            hintText: 'https://youtu.be/...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'الوصف', border: OutlineInputBorder()),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _publish,
          onChanged: (v) => setState(() => _publish = v),
          title: const Text('نشره فوراً'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                style: const TextStyle(color: AppColors.errorRed, fontSize: 12.5)),
          ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ'),
          ),
        ),
      ]),
    );
  }
}
