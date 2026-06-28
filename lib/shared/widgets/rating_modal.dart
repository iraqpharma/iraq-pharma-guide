import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../services/rating_service.dart';

const _kStoreThreshold = 4.0;

class RatingModal {
  RatingModal._();

  /// Shows the rating modal. Call after checking [RatingService.shouldShow].
  static Future<void> show(
    BuildContext context, {
    required RatingConfig config,
  }) async {
    await RatingService.instance.markShown();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RatingModalWidget(config: config),
    );
  }
}

class _RatingModalWidget extends StatefulWidget {
  final RatingConfig config;
  const _RatingModalWidget({required this.config});

  @override
  State<_RatingModalWidget> createState() => _RatingModalWidgetState();
}

class _RatingModalWidgetState extends State<_RatingModalWidget> {
  double _rating    = 0;
  bool   _submitted = false;
  bool   _loading   = false;

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _loading = true);

    bool redirected = false;
    if (_rating >= _kStoreThreshold) {
      final uri = Uri.parse(widget.config.ratingLink);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          redirected = true;
        }
      } catch (_) {}
    }

    await RatingService.instance.submitRating(
      rating: _rating,
      redirectedToStore: redirected,
    );

    if (mounted) {
      setState(() { _submitted = true; _loading = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _submitted ? _buildThanks() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 38),
        ),
        const SizedBox(height: 16),

        // Title
        Text('قيّم التطبيق',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Message from Supabase
        Text(widget.config.messageText,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14, color: AppColors.textSecondary, height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Star rating bar
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 42,
          unratedColor: Colors.grey.shade200,
          itemBuilder: (_, __) => const Icon(
            Icons.star_rounded,
            color: Color(0xFFF59E0B),
          ),
          onRatingUpdate: (r) => setState(() => _rating = r),
        ),
        const SizedBox(height: 8),

        // Hint under stars
        AnimatedOpacity(
          opacity: _rating > 0 ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _rating >= _kStoreThreshold
                ? '🎉 شكراً! سنحولك للمتجر لإتمام التقييم'
                : 'نأسف لذلك. سنعمل على التحسين',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              color: _rating >= _kStoreThreshold
                  ? AppColors.primary
                  : Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Buttons row
        Row(
          children: [
            // Later
            Expanded(
              child: TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: Text('لاحقاً',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: AppColors.textSecondary, fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Submit
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: (_rating == 0 || _loading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text('إرسال التقييم',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14, fontWeight: FontWeight.bold,
                          )),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThanks() {
    return Column(
      key: const ValueKey('thanks'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.primary, size: 64),
        const SizedBox(height: 16),
        Text('شكراً لك!',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _rating >= _kStoreThreshold
              ? 'تقييمك يعني لنا الكثير ❤️'
              : 'سنعمل على تحسين التطبيق',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14, color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
