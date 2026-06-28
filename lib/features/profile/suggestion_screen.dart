import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});
  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _client    = Supabase.instance.client;
  final _formKey   = GlobalKey<FormState>();
  final _textCtrl  = TextEditingController();
  String? _selectedCategory;
  bool    _sending = false;
  bool    _sent    = false;
  String? _error;

  static const _categories = [
    'اقتراح ميزة جديدة',
    'الإبلاغ عن خطأ',
    'تحسين واجهة المستخدم',
    'إضافة دواء أو معلومة',
    'أخرى',
  ];

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('not logged in');
      await _client.from('user_suggestions').insert({
        'user_id':         uid,
        'suggestion_text': '${_selectedCategory != null ? "[${_selectedCategory!}] " : ""}${_textCtrl.text.trim()}',
        'created_at':      DateTime.now().toIso8601String(),
      });
      if (mounted) setState(() { _sent = true; _sending = false; });
    } catch (_) {
      setState(() { _sending = false; _error = 'فشل الإرسال، تحقق من اتصالك وحاول مجدداً'; });
    }
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
        title: Text('إرسال اقتراح',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        Text('تم إرسال اقتراحك!',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Text('شكراً لمساهمتك في تطوير التطبيق.\nسنراجع اقتراحك في أقرب وقت.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('العودة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(18),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkNavy, AppColors.primary],
              begin: Alignment.centerRight, end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('رأيك يهمنا',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('ساعدنا في تحسين التطبيق باقتراحاتك',
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12, color: Colors.white.withOpacity(0.85))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Category
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel('نوع الاقتراح', Icons.category_outlined),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
                    boxShadow: selected ? [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))
                    ] : [],
                  ),
                  child: Text(cat,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ])),
        const SizedBox(height: 14),

        // Text
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel('تفاصيل الاقتراح', Icons.edit_note_rounded),
          const SizedBox(height: 10),
          TextFormField(
            controller: _textCtrl,
            textAlign: TextAlign.right,
            maxLines: 6, minLines: 4,
            maxLength: 1000,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'اكتب اقتراحك أو وصف المشكلة هنا...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(
                  color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.all(14),
              border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'يرجى كتابة اقتراحك';
              if (v.trim().length < 10) return '10 أحرف على الأقل';
              return null;
            },
          ),
        ])),
        const SizedBox(height: 8),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!,
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade700, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_sending ? 'جارٍ الإرسال...' : 'إرسال الاقتراح',
                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _fieldLabel(String text, IconData icon) => Row(children: [
    Icon(icon, size: 16, color: AppColors.primary),
    const SizedBox(width: 6),
    Text(text, style: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  ]);
}
