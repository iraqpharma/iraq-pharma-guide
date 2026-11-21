import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';

/// مشغّل صفحة embed للمنصّات التي تعطي رابطاً عاماً — Vimeo وفيسبوك
/// وتيك توك وDailymotion وإنستغرام. لا يُنشأ هذا الودجت إلا بعد ضغط
/// المستخدم على زر التشغيل، فلا يُفتح أي اتصال قبل ذلك.
class EmbedVideoPlayer extends StatefulWidget {
  final String embedUrl;
  const EmbedVideoPlayer({super.key, required this.embedUrl});

  @override
  State<EmbedVideoPlayer> createState() => _EmbedVideoPlayerState();
}

class _EmbedVideoPlayerState extends State<EmbedVideoPlayer> {
  late final WebViewController _wc;
  bool _loading = true;
  bool _failed  = false;

  @override
  void initState() {
    super.initState();
    _wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _loading = false; _failed = true; });
        },
        // المشغّل المدمج قد يحاول نقل المستخدم لصفحة المنصّة — نمنع ذلك
        // ونُبقيه داخل الإطار، ومن أراد الخروج يستعمل زر «فتح في المنصّة».
        onNavigationRequest: (req) =>
            req.url.startsWith(widget.embedUrl.split('?').first)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent,
      ))
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black, child: WebViewWidget(controller: _wc)),
        if (_loading)
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.white70),
          ),
        if (_failed)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'هذه المنصّة لا تسمح بالتشغيل داخل التطبيق — افتح الفيديو من الزر أدناه',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

/// مشغّل ملف فيديو مباشر (mp4 / m3u8) — يُستعمل للمقاطع القصيرة
/// المرفوعة على سوبابيس. ضع المقاطع الطويلة على يوتيوب، لأن داتا
/// الملف المباشر تُحسب من حصة الاستضافة.
class FileVideoPlayer extends StatefulWidget {
  final String url;
  const FileVideoPlayer({super.key, required this.url});

  @override
  State<FileVideoPlayer> createState() => _FileVideoPlayerState();
}

class _FileVideoPlayerState extends State<FileVideoPlayer> {
  VideoPlayerController? _vc;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vc = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      c.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _vc;
    if (_failed) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text('تعذّر تشغيل الملف — تحقّق من الرابط أو الاتصال',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: Colors.white70),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          // زر تشغيل/إيقاف يظهر عند اللمس
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(
                () => c.value.isPlaying ? c.pause() : c.play()),
            child: AnimatedOpacity(
              opacity: c.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
