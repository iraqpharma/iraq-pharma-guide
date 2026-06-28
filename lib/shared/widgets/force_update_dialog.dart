import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

// Replace with your actual Play Store URL when published
const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.iraqpharma.guide';

/// Non-dismissible force-update dialog.
/// Call [ForceUpdateDialog.show] from your splash/init flow.
class ForceUpdateDialog {
  ForceUpdateDialog._();

  static Future<void> show(BuildContext context,
      {required String currentVersion, required String minVersion}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForceUpdateDialogWidget(
        currentVersion: currentVersion,
        minVersion: minVersion,
      ),
    );
  }
}

class _ForceUpdateDialogWidget extends StatefulWidget {
  final String currentVersion;
  final String minVersion;
  const _ForceUpdateDialogWidget(
      {required this.currentVersion, required this.minVersion});

  @override
  State<_ForceUpdateDialogWidget> createState() =>
      _ForceUpdateDialogWidgetState();
}

class _ForceUpdateDialogWidgetState extends State<_ForceUpdateDialogWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _openStore() async {
    setState(() => _launching = true);
    final uri = Uri.parse(_playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevents back-button dismiss
      child: ScaleTransition(
        scale: _scale,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Gradient header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkNavy, AppColors.primary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_alt_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 12),
                Text('تحديث مطلوب',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(children: [
                Text(
                  'يتوفر تحديث جديد!\nيرجى تحديث التطبيق للمتابعة.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15, height: 1.7, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),

                // Version badges
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _VersionBadge(label: 'الإصدار الحالي', version: widget.currentVersion, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _VersionBadge(label: 'الإصدار المطلوب', version: widget.minVersion, color: AppColors.primary),
                ]),
                const SizedBox(height: 22),

                // Update button
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _launching ? null : _openStore,
                    icon: _launching
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _launching ? 'جارٍ الفتح...' : 'تحديث الآن',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'لا يمكن الاستمرار بدون التحديث',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label, version;
  final Color color;
  const _VersionBadge(
      {required this.label, required this.version, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label,
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 10, color: AppColors.textSecondary)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('v$version',
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13, fontWeight: FontWeight.bold, color: color)),
    ),
  ]);
}
