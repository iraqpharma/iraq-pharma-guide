import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Profile form
  final _profileFormKey  = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _dateCtrl        = TextEditingController();

  String?        _selectedRole;
  String?        _selectedGovernorate;
  DateTime?      _birthDate;
  UsernameStatus _usernameStatus = UsernameStatus.idle;
  Timer?         _debounce;
  bool           _profileLoading = true;
  bool           _saving         = false;
  String?        _profileError;

  // Password form
  final _passFormKey  = GlobalKey<FormState>();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _obscureCurr = true;
  bool _obscureNew  = true;
  bool _obscureConf = true;
  bool _passLoading = false;
  String? _passError;
  String? _passSuccess;

  static const _roles = ['مدير صيدلية', 'صيدلاني متدرب', 'معاون صيدلي'];
  static const _governorates = [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'كركوك',
    'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 'كربلاء', 'النجف',
    'الديوانية', 'ميسان', 'واسط', 'ذي قار', 'المثنى', 'دهوك',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _usernameCtrl.addListener(_onUsernameEdited);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.removeListener(_onUsernameEdited);
    for (final c in [_nameCtrl, _usernameCtrl, _dateCtrl,
                     _currPassCtrl, _newPassCtrl, _confPassCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _profileLoading = false;
      if (data != null) {
        _nameCtrl.text     = data['full_name'] as String? ?? '';
        _usernameCtrl.text = data['username']  as String? ?? '';
        _selectedRole      = _roles.contains(data['role']) ? data['role'] as String? : null;
        _selectedGovernorate = _governorates.contains(data['address']) ? data['address'] as String? : null;
        final bd = data['birth_date'] as String?;
        if (bd != null && bd.isNotEmpty) {
          _dateCtrl.text = bd.replaceAll('-', '/');
          try {
            final parts = bd.split('-');
            _birthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } catch (_) {}
        }
      }
    });
  }

  void _onUsernameEdited() {
    _scheduleCheck(_usernameCtrl.text);
  }

  void _scheduleCheck(String value) {
    _debounce?.cancel();
    final clean = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.length < 4) { setState(() => _usernameStatus = UsernameStatus.tooShort); return; }
    setState(() => _usernameStatus = UsernameStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final status = await AuthService.instance.checkUsername(clean);
      if (!mounted) return;
      // If it's the same as current, treat as available
      setState(() => _usernameStatus = status);
    });
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

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_selectedRole == null) { setState(() => _profileError = 'اختر المهنة'); return; }
    setState(() { _saving = true; _profileError = null; });

    final birthStr = _birthDate == null ? '' :
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    final result = await AuthService.instance.updateProfile({
      'full_name':  _nameCtrl.text.trim(),
      'username':   _usernameCtrl.text.trim().toLowerCase(),
      'role':       _selectedRole,
      'address':    _selectedGovernorate ?? '',
      'birth_date': birthStr.isEmpty ? null : birthStr,
    });

    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم حفظ البيانات بنجاح',
            style: GoogleFonts.ibmPlexSansArabic()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      setState(() => _profileError = result.error);
    }
  }

  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() { _passLoading = true; _passError = null; _passSuccess = null; });

    final result = await AuthService.instance.changePassword(
      currentPassword: _currPassCtrl.text,
      newPassword:     _newPassCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _passLoading = false;
      if (result.isSuccess) {
        _passSuccess = 'تم تغيير كلمة المرور بنجاح';
        _currPassCtrl.clear();
        _newPassCtrl.clear();
        _confPassCtrl.clear();
      } else {
        _passError = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('تعديل البيانات الشخصية',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: _profileLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // ── Change Password ──────────────────────────────────────
                  _sectionLabel('تغيير كلمة المرور', Icons.lock_outline),
                  const SizedBox(height: 10),
                  _card(
                    child: Form(
                      key: _passFormKey,
                      child: Column(children: [
                        _passField(ctrl: _currPassCtrl, label: 'كلمة المرور الحالية',
                            obscure: _obscureCurr, onToggle: () => setState(() => _obscureCurr = !_obscureCurr),
                            validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور الحالية' : null),
                        const SizedBox(height: 12),
                        _passField(ctrl: _newPassCtrl, label: 'كلمة المرور الجديدة',
                            obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'أدخل كلمة المرور الجديدة';
                              if (v.length < 6) return '6 أحرف على الأقل';
                              return null;
                            }),
                        const SizedBox(height: 12),
                        _passField(ctrl: _confPassCtrl, label: 'تأكيد كلمة المرور الجديدة',
                            obscure: _obscureConf, onToggle: () => setState(() => _obscureConf = !_obscureConf),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'أعد إدخال كلمة المرور';
                              if (v != _newPassCtrl.text) return 'كلمتا المرور غير متطابقتين';
                              return null;
                            }),
                        if (_passError != null) ...[
                          const SizedBox(height: 10),
                          _errorBanner(_passError!),
                        ],
                        if (_passSuccess != null) ...[
                          const SizedBox(height: 10),
                          _successBanner(_passSuccess!),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                            onPressed: _passLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _passLoading
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('تغيير كلمة المرور',
                                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Profile Data ─────────────────────────────────────────
                  _sectionLabel('البيانات الشخصية', Icons.person_outline),
                  const SizedBox(height: 10),
                  _card(
                    child: Form(
                      key: _profileFormKey,
                      child: Column(children: [
                        // Full name
                        _textField(ctrl: _nameCtrl, label: 'الاسم الكامل', icon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'أدخل اسمك الكامل';
                              if (v.trim().split(' ').where((s) => s.isNotEmpty).length < 2)
                                return 'أدخل الاسم الأول والأخير';
                              return null;
                            }),
                        const SizedBox(height: 12),

                        // Username
                        _usernameField(),
                        const SizedBox(height: 12),

                        // Role
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: _deco(label: 'المهنة', icon: Icons.work_outline),
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: AppColors.textPrimary),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setState(() => _selectedRole = v),
                          validator: (v) => v == null ? 'اختر مهنتك' : null,
                        ),
                        const SizedBox(height: 12),

                        // Governorate
                        DropdownButtonFormField<String>(
                          value: _selectedGovernorate,
                          isExpanded: true,
                          decoration: _deco(label: 'المحافظة', icon: Icons.location_on_outlined),
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: AppColors.textPrimary),
                          items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGovernorate = v),
                        ),
                        const SizedBox(height: 12),

                        // Birth date
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _dateCtrl,
                              readOnly: true,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                              decoration: _deco(label: 'تاريخ الميلاد (اختياري)', icon: Icons.calendar_today_outlined,
                                  hint: 'مثال: 1995/06/15').copyWith(
                                suffixIcon: _birthDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                                        onPressed: () => setState(() { _birthDate = null; _dateCtrl.clear(); }),
                                      )
                                    : const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 18),
                              ),
                            ),
                          ),
                        ),

                        if (_profileError != null) ...[
                          const SizedBox(height: 10),
                          _errorBanner(_profileError!),
                        ],
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('حفظ التغييرات',
                                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Username field with live check ─────────────────────────────────────────
  Widget _usernameField() {
    Widget indicator() {
      switch (_usernameStatus) {
        case UsernameStatus.checking:
          return const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
        case UsernameStatus.available:
          return const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20);
        case UsernameStatus.taken:
          return const Icon(Icons.cancel, color: Colors.red, size: 20);
        default:
          return const SizedBox.shrink();
      }
    }

    return TextFormField(
      controller: _usernameCtrl,
      textAlign: TextAlign.right,
      maxLength: 30,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
        LengthLimitingTextInputFormatter(30),
      ],
      style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
      decoration: _deco(label: 'اسم المستخدم', icon: Icons.alternate_email_rounded).copyWith(
        counterText: '',
        suffixIcon: Padding(padding: const EdgeInsets.all(12), child: indicator()),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'أدخل اسم المستخدم';
        if (v.trim().length < 4) return '4 أحرف على الأقل';
        if (_usernameStatus == UsernameStatus.taken) return 'اسم المستخدم مستخدم';
        return null;
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    ],
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    textAlign: TextAlign.right,
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _deco(label: label, icon: icon),
    validator: validator,
  );

  Widget _passField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    obscureText: obscure,
    textAlign: TextAlign.left,
    textDirection: TextDirection.ltr,
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _deco(label: label, icon: Icons.lock_outline).copyWith(
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary),
        onPressed: onToggle,
      ),
    ),
    validator: validator,
  );

  InputDecoration _deco({required String label, required IconData icon, String? hint}) =>
      InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true, fillColor: const Color(0xFFF8F9FA),
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );

  Widget _errorBanner(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade700, fontSize: 13))),
    ]),
  );

  Widget _successBanner(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: GoogleFonts.ibmPlexSansArabic(color: Colors.green.shade700, fontSize: 13))),
    ]),
  );
}
