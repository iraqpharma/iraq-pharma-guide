import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.iraqpharma.guide';
const _appStoreUrl =
    'https://apps.apple.com/app/id0000000000'; // استبدل بالرابط الفعلي

class SoftUpdateDialog {
  SoftUpdateDialog._();

  static Future<void> show(
    BuildContext context, {
    required String updateMessage,
    required String latestVersion,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SoftUpdateWidget(
        updateMessage: updateMessage,
        latestVersion: latestVersion,
      ),
    );
  }
}

class _SoftUpdateWidget extends StatelessWidget {
  final String updateMessage;
  final String latestVersion;

  const _SoftUpdateWidget({
    required this.updateMessage,
    required this.latestVersion,
  });

  Future<void> _openStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update_rounded,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),

              // عنوان
              Text(
                '🎉 تحديث جديد متاح!',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                'الإصدار $latestVersion',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              // رسالة التحديث (يمكنك تحريرها من Supabase)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  updateMessage,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 20),

              // زر التحديث
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openStore,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    'حدّث التطبيق الآن',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

            ],
          ),
        ),
      ),
    ));
  }
}
