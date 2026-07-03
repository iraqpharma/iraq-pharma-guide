import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/admin_access_service.dart';

const _kAdminPinKey = 'admin_pin_hash';

String _hashPin(String pin) =>
    sha256.convert(utf8.encode('ipg_salt_$pin')).toString();

class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});
  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = true;
  bool _hasPin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasAccess = await AdminAccessService.instance.hasAccess();
    if (!hasAccess) {
      // Defense in depth: block direct navigation even if the UI entry
      // point were somehow reached by a non-admin account.
      if (mounted) context.pop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPin = prefs.getString(_kAdminPinKey) != null;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'الرمز يجب أن يكون 4 أرقام على الأقل');
      return;
    }
    if (_hasPin) {
      final savedHash = prefs.getString(_kAdminPinKey);
      if (_hashPin(pin) != savedHash) {
        setState(() => _error = 'الرمز غير صحيح');
        return;
      }
      if (mounted) context.push('/admin/drugs');
    } else {
      if (pin != _confirmCtrl.text.trim()) {
        setState(() => _error = 'الرمزان غير متطابقين');
        return;
      }
      await prefs.setString(_kAdminPinKey, _hashPin(pin));
      if (mounted) context.push('/admin/drugs');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('إدارة قاعدة البيانات',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              _hasPin ? 'أدخل رمز الدخول' : 'أنشئ رمز دخول جديد (4 أرقام أو أكثر)',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: _hasPin ? 'الرمز' : 'رمز جديد',
                filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (!_hasPin) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 22, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: 'تأكيد الرمز',
                  filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.ibmPlexSansArabic(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_hasPin ? 'دخول' : 'إنشاء وحفظ',
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
