import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../core/l10n/app_strings.dart';

class OtpScreen extends StatefulWidget {
  final String  email;
  final OtpType otpType;
  final bool    isLogin;

  const OtpScreen({
    super.key,
    required this.email,
    required this.otpType,
    this.isLogin = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late final int              _len;
  final TextEditingController _ctrl  = TextEditingController();
  final FocusNode             _focus = FocusNode();

  bool    _loading   = false;
  String? _error;
  int     _countdown = 60;
  bool    _canResend = false;
  Timer?  _timer;

  // Shake on error
  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _len = (widget.otpType == OtpType.signup || widget.otpType == OtpType.recovery) ? 8 : 6;

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),    weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    _ctrl.addListener(_onInput);
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.removeListener(_onInput);
    _ctrl.dispose();
    _focus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onInput() {
    final raw     = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    final clamped = raw.length > _len ? raw.substring(0, _len) : raw;
    if (_ctrl.text != clamped) {
      _ctrl.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
      return;
    }
    if (_error != null) setState(() => _error = null);
    if (clamped.length == _len && !_loading) _verify();
  }

  void _startCountdown() {
    setState(() { _countdown = 60; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) { t.cancel(); _canResend = true; }
      });
    });
  }

  Future<void> _verify() async {
    if (_ctrl.text.length < _len || _loading) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.verifyOtp(
      email: widget.email,
      token: _ctrl.text,
      type:  widget.otpType,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      if (widget.otpType == OtpType.recovery) {
        // Password reset flow → go to new password screen
        context.go('/reset-password');
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SuccessDialog(),
        ).then((_) { if (mounted) context.go('/notification-permission'); });
      }
    } else {
      _ctrl.clear();
      _shakeCtrl.forward(from: 0);
      setState(() { _loading = false; _error = result.error; });
      _focus.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() { _error = null; _ctrl.clear(); });
    if (widget.otpType == OtpType.signup) {
      await AuthService.instance.resendSignupConfirmation(widget.email);
    } else {
      await AuthService.instance.sendEmailOtp(widget.email);
    }
    _startCountdown();
    _focus.requestFocus();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final digits = data!.text!.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final val = digits.substring(0, min(digits.length, _len));
    _ctrl.value = TextEditingValue(
      text: val,
      selection: TextSelection.collapsed(offset: val.length),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxW   = _len > 6 ? 36.0 : 46.0;
    final boxH   = _len > 6 ? 50.0 : 58.0;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF5F7FA),
      // ── invisible text field captures keyboard ───────────────────────────
      body: Stack(
        children: [
          // Hidden input — offstage so it never paints
          Offstage(
            child: TextField(
              controller:   _ctrl,
              focusNode:    _focus,
              keyboardType: TextInputType.number,
              maxLength:    _len,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration.collapsed(hintText: ''),
              enableInteractiveSelection: false,
            ),
          ),

          Column(
            children: [
              // ── Teal header ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00796B), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
                    child: Column(children: [
                      // back row
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: _goBack,
                        ),
                      ]),
                      const SizedBox(height: 4),
                      // icon
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('التحقق من البريد الإلكتروني',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 19, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('أرسلنا رمزاً مكوناً من $_len أرقام إلى',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.82))),
                      const SizedBox(height: 2),
                      Text(widget.email,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.white, letterSpacing: 0.2)),
                    ]),
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    const Spacer(),

                    // OTP boxes
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _focus.requestFocus(),
                      onLongPress: _paste,
                      child: AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        ),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _ctrl,
                          builder: (_, val, __) {
                            final typed     = val.text;
                            final showError = _error != null && typed.isEmpty;
                            return Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_len, (i) {
                                  final filled    = i < typed.length;
                                  final isFocused = _focus.hasFocus && typed.length == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: boxW, height: boxH,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: filled
                                          ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.08)
                                          : isDark
                                              ? const Color(0xFF1C1C1E)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        width: isFocused ? 2.0 : 1.4,
                                        color: showError
                                            ? Colors.red.shade400
                                            : isFocused
                                                ? AppColors.primary
                                                : filled
                                                    ? AppColors.primary.withOpacity(0.4)
                                                    : isDark
                                                        ? const Color(0xFF3A3A3C)
                                                        : const Color(0xFFDDE1E7),
                                      ),
                                      boxShadow: isFocused
                                          ? [BoxShadow(
                                              color: AppColors.primary.withOpacity(0.15),
                                              blurRadius: 8, spreadRadius: 1)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: filled
                                          ? Text(typed[i],
                                              textDirection: TextDirection.ltr,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ))
                                          : isFocused
                                              ? _BlinkingCursor()
                                              : null,
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Paste hint
                    GestureDetector(
                      onTap: _paste,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_paste_rounded,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text('اضغط للصق الرمز',
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),

                    // Error
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                              child: _ErrorBanner(_error!),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const Spacer(),

                    // Verify button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _ctrl,
                        builder: (_, val, __) {
                          final ready = val.text.length == _len;
                          return SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: (_loading || !ready) ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.3),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text(context.s.verifyCode,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Resend
                    GestureDetector(
                      onTap: _canResend ? _resend : null,
                      child: AnimatedOpacity(
                        opacity: _canResend ? 1.0 : 0.55,
                        duration: const Duration(milliseconds: 300),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                            children: [
                              TextSpan(text: 'لم تستلم الرمز؟  ',
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                              TextSpan(
                                text: _canResend
                                    ? 'إعادة الإرسال'
                                    : 'إعادة الإرسال (${_countdown}s)',
                                style: TextStyle(
                                  color: _canResend
                                      ? AppColors.primary
                                      : cs.onSurfaceVariant,
                                  fontWeight: _canResend
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Change email
                    TextButton.icon(
                      onPressed: _goBack,
                      icon: const Icon(Icons.edit_outlined,
                          size: 15, color: AppColors.primary),
                      label: Text('تغيير البريد الإلكتروني',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Blinking cursor ───────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 2, height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.red.shade700, fontSize: 13))),
    ]),
  );
}

// ── Success dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800),
        () { if (mounted) Navigator.of(context).pop(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.12), blurRadius: 24)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(context.s.welcomeBack,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(context.s.loginSuccess,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    ),
  );
}
