import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool   _loading  = false;
  bool   _sent     = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.resetPassword(_emailCtrl.text);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() { _loading = false; _sent = true; });
    } else {
      setState(() { _loading = false; _error = result.error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: _sent ? _SuccessView(email: _emailCtrl.text) : _FormView(
            formKey:   _formKey,
            emailCtrl: _emailCtrl,
            loading:   _loading,
            error:     _error,
            onSubmit:  _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72, height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.lock_reset_rounded, color: Colors.orange.shade700, size: 38),
          ),
          const SizedBox(height: 24),
          Text('نسيت كلمة المرور؟',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text('أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 32),

          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.right,
            maxLength: 254,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              counterText: '',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
              filled: true, fillColor: Colors.white,
              labelStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'أدخل بريدك الإلكتروني';
              if (!v.contains('@') || !v.contains('.')) return 'بريد إلكتروني غير صحيح';
              return null;
            },
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!,
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade700, fontSize: 13))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('إرسال رابط الاستعادة',
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 72, height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF4CAF50), size: 42),
        ),
        const SizedBox(height: 24),
        Text('تم الإرسال!',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Text(
          'تحقق من بريدك الإلكتروني $email\nواضغط على الرابط لإعادة تعيين كلمة المرور.',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14, color: AppColors.textSecondary, height: 1.7),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('العودة لتسجيل الدخول',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
