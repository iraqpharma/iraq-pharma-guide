import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool    _loading  = false;
  bool    _obscure1 = true;
  bool    _obscure2 = true;
  String? _error;
  bool    _done     = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passCtrl.text),
      );
      if (mounted) setState(() { _loading = false; _done = true; });
    } on AuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'حدث خطأ، حاول مجدداً'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.onSurface, size: 20),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: _done ? _DoneView() : _FormView(
            formKey:    _formKey,
            passCtrl:   _passCtrl,
            confirmCtrl: _confirmCtrl,
            loading:    _loading,
            error:      _error,
            obscure1:   _obscure1,
            obscure2:   _obscure2,
            onToggle1:  () => setState(() => _obscure1 = !_obscure1),
            onToggle2:  () => setState(() => _obscure2 = !_obscure2),
            onSubmit:   _submit,
          ),
        ),
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool    loading;
  final String? error;
  final bool    obscure1;
  final bool    obscure2;
  final VoidCallback onToggle1;
  final VoidCallback onToggle2;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.loading,
    required this.error,
    required this.obscure1,
    required this.obscure2,
    required this.onToggle1,
    required this.onToggle2,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    InputDecoration fieldDeco(String label, IconData icon, {Widget? suffix}) =>
        InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14, color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          suffixIcon: suffix,
          filled: true,
          fillColor: cs.surfaceVariant,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // Icon
          Center(
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 38),
            ),
          ),
          const SizedBox(height: 22),

          Text('تعيين كلمة مرور جديدة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('أدخل كلمة المرور الجديدة التي تريد استخدامها',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 32),

          // New password
          TextFormField(
            controller:  passCtrl,
            obscureText: obscure1,
            maxLength:   128,
            inputFormatters: [LengthLimitingTextInputFormatter(128)],
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
            decoration: fieldDeco(
              'كلمة المرور الجديدة',
              Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: cs.onSurfaceVariant, size: 20,
                ),
                onPressed: onToggle1,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
              if (v.length < 8) return 'يجب أن تكون 8 أحرف على الأقل';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm
          TextFormField(
            controller:  confirmCtrl,
            obscureText: obscure2,
            maxLength:   128,
            inputFormatters: [LengthLimitingTextInputFormatter(128)],
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
            decoration: fieldDeco(
              'تأكيد كلمة المرور',
              Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: cs.onSurfaceVariant, size: 20,
                ),
                onPressed: onToggle2,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'أكّد كلمة المرور';
              if (v != passCtrl.text) return 'كلمتا المرور غير متطابقتين';
              return null;
            },
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error!,
                    style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.red.shade700, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('حفظ كلمة المرور',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done view ─────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 60),
      Center(
        child: Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
      ),
      const SizedBox(height: 28),
      Text('تم تغيير كلمة المرور',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 10),
      Text('يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6)),
      const SizedBox(height: 40),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('الذهاب إلى تسجيل الدخول',
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  );
}
