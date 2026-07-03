import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});
  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _client   = Supabase.instance.client;
  final _formKey  = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _picker   = ImagePicker();

  String?  _selectedCategory;
  File?    _image;
  bool     _sending = false;
  bool     _sent    = false;
  String?  _error;


  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  // ── اختيار صورة من المعرض أو الكاميرا ──────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    // طلب الأذن المناسب
    Permission permission = source == ImageSource.camera
        ? Permission.camera
        : (Platform.isAndroid &&
                (await Permission.photos.status).isDenied)
            ? Permission.storage
            : Permission.photos;

    final status = await permission.request();
    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          status.isPermanentlyDenied
              ? context.s.allowAccessSettings
              : context.s.allowAccessRequired,
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        action: status.isPermanentlyDenied
            ? SnackBarAction(
                label: context.s.settingsTitle,
                onPressed: openAppSettings,
              )
            : null,
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (file != null && mounted) {
      setState(() => _image = File(file.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
              ),
              title: Text(context.s.fromGallery,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF5C6BC0)),
              ),
              title: Text(context.s.takePicture,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ]),
        ),
      ),
    );
  }

  // ── إرسال الاقتراح ────────────────────────────────────────────────────────
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });

    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('not logged in');

      String? imageUrl;

      // رفع الصورة إذا وجدت
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        final ext   = _image!.path.split('.').last.toLowerCase();
        final path  = 'suggestions/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _client.storage.from('suggestions').uploadBinary(
          path, bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
        );
        imageUrl = _client.storage.from('suggestions').getPublicUrl(path);
      }

      await _client.from('user_suggestions').insert({
        'user_id':         uid,
        'category':        _selectedCategory,
        'suggestion_text': _textCtrl.text.trim(),
        'image_url':       imageUrl,
        'created_at':      DateTime.now().toIso8601String(),
      });

      if (mounted) setState(() { _sent = true; _sending = false; });
    } catch (_) {
      setState(() {
        _sending = false;
        _error = context.s.sendFailed_;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(context.s.suggestionTitle,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  // ── شاشة النجاح ──────────────────────────────────────────────────────────
  Widget _buildSuccess() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        Text(context.s.suggestionSent,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 10),
        Text(context.s.suggestionSentMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(context.s.back,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  // ── نموذج الاقتراح ────────────────────────────────────────────────────────
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
            const Icon(Icons.lightbulb_outline_rounded,
                color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.s.yourOpinionMatters,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(context.s.suggestionHeaderSub,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Category
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel(context.s.suggestionType, Icons.category_outlined),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: context.s.suggestionCategories.map((cat) {
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE0E0E0)),
                    boxShadow: selected
                        ? [BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(cat,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ])),
        const SizedBox(height: 14),

        // Text
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel(context.s.suggestionDetails, Icons.edit_note_rounded),
          const SizedBox(height: 10),
          TextFormField(
            controller: _textCtrl,
            textAlign: TextAlign.right,
            maxLines: 6, minLines: 4,
            maxLength: 1000,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: context.s.suggestionHint,
              hintStyle: GoogleFonts.ibmPlexSansArabic(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 13),
              filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.red, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return context.s.writeYourSuggestion;
              if (v.trim().length < 10) return context.s.min10Chars;
              return null;
            },
          ),
        ])),
        const SizedBox(height: 14),

        // Image attachment
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel(context.s.attachImageOptional, Icons.image_outlined),
          const SizedBox(height: 12),
          if (_image != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!,
                      width: double.infinity, height: 180,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              height: _image != null ? 44 : 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE0E0E0), style: BorderStyle.solid),
              ),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _image != null
                        ? Icons.swap_horiz_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: AppColors.primary, size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _image != null ? context.s.changeImage : context.s.tapToAddImage,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
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
                  style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.red.shade700, fontSize: 13))),
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
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _sending ? context.s.sending_ : context.s.suggestionTitle,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    ),
  );

  Widget _card({required Widget child}) => Builder(builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))
      ],
    ),
    child: child,
  ));

  Widget _fieldLabel(String text, IconData icon) => Builder(builder: (context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.primary),
    const SizedBox(width: 6),
    Text(text, style: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface)),
  ]));
}
