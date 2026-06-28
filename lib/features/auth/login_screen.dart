import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  LOGIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool    _loading    = false;
  bool    _obscure    = true;
  bool    _rememberMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await SessionService.instance.getSavedEmail();
    if (saved != null && mounted) {
      _emailCtrl.text = saved;
      setState(() => _rememberMe = true);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.signIn(
      emailOrUsername: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() { _loading = false; _error = result.error; });
      return;
    }

    // Save session preference
    await SessionService.instance.onLoginSuccess(
      rememberMe: _rememberMe,
      email:      _emailCtrl.text,
    );

    setState(() => _loading = false);
    _showLoginSuccess();
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess) {
      _showLoginSuccess();
    } else {
      setState(() => _error = result.error);
    }
  }

  void _showLoginSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoginSuccessDialog(),
    ).then((_) { if (mounted) context.go('/notification-permission'); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const _AppLogo(),
                const SizedBox(height: 36),

                // Email or username
                _AuthField(
                  label: 'البريد الإلكتروني أو اسم المستخدم',
                  ctrl:  _emailCtrl,
                  icon:  Icons.person_outline,
                  maxLen: 254,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني أو اسم المستخدم';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                _PasswordField(
                  ctrl: _passCtrl, obscure: _obscure,
                  onToggle: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: 4),

                // Remember me + forgot password row
                Row(
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Text('تذكرني',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                      child: Text('نسيت كلمة المرور؟',
                          style: GoogleFonts.ibmPlexSansArabic(
                              color: AppColors.primary, fontSize: 13)),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(_error!),
                ],
                const SizedBox(height: 20),

                _PrimaryButton(
                  label: 'تسجيل الدخول',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),

                _Divider('أو'),
                const SizedBox(height: 16),

                _GoogleButton(loading: _loading, onPressed: _googleSignIn),
                const SizedBox(height: 32),

                // Sign up — bigger text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ليس لديك حساب؟  ',
                        style: GoogleFonts.ibmPlexSansArabic(
                            color: AppColors.textSecondary, fontSize: 16)),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text('سجّل الآن',
                          style: GoogleFonts.ibmPlexSansArabic(
                              color: AppColors.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Login success dialog (auto-dismiss 2s) ────────────────────────────────────
class _LoginSuccessDialog extends StatefulWidget {
  const _LoginSuccessDialog();
  @override
  State<_LoginSuccessDialog> createState() => _LoginSuccessDialogState();
}

class _LoginSuccessDialogState extends State<_LoginSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text('أهلاً بعودتك!',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('تم تسجيل الدخول بنجاح.',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SIGN UP SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  String?        _selectedRole;
  bool           _loading            = false;
  bool           _obscure1           = true;
  bool           _obscure2           = true;
  String?        _error;
  bool           _userEditedUsername = false;
  UsernameStatus _usernameStatus     = UsernameStatus.idle;
  Timer?         _debounce;

  static const _roles = [
    'مدير صيدلية', 'صيدلاني متدرب', 'معاون صيدلي',
  ];

  static const _governorates = [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'كركوك',
    'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 'كربلاء', 'النجف',
    'الديوانية', 'ميسان', 'واسط', 'ذي قار', 'المثنى', 'دهوك',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
    _usernameCtrl.addListener(_onUsernameEdited);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.removeListener(_onNameChanged);
    _usernameCtrl.removeListener(_onUsernameEdited);
    for (final c in [_nameCtrl, _usernameCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Username auto-fill ────────────────────────────────────────────────────
  void _onNameChanged() {
    if (_userEditedUsername) return;
    final generated = AuthService.instance.generateUsernameFromName(_nameCtrl.text);
    if (generated.length >= 3) {
      _setUsername(generated);
      _scheduleCheck(generated, autoFix: true);
    }
  }

  void _onUsernameEdited() {
    _userEditedUsername = true;
    _scheduleCheck(_usernameCtrl.text, autoFix: false);
  }

  void _setUsername(String value) {
    _usernameCtrl.removeListener(_onUsernameEdited);
    _usernameCtrl.text = value;
    _usernameCtrl.addListener(_onUsernameEdited);
  }

  void _scheduleCheck(String value, {required bool autoFix}) {
    _debounce?.cancel();
    final clean = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.length < 4) {
      setState(() => _usernameStatus = UsernameStatus.tooShort);
      return;
    }
    setState(() => _usernameStatus = UsernameStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final status = await AuthService.instance.checkUsername(clean);
      if (!mounted) return;
      if (status == UsernameStatus.taken && autoFix) {
        // Auto-find available alternative and fill it
        final available = await AuthService.instance.findAvailableUsername(clean);
        if (!mounted || _userEditedUsername) return;
        _setUsername(available);
        setState(() => _usernameStatus = UsernameStatus.available);
      } else {
        setState(() => _usernameStatus = status);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) { setState(() => _error = 'يرجى اختيار المهنة'); return; }
    if (_usernameStatus == UsernameStatus.taken) { setState(() => _error = 'اسم المستخدم مستخدم بالفعل'); return; }
    if (_usernameStatus == UsernameStatus.checking) { setState(() => _error = 'جارٍ التحقق من اسم المستخدم…'); return; }

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.signUp(
      email:     _emailCtrl.text,
      password:  _passCtrl.text,
      fullName:  _nameCtrl.text,
      username:  _usernameCtrl.text,
      role:      _selectedRole!,
      birthDate: '',
      address:   '',
    );

    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/register-success');
    } else {
      setState(() { _loading = false; _error = result.error; });
    }
  }

  // ── Username indicator ────────────────────────────────────────────────────
  Widget _indicator() {
    switch (_usernameStatus) {
      case UsernameStatus.checking:
        return const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
      case UsernameStatus.available:
        return const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20);
      case UsernameStatus.taken:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
      case UsernameStatus.tooShort:
        return Icon(Icons.info_outline, color: Colors.orange.shade400, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }

  Color _borderColor() {
    switch (_usernameStatus) {
      case UsernameStatus.available: return const Color(0xFF4CAF50);
      case UsernameStatus.taken:     return Colors.red;
      case UsernameStatus.tooShort:  return Colors.orange;
      default: return const Color(0xFFE0E0E0);
    }
  }

  (String, Color)? _statusLabel() {
    switch (_usernameStatus) {
      case UsernameStatus.available: return ('متاح ✓', const Color(0xFF4CAF50));
      case UsernameStatus.taken:     return ('مستخدم بالفعل', Colors.red);
      case UsernameStatus.tooShort:  return ('4 أحرف على الأقل', Colors.orange);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label   = _statusLabel();
    final borderC = _borderColor();
    final focusC  = _usernameStatus == UsernameStatus.available
        ? const Color(0xFF4CAF50) : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AppLogo(),
                const SizedBox(height: 14),
                Text('إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 20),

                // Full name
                _AuthField(
                  label: 'الاسم الكامل',
                  ctrl:  _nameCtrl, icon: Icons.person_outline, maxLen: 80,
                  hint: 'بالعربي أو الإنجليزي',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل اسمك الكامل';
                    if (v.trim().split(' ').where((s) => s.isNotEmpty).length < 2)
                      return 'أدخل الاسم الأول والأخير على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Username with availability
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _usernameCtrl,
                      textAlign: TextAlign.right,
                      maxLength: 30,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        counterText: '',
                        hintText: 'يُملأ تلقائياً من الاسم',
                        prefixIcon: const Icon(Icons.alternate_email_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: Padding(
                            padding: const EdgeInsets.all(12), child: _indicator()),
                        filled: true, fillColor: Colors.white,
                        labelStyle: GoogleFonts.ibmPlexSansArabic(
                            color: AppColors.textSecondary, fontSize: 14),
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                            color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusC, width: 1.5)),
                        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل اسم المستخدم';
                        if (v.trim().length < 4) return '4 أحرف على الأقل';
                        if (_usernameStatus == UsernameStatus.taken) return 'اسم المستخدم مستخدم';
                        return null;
                      },
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(label.$1,
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: label.$2)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                _AuthField(
                  label: 'البريد الإلكتروني', ctrl: _emailCtrl,
                  icon: Icons.email_outlined, maxLen: 254,
                  keyboard: TextInputType.emailAddress, validator: _emailValidator,
                ),
                const SizedBox(height: 12),

                _PasswordField(
                  ctrl: _passCtrl, obscure: _obscure1,
                  onToggle: () => setState(() => _obscure1 = !_obscure1),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                    if (v.length < 6) return '6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _PasswordField(
                  ctrl: _confirmCtrl, obscure: _obscure2,
                  label: 'تأكيد كلمة المرور',
                  onToggle: () => setState(() => _obscure2 = !_obscure2),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أعد إدخال كلمة المرور';
                    if (v != _passCtrl.text) return 'كلمتا المرور غير متطابقتين';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: _fieldDeco(label: 'المهنة', icon: Icons.work_outline),
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: AppColors.textPrimary),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? 'اختر مهنتك' : null,
                ),

                if (_error != null) ...[const SizedBox(height: 10), _ErrorBanner(_error!)],
                const SizedBox(height: 20),

                _PrimaryButton(label: 'إنشاء الحساب', loading: _loading, onPressed: _submit),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لديك حساب؟ ',
                        style: GoogleFonts.ibmPlexSansArabic(
                            color: AppColors.textSecondary, fontSize: 15)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('سجّل الدخول',
                          style: GoogleFonts.ibmPlexSansArabic(
                              color: AppColors.primary, fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS & HELPERS
// ══════════════════════════════════════════════════════════════════════════════

String? _emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
  final t = v.trim();
  if (!t.contains('@') || !t.contains('.')) return 'بريد إلكتروني غير صحيح';
  if (t.length > 254) return 'البريد الإلكتروني طويل جداً';
  return null;
}

InputDecoration _fieldDeco({required String label, required IconData icon, String? hint}) =>
    InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true, fillColor: Colors.white,
      labelStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
      hintStyle:  GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );

class _AppLogo extends StatelessWidget {
  const _AppLogo();
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.primary],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 36),
    ),
    const SizedBox(height: 12),
    Text('Iraq Pharma Guide',
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    Text('دليل الصيدلة العراقي',
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
  ]);
}

class _AuthField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLen;
  final String? hint;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.label, required this.ctrl, required this.icon,
    this.maxLen = 200, this.hint, this.keyboard, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, textAlign: TextAlign.right, keyboardType: keyboard,
    maxLength: maxLen, inputFormatters: [LengthLimitingTextInputFormatter(maxLen)],
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _fieldDeco(label: label, icon: icon, hint: hint).copyWith(counterText: ''),
    validator: validator,
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool obscure;
  final String label;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.ctrl, required this.obscure,
    this.label = 'كلمة المرور', required this.onToggle, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, obscureText: obscure,
    textAlign: TextAlign.left, textDirection: TextDirection.ltr,
    maxLength: 128, inputFormatters: [LengthLimitingTextInputFormatter(128)],
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _fieldDeco(label: label, icon: Icons.lock_outline).copyWith(
      counterText: '',
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary),
        onPressed: onToggle,
      ),
    ),
    validator: validator ?? (v) {
      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
      if (v.length < 6) return '6 أحرف على الأقل';
      return null;
    },
  );
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFFDDDDDD)),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleGPainter())),
      const SizedBox(width: 10),
      Text('المتابعة عبر Google',
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    ]),
  );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * 1.5708 - 1.5708, 1.5708, false,
        Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = 3,
      );
    }
  }
  @override bool shouldRepaint(_) => false;
}


class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade700, fontSize: 13))),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider(this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider()),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 13))),
    const Expanded(child: Divider()),
  ]);
}
