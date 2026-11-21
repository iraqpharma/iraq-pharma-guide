import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نتيجة قراءة الباركود.
class BarcodeHit {
  final String barcode;
  final int? drugId;
  final String name;
  final String form;
  final String strength;
  final int confirms;

  const BarcodeHit({
    required this.barcode,
    required this.name,
    this.drugId,
    this.form = '',
    this.strength = '',
    this.confirms = 1,
  });

  String get label => [name, strength, form]
      .where((e) => e.trim().isNotEmpty)
      .join('  ·  ');

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'drug_id': drugId,
        'display_name': name,
        'dosage_form': form,
        'strength': strength,
        'confirms': confirms,
      };

  factory BarcodeHit.fromMap(Map<String, dynamic> m) => BarcodeHit(
        barcode: (m['barcode'] ?? '').toString(),
        drugId: m['drug_id'] is int
            ? m['drug_id'] as int
            : int.tryParse('${m['drug_id']}'),
        name: (m['display_name'] ?? '').toString(),
        form: (m['dosage_form'] ?? '').toString(),
        strength: (m['strength'] ?? '').toString(),
        confirms: m['confirms'] is int
            ? m['confirms'] as int
            : int.tryParse('${m['confirms']}') ?? 1,
      );
}

/// ربط أرقام الباركود بأسماء الأدوية.
///
/// الباركود المطبوع على العلبة رقم تسلسلي لا يحمل اسم الدواء ولا تركيزه،
/// فلا يمكن لأي تطبيق أن يستخرج الاسم من الرقم نفسه. المصدر الوحيد هو
/// قاعدة ربط بين الرقم والاسم، وقواعد الباركود العالمية مدفوعة ولا تغطّي
/// المستورد إلى العراق. لذلك تُبنى القاعدة من الصيادلة أنفسهم: من يقرأ
/// رقماً غير معروف يُسنده إلى دواء مرّة واحدة، فيصبح معروفاً لكل
/// المستخدمين بعدها، ومن يقرأ رقماً معروفاً يؤكّده فيزيد وزنه.
class BarcodeService {
  BarcodeService._();
  static final instance = BarcodeService._();

  SupabaseClient get _db => Supabase.instance.client;

  static const _cacheKey = 'barcode_cache_v1';

  /// هل النص رقم باركود وليس اسم دواء؟
  ///
  /// أرقام الباركود التجارية EAN-13 و EAN-8 و UPC-A رقمية بحتة بطول
  /// 8 خانات أو أكثر، ولا يوجد اسم دواء بهذا الشكل، فالتمييز آمن.
  static bool looksLikeBarcode(String s) {
    final t = s.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (t.length < 8 || t.length > 20) return false;
    return RegExp(r'^[0-9]+$').hasMatch(t);
  }

  static String normalize(String s) =>
      s.trim().replaceAll(RegExp(r'[\s-]'), '');

  // ── التخزين المحلّي ليعمل البحث بلا إنترنت ───────────────────────

  Future<Map<String, dynamic>> _cache() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_cacheKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _remember(BarcodeHit hit) async {
    final p = await SharedPreferences.getInstance();
    final c = await _cache();
    c[hit.barcode] = hit.toJson();
    // لا نُراكم بلا حدّ: نحفظ آخر 500 قراءة
    if (c.length > 500) {
      final keys = c.keys.toList().sublist(0, c.length - 500);
      for (final k in keys) {
        c.remove(k);
      }
    }
    await p.setString(_cacheKey, jsonEncode(c));
  }

  Future<BarcodeHit?> _fromCache(String code) async {
    final c = await _cache();
    final m = c[code];
    if (m is Map) return BarcodeHit.fromMap(m.cast<String, dynamic>());
    return null;
  }

  // ── البحث ────────────────────────────────────────────────────────

  /// يبحث عن الرقم في القاعدة، ويرجع null إن كان غير معروف.
  ///
  /// يُجرّب الذاكرة المحلّية أولاً فيعمل بلا إنترنت، ثم السيرفر.
  Future<BarcodeHit?> lookup(String raw) async {
    final code = normalize(raw);
    if (code.isEmpty) return null;

    final local = await _fromCache(code);

    try {
      final row = await _db
          .from('barcode_map')
          .select()
          .eq('barcode', code)
          .maybeSingle();
      if (row != null) {
        final hit = BarcodeHit.fromMap((row as Map).cast<String, dynamic>());
        await _remember(hit);
        return hit;
      }
      return null; // معروف أنه غير موجود على السيرفر
    } catch (_) {
      // لا إنترنت: نكتفي بما في الذاكرة
      return local;
    }
  }

  /// هل الحساب الحالي مدير؟ الربط النهائي محصور بهم.
  ///
  /// ربط رقم باسم دواء خاطئ أسوأ من تركه مجهولاً، لأن الصيدلاني سيثق
  /// بالنتيجة ويصرف على أساسها. لذلك لا يكتب في القاعدة إلا المدير،
  /// والمستخدم يرسل اقتراحاً يُراجَع.
  Future<bool> isAdmin() async {
    try {
      final r = await _db.rpc('is_db_admin');
      return r == true;
    } catch (_) {
      return false;
    }
  }

  /// يُسند رقماً غير معروف إلى دواء. للمدراء فقط (تمنعه RLS لغيرهم).
  Future<bool> submit({
    required String barcode,
    required String name,
    int? drugId,
    String form = '',
    String strength = '',
  }) async {
    final code = normalize(barcode);
    if (!looksLikeBarcode(code)) return false;
    if (name.trim().length < 2) return false;
    try {
      await _db.from('barcode_map').insert({
        'barcode': code,
        'drug_id': drugId,
        'display_name': name.trim(),
        'dosage_form': form.trim(),
        'strength': strength.trim(),
      });
      await _remember(BarcodeHit(
        barcode: code,
        name: name.trim(),
        drugId: drugId,
        form: form.trim(),
        strength: strength.trim(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// اقتراح من مستخدم عادي. لا يظهر لأحد قبل مراجعة المدير.
  Future<bool> suggest({
    required String barcode,
    required String name,
    String form = '',
    String strength = '',
  }) async {
    final code = normalize(barcode);
    if (!looksLikeBarcode(code)) return false;
    try {
      await _db.from('barcode_submissions').insert({
        'barcode': code,
        'suggested_name': name.trim(),
        'dosage_form': form.trim(),
        'strength': strength.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── إدارة الاقتراحات ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> pendingSubmissions() async {
    final rows = await _db
        .from('barcode_submissions')
        .select()
        .eq('status', 'new')
        .order('created_at', ascending: false)
        .limit(300);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<int> pendingCount() async {
    try {
      final rows = await _db
          .from('barcode_submissions')
          .select('id')
          .eq('status', 'new');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setSubmissionStatus(dynamic id, String status) async {
    await _db
        .from('barcode_submissions')
        .update({'status': status}).eq('id', id);
  }

  /// آخر ما أُضيف إلى القاعدة، لشاشة الإدارة.
  Future<List<BarcodeHit>> recent({int limit = 100}) async {
    final rows = await _db
        .from('barcode_map')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => BarcodeHit.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> remove(String barcode) async {
    await _db.from('barcode_map').delete().eq('barcode', normalize(barcode));
  }

  /// إدخال دفعة واحدة من سطور «رقم , اسم , تركيز , شكل».
  ///
  /// الفواصل المقبولة: فاصلة أو فاصلة منقوطة أو تبويب، كي يُلصق مباشرة
  /// من جدول Excel أو من ملف CSV جاء من مندوب أو شركة.
  /// يُرجع (عدد المُضاف، قائمة الأسطر المرفوضة بسببها).
  Future<(int, List<String>)> importLines(String text) async {
    final rows = <Map<String, dynamic>>[];
    final bad  = <String>[];

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line
          .split(RegExp(r'[,;\t]'))
          .map((e) => e.trim())
          .toList();
      if (parts.length < 2) {
        bad.add('$line  ←  ينقصه الاسم');
        continue;
      }
      final code = normalize(parts[0]);
      if (!looksLikeBarcode(code)) {
        bad.add('$line  ←  الرقم غير صالح');
        continue;
      }
      if (parts[1].length < 2) {
        bad.add('$line  ←  الاسم قصير');
        continue;
      }
      rows.add({
        'barcode': code,
        'display_name': parts[1],
        'strength': parts.length > 2 ? parts[2] : '',
        'dosage_form': parts.length > 3 ? parts[3] : '',
      });
    }

    if (rows.isEmpty) return (0, bad);
    try {
      // upsert كي لا يفشل السطر كلّه بسبب رقم مكرّر
      await _db.from('barcode_map').upsert(rows, onConflict: 'barcode');
      return (rows.length, bad);
    } catch (e) {
      bad.add('تعذّر الحفظ: $e');
      return (0, bad);
    }
  }

  /// يزيد عدّاد التأكيد لرقم معروف، فتُرتّب الأسماء المتنازعة بالوزن.
  Future<void> confirm(String barcode) async {
    try {
      await _db.rpc('confirm_barcode', params: {'p_barcode': normalize(barcode)});
    } catch (_) {
      // التأكيد تحسين لا أكثر، فلا نُزعج المستخدم بفشله
    }
  }

  /// عدد الأرقام المعروفة، لعرضه في الإحصائيات.
  Future<int> knownCount() async {
    try {
      final rows = await _db.from('barcode_map').select('barcode');
      return (rows as List).length;
    } catch (_) {
      return (await _cache()).length;
    }
  }
}
