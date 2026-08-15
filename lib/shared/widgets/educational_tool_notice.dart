import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';

/// One-time-per-tool acknowledgement shown before a calculator opens.
///
/// The calculators are teaching aids built on published formulas, not a
/// prescribing tool. Making the user confirm that in their own words is what
/// keeps the feature honest — and it is the mitigation App Review looks for
/// on guideline 1.4.2.
class EducationalToolNotice {
  EducationalToolNotice._();

  static String _key(String toolId) => 'edu_notice_hidden_$toolId';

  /// Returns true when the user acknowledged (or had already hidden it) and
  /// the caller should proceed to open the tool.
  static Future<bool> ensureAcknowledged(
    BuildContext context, {
    required String toolId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(toolId)) == true) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NoticeDialog(toolId: toolId),
    );
    return accepted ?? false;
  }
}

class _NoticeDialog extends StatefulWidget {
  final String toolId;
  const _NoticeDialog({required this.toolId});

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.s.eduNoticeTitle,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.s.eduNoticeBody,
            style: GoogleFonts.cairo(
                fontSize: 13.5, height: 1.7, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _dontShowAgain,
                      activeColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) =>
                          setState(() => _dontShowAgain = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.s.eduNoticeDontShow,
                      style: GoogleFonts.cairo(
                          fontSize: 12.5, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.s.cancel,
              style: GoogleFonts.cairo(color: cs.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(
                  EducationalToolNotice._key(widget.toolId), true);
            }
            if (context.mounted) Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(context.s.eduNoticeAgree,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
