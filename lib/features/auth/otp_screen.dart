import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String  email;
  final OtpType otpType;
  final bool    isLogin; // true = show success dialog before going home

  const OtpScreen({super.key, required this.email, required this.otpType, this.isLogin = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final int _codeLength;
  late final List<TextEditingController> _ctls;
  late final List<FocusNode>             _nodes;

  bool    _loading   = false;
  String? _error;
  int     _countdown = 60;
  bool    _canResend = false;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    // Signup confirmation uses 8-digit token, login OTP uses 6-digit
    _codeLength = widget.otpType == OtpType.signup ? 8 : 6;
    _ctls  = List.generate(_codeLength, (_) => TextEditingController());
    _nodes = List.generate(_codeLength, (_) => FocusNode());
    _startCountdown();
    for (int i = 0; i < _codeLength; i++) {
      _ctls[i].addListener(_checkAutoVerify);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctls)  { c.removeListener(_checkAutoVerify); c.dispose(); }
    for (final n in _nodes) n.dispose();
    super.dispose();
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

  String get _token => _ctls.map((c) => c.text).join();

  void _checkAutoVerify() {
    if (_token.length == _codeLength && !_loading) _verify();
  }

  void _onDigit(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Paste: fill all boxes at once
    if (digits.length >= _codeLength) {
      for (int i = 0; i < _codeLength; i++) {
        _ctls[i].text = digits[i];
        _ctls[i].selection = const TextSelection.collapsed(offset: 1);
      }
      _nodes[_codeLength - 1].requestFocus();
      setState(() {}); // refresh border colors
      return;
    }

    // Single digit typed → move forward
    if (digits.isNotEmpty) {
      _ctls[index].text = digits[digits.length - 1];
      _ctls[index].selection = const TextSelection.collapsed(offset: 1);
      if (index < _codeLength - 1) _nodes[index + 1].requestFocus();
      setState(() {});
      return;
    }

    // Deleted → move back
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_token.length < _codeLength || _loading) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.verifyOtp(
      email: widget.email,
      token: _token,
      type:  widget.otpType,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      if (widget.isLogin) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _LoginSuccessDialog(),
        ).then((_) { if (mounted) context.go('/notification-permission'); });
      } else {
        // Signup confirmation → show success screen
        context.go('/register-success');
      }
      return;
    } else {
      for (final c in _ctls) c.clear();
      _nodes[0].requestFocus();
      setState(() { _loading = false; _error = result.error; });
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _error = null);
    if (widget.otpType == OtpType.signup) {
      await AuthService.instance.resendSignupConfirmation(widget.email);
    } else {
      await AuthService.instance.sendEmailOtp(widget.email);
    }
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 38),
              ),
              const SizedBox(height: 22),

              Text('التحقق من البريد الإلكتروني',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'أرسلنا رمز مكون من $_codeLength أرقام إلى\n${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 36),

              // OTP boxes — always LTR, digits only
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_codeLength, (i) {
                    final boxSize = _codeLength > 6 ? 38.0 : 48.0;
                    return Container(
                      width: boxSize, height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ctls[i].text.isNotEmpty
                              ? AppColors.primary
                              : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
                        ],
                      ),
                      child: TextField(
                        controller:   _ctls[i],
                        focusNode:    _nodes[i],
                        textAlign:    TextAlign.center,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        maxLength:    _codeLength,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_codeLength),
                        ],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          counterText: '',
                          border:        InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (v) => _onDigit(i, v),
                        onTap: () => _ctls[i].selection = TextSelection.fromPosition(
                            TextPosition(offset: _ctls[i].text.length)),
                      ),
                    );
                  }),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(_error!),
              ],
              const SizedBox(height: 28),

              // Verify button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: (_loading || _token.length < _codeLength) ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('تحقق من الرمز',
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              // Resend
              GestureDetector(
                onTap: _canResend ? _resend : null,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                    children: [
                      TextSpan(text: 'لم تستلم الرمز؟ ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      TextSpan(
                        text: _canResend ? 'إعادة الإرسال' : 'إعادة الإرسال (${_countdown}s)',
                        style: TextStyle(
                          color: _canResend ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: _canResend ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

// ── Login success dialog (shared with login_screen via import) ────────────────
class _LoginSuccessDialog extends StatefulWidget {
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
      backgroundColor: Colors.transparent, elevation: 0,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text('أهلاً بعودتك!',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('تم تسجيل الدخول بنجاح.',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}
