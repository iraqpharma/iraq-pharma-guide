import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../core/l10n/app_strings.dart';

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
  bool    _fbLoading  = false;
  bool    _obscure    = true;
  bool    _rememberMe = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn && _fbLoading) {
        setState(() => _fbLoading = false);
        _showLoginSuccess();
      }
    });
  }

  Future<void> _loadSavedEmail() async {
    final saved = await SessionService.instance.getSavedEmail();
    if (saved != null && mounted) {
      _emailCtrl.text = saved;
      setState(() => _rememberMe = true);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _facebookSignIn() async {
    setState(() { _fbLoading = true; _error = null; });
    try {
      await AuthService.instance.signInWithFacebook();
      // Result handled by _authSub listener; if browser closed without login, reset after 2 min
      Future.delayed(const Duration(minutes: 2), () {
        if (mounted && _fbLoading) setState(() => _fbLoading = false);
      });
    } catch (e) {
      if (mounted) setState(() { _fbLoading = false; _error = 'فشل تسجيل الدخول بـ Facebook'; });
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Teal header banner ──────────────────────────────────────────────
          _LoginHeader(),

          // ── Scrollable form ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.s.loginTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    const SizedBox(height: 6),
                    Text(context.s.loginSubHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 24),

                    // Universal identifier field
                    _UniversalLoginField(ctrl: _emailCtrl),
                    const SizedBox(height: 14),

                    // Password
                    _PasswordField(
                      ctrl: _passCtrl, obscure: _obscure,
                      onToggle: () => setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 4),

                    // Remember me + forgot password
                    Row(children: [
                      SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          side: BorderSide(color: cs.onSurfaceVariant.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Text(context.s.rememberMe,
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                        child: Text(context.s.forgotPassword,
                            style: GoogleFonts.ibmPlexSansArabic(
                                color: AppColors.primary, fontSize: 13)),
                      ),
                    ]),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      _ErrorBanner(_error!),
                    ],
                    const SizedBox(height: 20),

                    _PrimaryButton(
                        label: context.s.loginTitle,
                        loading: _loading,
                        onPressed: _submit),
                    const SizedBox(height: 18),

                    _Divider(context.s.orWith),
                    const SizedBox(height: 18),

                    _SocialLoginRow(
                      loading: _loading || _fbLoading,
                      fbLoading: _fbLoading,
                      onGoogle: _googleSignIn,
                      onFacebook: _facebookSignIn,
                    ),
                    const SizedBox(height: 30),

                    // Sign up row — prominent
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${context.s.noAccount}  ',
                              style: GoogleFonts.ibmPlexSansArabic(
                                  color: cs.onSurfaceVariant, fontSize: 15)),
                          GestureDetector(
                            onTap: () => context.push('/signup'),
                            child: Text(context.s.registerNow,
                                style: GoogleFonts.ibmPlexSansArabic(
                                    color: AppColors.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Teal header banner (matches app brand) ────────────────────────────────────
class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPad + 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00796B), Color(0xFF009688), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // App logo
          Image.asset(
            'assets/images/logo_white.png.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text('Iraq Pharma Guide',
              style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('دليل الصيدلة العراقي',
              style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white.withOpacity(0.85), fontSize: 13)),
        ],
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
            color: Theme.of(context).colorScheme.surface,
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
              Text(context.s.welcomeBack,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(context.s.loginSuccess,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
  final _formKey         = GlobalKey<FormState>();
  final _firstNameCtrl   = TextEditingController();
  final _middleNameCtrl  = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
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
  bool           _agreedToTerms      = false;

  List<String> _getRoles(BuildContext context) => context.s.roles;

  static const _governorates = [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'كركوك',
    'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 'كربلاء', 'النجف',
    'الديوانية', 'ميسان', 'واسط', 'ذي قار', 'المثنى', 'دهوك',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onNameChanged);
    _lastNameCtrl.addListener(_onNameChanged);
    _usernameCtrl.addListener(_onUsernameEdited);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameCtrl.removeListener(_onNameChanged);
    _lastNameCtrl.removeListener(_onNameChanged);
    _usernameCtrl.removeListener(_onUsernameEdited);
    for (final c in [_firstNameCtrl, _middleNameCtrl, _lastNameCtrl,
                     _usernameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Username auto-fill ────────────────────────────────────────────────────
  void _onNameChanged() {
    if (_userEditedUsername) return;
    final combined = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final generated = AuthService.instance.generateUsernameFromName(combined);
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
    if (_selectedRole == null) { setState(() => _error = context.s.chooseProfessionFirst); return; }
    if (_usernameStatus == UsernameStatus.taken) { setState(() => _error = context.s.usernameTakenFull); return; }
    if (!_agreedToTerms) { setState(() => _error = context.s.agreeToTermsErr); return; }
    if (_usernameStatus == UsernameStatus.checking) { setState(() => _error = context.s.checkingUsername); return; }

    setState(() { _loading = true; _error = null; });

    final middle = _middleNameCtrl.text.trim();
    final fullName = [
      _firstNameCtrl.text.trim(),
      if (middle.isNotEmpty) middle,
      _lastNameCtrl.text.trim(),
    ].join(' ');

    final result = await AuthService.instance.signUp(
      email:     _emailCtrl.text,
      password:  _passCtrl.text,
      fullName:  fullName,
      username:  _usernameCtrl.text,
      role:      _selectedRole!,
      phone:     _phoneCtrl.text.trim(),
      birthDate: '',
      address:   '',
    );

    if (!mounted) return;
    if (result.isSuccess) {
      context.push('/otp', extra: {
        'email':   _emailCtrl.text.trim(),
        'type':    OtpType.signup,
        'isLogin': false,
      });
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
      case UsernameStatus.available: return (context.s.usernameAvailable, const Color(0xFF4CAF50));
      case UsernameStatus.taken:     return (context.s.usernameTaken,     Colors.red);
      case UsernameStatus.tooShort:  return (context.s.usernameTooShort,  Colors.orange);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label   = _statusLabel();
    final borderC = _borderColor();
    final focusC  = _usernameStatus == UsernameStatus.available
        ? const Color(0xFF4CAF50) : AppColors.primary;

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Teal header ─────────────────────────────────────────────────────
          _SignUpHeader(onBack: () => context.pop()),

          // ── Scrollable form ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.s.newAccount,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(context.s.newAccountSub,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 20),

                _AuthField(
                  label: context.s.firstName,
                  ctrl: _firstNameCtrl, icon: Icons.person_outline, maxLen: 40,
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.s.enterFirstName : null,
                ),
                const SizedBox(height: 12),

                _AuthField(
                  label: context.s.middleName,
                  ctrl: _middleNameCtrl, icon: Icons.person_outline, maxLen: 40,
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),

                _AuthField(
                  label: context.s.lastName,
                  ctrl: _lastNameCtrl, icon: Icons.person_outline, maxLen: 40,
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.s.enterLastName : null,
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
                        labelText: context.s.usernameField,
                        counterText: '',
                        hintText: context.s.usernameHint,
                        prefixIcon: Icon(Icons.alternate_email_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                        suffixIcon: Padding(
                            padding: const EdgeInsets.all(12), child: _indicator()),
                        filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: GoogleFonts.ibmPlexSansArabic(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusC, width: 1.5)),
                        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return context.s.enterUsername;
                        if (v.trim().length < 4) return context.s.usernameTooShort;
                        if (_usernameStatus == UsernameStatus.taken) return context.s.usernameTakenErr;
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
                  keyboard: TextInputType.emailAddress, validator: (v) => _emailValidator(v, context.s),
                ),
                const SizedBox(height: 12),

                _AuthField(
                  label: context.s.phoneOptional,
                  ctrl: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  maxLen: 15,
                  keyboard: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) return context.s.invalidPhone;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _PasswordField(
                  ctrl: _passCtrl, obscure: _obscure1,
                  onToggle: () => setState(() => _obscure1 = !_obscure1),
                  validator: (v) {
                    if (v == null || v.isEmpty) return context.s.enterPassword;
                    if (v.length < 6) return context.s.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _PasswordField(
                  ctrl: _confirmCtrl, obscure: _obscure2,
                  label: context.s.confirmPassword,
                  onToggle: () => setState(() => _obscure2 = !_obscure2),
                  validator: (v) {
                    if (v == null || v.isEmpty) return context.s.reEnterPassword;
                    if (v != _passCtrl.text) return context.s.passwordMismatch;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: _fieldDeco(label: context.s.profession, icon: Icons.work_outline, context: context),
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                  items: _getRoles(context).map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? context.s.chooseProfession : null,
                ),

                const SizedBox(height: 16),

                // Terms agreement
                InkWell(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(context.s.agreePrefix,
                                style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            GestureDetector(
                              onTap: () => context.push('/legal/terms'),
                              child: Text(context.s.termsOfUse,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13, color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary)),
                            ),
                            Text(context.s.agreeAnd,
                                style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            GestureDetector(
                              onTap: () => context.push('/legal/privacy'),
                              child: Text(context.s.privacyPolicy,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13, color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[const SizedBox(height: 10), _ErrorBanner(_error!)],
                const SizedBox(height: 20),

                _PrimaryButton(label: context.s.signUp, loading: _loading, onPressed: _submit),
                const SizedBox(height: 20),

                // Login row — prominent
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${context.s.alreadyHaveAccount}  ',
                          style: GoogleFonts.ibmPlexSansArabic(
                              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(context.s.signInNow,
                            style: GoogleFonts.ibmPlexSansArabic(
                                color: AppColors.primary, fontSize: 17,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

// ── SignUp header banner ───────────────────────────────────────────────────────
class _SignUpHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _SignUpHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 16, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00796B), Color(0xFF009688), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 12),
          // Icon + text
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.s.createAccount,
                  style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Iraq Pharma Guide',
                  style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS & HELPERS
// ══════════════════════════════════════════════════════════════════════════════

String? _emailValidator(String? v, AppStrings s) {
  if (v == null || v.trim().isEmpty) return s.enterEmail;
  final t = v.trim();
  if (!t.contains('@') || !t.contains('.')) return s.invalidEmail;
  if (t.length > 254) return s.emailTooLong;
  return null;
}

InputDecoration _fieldDeco({required String label, required IconData icon, String? hint, required BuildContext context}) =>
    InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
      labelStyle: GoogleFonts.ibmPlexSansArabic(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
      hintStyle:  GoogleFonts.ibmPlexSansArabic(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
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
    const SizedBox(height: 12),
    Text('Iraq Pharma Guide',
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
    Text('دليل الصيدلة العراقي',
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);
}

// Smart login field: detects email / phone / username and adjusts keyboard + icon
class _UniversalLoginField extends StatefulWidget {
  final TextEditingController ctrl;
  const _UniversalLoginField({required this.ctrl});
  @override
  State<_UniversalLoginField> createState() => _UniversalLoginFieldState();
}

class _UniversalLoginFieldState extends State<_UniversalLoginField> {
  late TextInputType _keyboard;
  late IconData      _icon;
  String             _hint = '';

  @override
  void initState() {
    super.initState();
    _update(widget.ctrl.text);
    widget.ctrl.addListener(_onChanged);
  }

  @override
  void dispose() { widget.ctrl.removeListener(_onChanged); super.dispose(); }

  void _onChanged() => setState(() => _update(widget.ctrl.text));

  void _update(String v) {
    final t = v.trim();
    if (_looksLikePhone(t)) {
      _keyboard = TextInputType.phone;
      _icon     = Icons.phone_outlined;
      _hint     = 'phone';
    } else if (t.contains('@')) {
      _keyboard = TextInputType.emailAddress;
      _icon     = Icons.email_outlined;
      _hint     = '';
    } else {
      _keyboard = TextInputType.text;
      _icon     = Icons.person_outline;
      _hint     = '';
    }
  }

  bool _looksLikePhone(String v) {
    final s = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (s.startsWith('+') && s.length >= 8) return true;
    if (RegExp(r'^(07|009647)').hasMatch(s)) return true;
    if (s.isNotEmpty && RegExp(r'^\d').hasMatch(s)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.ctrl,
    keyboardType: _keyboard,
    textAlign: TextAlign.right,
    maxLength: 254,
    inputFormatters: [LengthLimitingTextInputFormatter(254)],
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _fieldDeco(
      label: context.s.universalFieldLabel,
      icon: _icon,
      hint: _hint == 'phone' ? context.s.phoneExample : (_hint.isEmpty ? null : _hint),
      context: context,
    ).copyWith(counterText: ''),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return context.s.enterIdentifier;
      return null;
    },
  );
}

class _AuthField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLen;
  final String? hint;
  final TextInputType? keyboard;
  final TextDirection? textDirection;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.label, required this.ctrl, required this.icon,
    this.maxLen = 200, this.hint, this.keyboard, this.textDirection, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
    textDirection: textDirection,
    keyboardType: keyboard,
    maxLength: maxLen, inputFormatters: [LengthLimitingTextInputFormatter(maxLen)],
    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
    decoration: _fieldDeco(label: label, icon: icon, hint: hint, context: context).copyWith(counterText: ''),
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
    decoration: _fieldDeco(label: label, icon: Icons.lock_outline, context: context).copyWith(
      counterText: '',
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        onPressed: onToggle,
      ),
    ),
    validator: validator ?? (v) {
      if (v == null || v.isEmpty) return context.s.enterPassword;
      if (v.length < 6) return context.s.passwordTooShort;
      return null;
    },
  );
}

// ── Social Login Row ──────────────────────────────────────────────────────────

// Official SVG logos embedded as constants
const _kFacebookSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99
    4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669
    4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491
    0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24
    18.062 24 12.073z"/>
</svg>''';

const _kGoogleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26
    1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23
    1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43
    8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09
    14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>''';

class _SocialLoginRow extends StatelessWidget {
  final bool loading;
  final bool fbLoading;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  const _SocialLoginRow({
    required this.loading,
    required this.fbLoading,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        'المتابعة عبر',
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          letterSpacing: 0.3,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SocialBtn(
            onTap: loading ? null : onFacebook,
            child: fbLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1877F2)))
                : SvgPicture.string(_kFacebookSvg, width: 24, height: 24),
          ),
          const SizedBox(width: 20),
          _SocialBtn(
            onTap: loading ? null : onGoogle,
            child: SvgPicture.string(_kGoogleSvg, width: 24, height: 24),
          ),
        ],
      ),
    ]);
  }
}

class _SocialBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _SocialBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double size = 54;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      opacity: onTap == null ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8),
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.black.withOpacity(0.04),
          highlightColor: Colors.black.withOpacity(0.02),
          child: SizedBox(
            width: size, height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
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
        child: Text(label, style: GoogleFonts.ibmPlexSansArabic(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))),
    const Expanded(child: Divider()),
  ]);
}
