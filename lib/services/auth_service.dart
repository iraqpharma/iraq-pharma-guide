import 'dart:convert';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Input limits ──────────────────────────────────────────────────────────────
const int kMaxEmailLen    = 254;
const int kMaxPasswordLen = 128;
const int kMaxNameLen     = 80;
const int kMaxUsernameLen = 30;
const int kMaxAddressLen  = 200;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static const _keyPendingProfile = 'pending_profile_v1';

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
    required String birthDate,
    required String address,
  }) async {
    email    = _clamp(email.trim().toLowerCase(), kMaxEmailLen);
    password = _clamp(password, kMaxPasswordLen);
    fullName = _clamp(_sanitizeText(fullName), kMaxNameLen);
    username = _clamp(_sanitizeUsername(username), kMaxUsernameLen);
    address  = _clamp(_sanitizeText(address), kMaxAddressLen);

    // Profile data without id (id added at flush time after OTP)
    final pendingProfile = {
      'email':      email,
      'full_name':  fullName,
      'username':   username,
      'role':       role,
      'birth_date': birthDate.isEmpty ? null : birthDate,
      'address':    address,
    };

    try {
      final res = await _client.auth.signUp(email: email, password: password);
      final user = res.user;
      if (user == null) return AuthResult.failure('فشل إنشاء الحساب، يرجى المحاولة مجدداً');

      final profileData = {'id': user.id, ...pendingProfile};

      // Insert profile (email confirmation disabled → session is active immediately)
      try {
        await _client.from('profiles').upsert(profileData);
      } catch (_) {}

      return AuthResult.success(email: email);
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('فشل إنشاء الحساب: ${e.toString().split('\n').first}');
    }
  }

  // Creates pending profile after OTP verification when session is now active
  Future<void> _flushPendingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingProfile);
    if (raw == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      // Add user id if missing (happens when email sending failed during signUp)
      if (!data.containsKey('id') || data['id'] == null) {
        final uid = _client.auth.currentUser?.id;
        if (uid == null) return;
        data['id'] = uid;
      }
      await _client.from('profiles').upsert(data);
      await prefs.remove(_keyPendingProfile);
    } catch (_) {}
  }

  // ── Sign In (email or username + password) ───────────────────────────────
  Future<AuthResult> signIn({required String emailOrUsername, required String password}) async {
    password = _clamp(password, kMaxPasswordLen);

    // Resolve username → email if needed
    String email = emailOrUsername.trim().toLowerCase();
    if (!email.contains('@')) {
      final resolved = await _resolveEmailFromUsername(email);
      if (resolved == null) return AuthResult.failure('اسم المستخدم غير موجود');
      email = resolved;
    }
    email = _clamp(email, kMaxEmailLen);

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('تحقق من اتصالك بالإنترنت');
    }
  }

  Future<String?> _resolveEmailFromUsername(String username) async {
    try {
      final result = await _client
          .rpc('get_email_by_username', params: {'uname': _sanitizeUsername(username)});
      return result as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Resend Signup Confirmation ────────────────────────────────────────────
  Future<void> resendSignupConfirmation(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim().toLowerCase());
    } catch (_) {}
  }

  // ── Send Email OTP ────────────────────────────────────────────────────────
  Future<AuthResult> sendEmailOtp(String email) async {
    email = _clamp(email.trim().toLowerCase(), kMaxEmailLen);
    try {
      await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return AuthResult.success(email: email);
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('فشل إرسال الرمز، تحقق من اتصالك');
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<AuthResult> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: _clamp(email.trim().toLowerCase(), kMaxEmailLen),
        token: _clamp(token.trim(), 10),
        type:  type,
      );
      // Now we have an active session → create pending profile if any
      await _flushPendingProfile();
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('رمز غير صحيح أو منتهي الصلاحية');
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser   = await googleSignIn.signIn();
      if (googleUser == null) return AuthResult.failure('تم إلغاء تسجيل الدخول');

      final googleAuth  = await googleUser.authentication;
      final idToken     = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) return AuthResult.failure('فشل الحصول على بيانات Google');

      await _client.auth.signInWithIdToken(
        provider:    OAuthProvider.google,
        idToken:     idToken,
        accessToken: accessToken,
      );

      // Create profile on first Google login
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        final existing = await _client.from('profiles').select('id').eq('id', uid).maybeSingle();
        if (existing == null) {
          final uname = await _uniqueUsername(_usernameFromEmail(googleUser.email));
          await _client.from('profiles').insert({
            'id':        uid,
            'full_name': googleUser.displayName ?? '',
            'username':  uname,
          });
        }
      }
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('فشل تسجيل الدخول بـ Google');
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    email = _clamp(email.trim().toLowerCase(), kMaxEmailLen);
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('فشل إرسال رابط الاستعادة');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async => _client.auth.signOut();

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return _client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  Future<AuthResult> updateProfile(Map<String, dynamic> data) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return AuthResult.failure('غير مسجّل الدخول');
    try {
      final sanitized = <String, dynamic>{};
      if (data.containsKey('full_name'))
        sanitized['full_name'] = _clamp(_sanitizeText(data['full_name'] as String), kMaxNameLen);
      if (data.containsKey('username'))
        sanitized['username'] = _clamp(_sanitizeUsername(data['username'] as String), kMaxUsernameLen);
      if (data.containsKey('role'))       sanitized['role']       = data['role'];
      if (data.containsKey('address'))    sanitized['address']    = data['address'];
      if (data.containsKey('birth_date')) sanitized['birth_date'] = data['birth_date'];
      await _client.from('profiles').update(sanitized).eq('id', uid);
      return AuthResult.success();
    } catch (_) {
      return AuthResult.failure('فشل تحديث البيانات');
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return AuthResult.failure('غير مسجّل الدخول');
    try {
      await _client.auth.signInWithPassword(email: email, password: currentPassword);
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('فشل تغيير كلمة المرور');
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Future<void> incrementDrugSearch() async  => _incrementStat('drug_search_count');
  Future<void> incrementToolUsage() async   => _incrementStat('tool_usage_count');

  Future<void> _incrementStat(String column) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.rpc('increment_profile_stat', params: {'uid': uid, 'col': column});
    } catch (_) {}
  }

  // ── Username Availability ─────────────────────────────────────────────────
  Future<UsernameStatus> checkUsername(String username) async {
    username = _sanitizeUsername(username);
    if (username.length < 4) return UsernameStatus.tooShort;
    try {
      final res = await _client.from('profiles')
          .select('username').eq('username', username).maybeSingle();
      return res == null ? UsernameStatus.available : UsernameStatus.taken;
    } catch (_) {
      return UsernameStatus.error;
    }
  }

  // ── Username generation (Arabic + English) ───────────────────────────────
  String generateUsernameFromName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final latin = _containsArabic(trimmed)
        ? _transliterate(trimmed)
        : trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
    final username = latin.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'_+'), '_');
    return _clamp(username, 20);
  }

  Future<String> findAvailableUsername(String base) async {
    if (base.length < 4) base = '${base}user';
    final clean = _sanitizeUsername(base);
    if (await checkUsername(clean) == UsernameStatus.available) return clean;
    for (int i = 1; i <= 99; i++) {
      final candidate = '$clean$i';
      if (await checkUsername(candidate) == UsernameStatus.available) return candidate;
    }
    return '${clean}_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  bool _containsArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

  String _transliterate(String arabic) {
    const map = {
      'أ': 'a', 'ا': 'a', 'إ': 'i', 'آ': 'a', 'ء': '',
      'ب': 'b', 'ت': 't', 'ث': 'th', 'ج': 'j', 'ح': 'h',
      'خ': 'kh', 'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z',
      'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'd', 'ط': 't',
      'ظ': 'z', 'ع': 'a', 'غ': 'gh', 'ف': 'f', 'ق': 'q',
      'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h',
      'و': 'w', 'ي': 'y', 'ى': 'a', 'ة': 'a', 'ئ': 'y',
      'ؤ': 'w', 'ّ': '', 'َ': 'a', 'ِ': 'i', 'ُ': 'u',
      'ً': '', 'ٍ': '', 'ٌ': '', 'ْ': '',
    };
    final buf = StringBuffer();
    for (final ch in arabic.split('')) {
      if (map.containsKey(ch)) {
        buf.write(map[ch]);
      } else if (RegExp(r'[a-zA-Z0-9]').hasMatch(ch)) {
        buf.write(ch.toLowerCase());
      } else if (ch == ' ') {
        buf.write('_');
      }
    }
    return buf.toString();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<String> _uniqueUsername(String base) async {
    String candidate = base;
    for (int i = 0; i < 10; i++) {
      if (await checkUsername(candidate) == UsernameStatus.available) return candidate;
      candidate = '$base${Random().nextInt(9999)}';
    }
    return '${base}_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  String _clamp(String v, int max)       => v.length > max ? v.substring(0, max) : v;
  String _sanitizeText(String v)         => v.replaceAll(RegExp("[<>\"'\\\\;]"), '');
  String _sanitizeUsername(String v)     => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  String _usernameFromEmail(String email) {
    final local = email.split('@').first;
    return _sanitizeUsername(local).substring(0, min(20, local.length));
  }

  String _translateAuthError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login credentials') || m.contains('invalid credentials'))
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    if (m.contains('already registered') || m.contains('already exists'))
      return 'البريد الإلكتروني مسجّل مسبقاً، يرجى تسجيل الدخول';
    if (m.contains('password should be at least'))
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    if (m.contains('token') && (m.contains('invalid') || m.contains('expired')))
      return 'رمز التحقق غير صحيح أو منتهي الصلاحية';
    if (m.contains('otp'))            return 'رمز التحقق غير صحيح';
    if (m.contains('email not confirmed')) return 'يرجى تأكيد بريدك الإلكتروني';
    if (m.contains('unable to validate email') || m.contains('invalid email'))
      return 'صيغة البريد الإلكتروني غير صحيحة';
    if (m.contains('error sending confirmation') || m.contains('unexpected_failure') || m.contains('smtp'))
      return 'تعذّر إرسال بريد التأكيد، يرجى التواصل مع الدعم أو المحاولة لاحقاً';
    if (m.contains('too many requests') || m.contains('rate limit'))
      return 'محاولات كثيرة، انتظر قليلاً ثم حاول مجدداً';
    if (m.contains('user not found') || m.contains('no user'))
      return 'لا يوجد حساب بهذا البريد الإلكتروني';
    if (m.contains('network') || m.contains('connection'))
      return 'تحقق من اتصالك بالإنترنت';
    return 'حدث خطأ: $msg';
  }
}

// ── Types ─────────────────────────────────────────────────────────────────────
enum UsernameStatus { idle, checking, available, taken, tooShort, error }

class AuthResult {
  final bool    isSuccess;
  final String? error;
  final bool    needsOtp;
  final String? email;

  const AuthResult._({required this.isSuccess, this.error, this.needsOtp = false, this.email});

  factory AuthResult.success({bool needsOtp = false, String? email}) =>
      AuthResult._(isSuccess: true, needsOtp: needsOtp, email: email);
  factory AuthResult.failure(String error) => AuthResult._(isSuccess: false, error: error);
}
