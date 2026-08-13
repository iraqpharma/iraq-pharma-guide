import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/avatar_service.dart';
import '../../services/profile_completion_service.dart';

/// One-time, fully optional prompt shown right after login/signup asking
/// for governorate, birth date and a profile photo. Skippable, and never
/// shown again once the user saves or skips (see ProfileCompletionService).
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});
  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  static const _governorates = [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'كركوك',
    'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 'كربلاء', 'النجف',
    'الديوانية', 'ميسان', 'واسط', 'ذي قار', 'المثنى', 'دهوك',
  ];

  final _dateCtrl = TextEditingController();
  String?   _selectedGovernorate;
  DateTime? _birthDate;
  String?   _avatarUrl;
  bool _uploadingAvatar = false;
  bool _saving = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
        _dateCtrl.text =
            '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => _uploadingAvatar = true);
    final url = await AvatarService.instance.pickAndUpload();
    if (!mounted) return;
    setState(() {
      _uploadingAvatar = false;
      if (url != null) _avatarUrl = url;
    });
  }

  Future<void> _finish({required bool saveData}) async {
    if (_saving) return;
    setState(() => _saving = true);

    if (saveData && (_selectedGovernorate != null || _birthDate != null)) {
      final birthStr = _birthDate == null ? null :
          '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
      await AuthService.instance.updateProfile({
        if (_selectedGovernorate != null) 'address':    _selectedGovernorate,
        if (birthStr != null)             'birth_date': birthStr,
      });
    }

    await ProfileCompletionService.instance.markAsked();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s  = context.s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.completeProfileTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(s.completeProfileSub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13, color: cs.onSurfaceVariant, height: 1.6)),
              const SizedBox(height: 32),

              // ── Avatar picker ────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.08),
                          image: _avatarUrl != null
                              ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _uploadingAvatar
                            ? const Center(child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.primary))
                            : (_avatarUrl == null
                                ? Icon(Icons.person_outline, size: 40, color: AppColors.primary.withOpacity(0.6))
                                : null),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: cs.surface, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(s.addPhotoLabel,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: AppColors.primary)),
              ),
              const SizedBox(height: 28),

              // ── Governorate ──────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedGovernorate,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.governorate,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  filled: true, fillColor: cs.surfaceVariant,
                  labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: cs.onSurfaceVariant),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: cs.onSurface),
                items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _selectedGovernorate = v),
              ),
              const SizedBox(height: 14),

              // ── Birth date ───────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: s.birthDateOptional,
                      hintText: s.birthDateHint,
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                      filled: true, fillColor: cs.surfaceVariant,
                      labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: cs.onSurfaceVariant),
                      hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save ─────────────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _finish(saveData: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(s.saveChanges,
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Skip ─────────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _saving ? null : () => _finish(saveData: false),
                  child: Text(s.skipForNow,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
