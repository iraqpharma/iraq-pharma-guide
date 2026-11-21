import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../services/barcode_service.dart';
import '../../services/haptics_service.dart';
import '../barcode/barcode_resolver.dart';

/// إدارة قاعدة الباركود.
///
/// ثلاثة طرق للبناء، من الأسرع إلى الأدقّ:
/// 1. لصق دفعة من جدول Excel أو ملف CSV جاء من شركة أو مندوب.
/// 2. إدخال مفرد مع قراءة الرقم بالكاميرا من العلبة التي بيدك.
/// 3. مراجعة اقتراحات المستخدمين واعتماد الصحيح منها.
class BarcodeAdminScreen extends StatefulWidget {
  const BarcodeAdminScreen({super.key});

  @override
  State<BarcodeAdminScreen> createState() => _BarcodeAdminScreenState();
}

class _BarcodeAdminScreenState extends State<BarcodeAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('قاعدة الباركود',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: TabBar(
          controller: _tabs,
          labelStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'إدخال مفرد'),
            Tab(text: 'لصق دفعة'),
            Tab(text: 'اقتراحات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_SingleTab(), _BulkTab(), _SuggestionsTab()],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// إدخال مفرد
// ════════════════════════════════════════════════════════════════════════

class _SingleTab extends StatefulWidget {
  const _SingleTab();

  @override
  State<_SingleTab> createState() => _SingleTabState();
}

class _SingleTabState extends State<_SingleTab> {
  final _code     = TextEditingController();
  final _name     = TextEditingController();
  final _strength = TextEditingController();
  final _form     = TextEditingController();

  List<String> _hints = [];
  List<BarcodeHit> _recent = [];
  bool _busy = false;
  String? _msg;
  bool _msgOk = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _strength.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    try {
      final r = await BarcodeService.instance.recent(limit: 40);
      if (mounted) setState(() => _recent = r);
    } catch (_) {}
  }

  Future<void> _scan() async {
    final c = await BarcodeResolver.scan(context);
    if (c == null || !mounted) return;
    _code.text = BarcodeService.normalize(c);
    setState(() {});
  }

  Future<void> _suggestName(String q) async {
    if (q.trim().length < 2) {
      if (_hints.isNotEmpty) setState(() => _hints = []);
      return;
    }
    final r = await DatabaseHelper.instance.searchNames(q, limit: 7);
    if (mounted) setState(() => _hints = r);
  }

  Future<void> _save() async {
    final code = BarcodeService.normalize(_code.text);
    final name = _name.text.trim();
    if (!BarcodeService.looksLikeBarcode(code)) {
      setState(() {
        _msg = 'الرقم يجب أن يكون 8 خانات رقمية فأكثر';
        _msgOk = false;
      });
      Haptics.error();
      return;
    }
    if (name.length < 2) {
      setState(() {
        _msg = 'اكتب اسم الدواء';
        _msgOk = false;
      });
      Haptics.error();
      return;
    }
    setState(() => _busy = true);
    final ok = await BarcodeService.instance.submit(
      barcode: code,
      name: name,
      form: _form.text.trim(),
      strength: _strength.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _msgOk = ok;
      _msg = ok ? 'أُضيف: $name' : 'تعذّر الحفظ. الرقم موجود مسبقاً أو لا اتصال';
    });
    if (ok) {
      Haptics.success();
      _code.clear();
      _name.clear();
      _strength.clear();
      _form.clear();
      _hints = [];
      _loadRecent();
    } else {
      Haptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        _card(isDark, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 15, letterSpacing: 0.8),
                  decoration: InputDecoration(
                    labelText: 'رقم الباركود',
                    labelStyle: const TextStyle(fontSize: 12.5),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton(
                tooltip: 'اقرأ من العلبة',
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.10),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              onChanged: _suggestName,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'اسم الدواء بالإنكليزية',
                labelStyle: const TextStyle(fontSize: 12.5),
                hintText: 'اكتب حرفين ليظهر الاقتراح من قاعدة الأدوية',
                hintStyle: const TextStyle(fontSize: 11.5),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_hints.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (final h in _hints)
                  InkWell(
                    onTap: () {
                      Haptics.tap();
                      _name.text = h;
                      setState(() => _hints = []);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.22)),
                      ),
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _strength,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'التركيز',
                    hintText: '500 mg',
                    labelStyle: const TextStyle(fontSize: 12.5),
                    hintStyle: const TextStyle(fontSize: 11.5),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _form,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'الشكل',
                    hintText: 'Tablet',
                    labelStyle: const TextStyle(fontSize: 12.5),
                    hintStyle: const TextStyle(fontSize: 11.5),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_rounded, size: 19),
                label: const Text('أضف إلى القاعدة',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ),
            if (_msg != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_msgOk ? AppColors.successGreen : AppColors.errorRed)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(_msg!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _msgOk
                            ? AppColors.successGreen
                            : AppColors.errorRed)),
              ),
            ],
          ],
        )),
        if (_recent.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 9),
            child: Text('آخر ما أُضيف',
                style:
                    TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          ),
          for (final h in _recent) _recentTile(h, isDark, theme),
        ],
      ],
    );
  }

  Widget _recentTile(BarcodeHit h, bool isDark, ThemeData theme) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : const Color(0xFFECEFF2)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(h.barcode,
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'احذف',
            onPressed: () async {
              Haptics.heavy();
              await BarcodeService.instance.remove(h.barcode);
              _loadRecent();
            },
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.errorRed),
          ),
        ]),
      );

  Widget _card(bool isDark, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// لصق دفعة
// ════════════════════════════════════════════════════════════════════════

class _BulkTab extends StatefulWidget {
  const _BulkTab();

  @override
  State<_BulkTab> createState() => _BulkTabState();
}

class _BulkTabState extends State<_BulkTab> {
  final _text = TextEditingController();
  bool _busy = false;
  int? _added;
  List<String> _bad = [];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _added = null;
      _bad = [];
    });
    final (n, bad) = await BarcodeService.instance.importLines(_text.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _added = n;
      _bad = bad;
    });
    if (n > 0) {
      Haptics.celebrate();
      _text.clear();
    } else {
      Haptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سطر لكل دواء',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                  'الرقم ثم الاسم ثم التركيز ثم الشكل، بينها فاصلة. '
                  'التركيز والشكل اختياريان. يُلصق مباشرة من عمود Excel',
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.75,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.25)
                      : const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                    '6251107013026, Panadol, 500 mg, Tablet\n'
                    '8901302097618, Augmentin, 1 g, Tablet\n'
                    '4262422540014, Nexium, 40 mg, Capsule',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.9,
                        fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          maxLines: 12,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 13, height: 1.6),
          decoration: InputDecoration(
            hintText: 'الصق هنا',
            hintStyle: const TextStyle(fontSize: 12.5),
            alignLabelWithHint: true,
            filled: true,
            fillColor: isDark ? theme.colorScheme.surface : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _run,
            icon: _busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_rounded, size: 19),
            label: const Text('أضف الدفعة',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
        if (_added != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('أُضيف $_added رقماً',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen)),
          ),
        ],
        if (_bad.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.warningAmber.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_bad.length} سطراً لم يُقبل',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningAmber)),
                const SizedBox(height: 7),
                for (final b in _bad.take(25))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(b,
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// اقتراحات المستخدمين
// ════════════════════════════════════════════════════════════════════════

class _SuggestionsTab extends StatefulWidget {
  const _SuggestionsTab();

  @override
  State<_SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<_SuggestionsTab> {
  List<Map<String, dynamic>>? _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await BarcodeService.instance.pendingSubmissions();
      if (mounted) setState(() => _rows = r);
    } catch (_) {
      if (mounted) setState(() => _rows = []);
    }
  }

  Future<void> _accept(Map<String, dynamic> r) async {
    final ok = await BarcodeService.instance.submit(
      barcode: '${r['barcode']}',
      name: '${r['suggested_name']}',
      form: '${r['dosage_form'] ?? ''}',
      strength: '${r['strength'] ?? ''}',
    );
    await BarcodeService.instance
        .setSubmissionStatus(r['id'], ok ? 'accepted' : 'rejected');
    Haptics.success();
    _load();
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    await BarcodeService.instance.setSubmissionStatus(r['id'], 'rejected');
    Haptics.heavy();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rows   = _rows;

    if (rows == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined,
                size: 50,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 14),
            Text('لا اقتراحات بانتظار المراجعة',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final r = rows[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFFECEFF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['suggested_name']}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(
                    [
                      '${r['barcode']}',
                      if ('${r['strength'] ?? ''}'.isNotEmpty)
                        '${r['strength']}',
                      if ('${r['dosage_form'] ?? ''}'.isNotEmpty)
                        '${r['dosage_form']}',
                    ].join('  ·  '),
                    style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.4,
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 11),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _accept(r),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('اعتمد',
                          style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.successGreen,
                        side: BorderSide(
                            color: AppColors.successGreen.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(r),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('ارفض',
                          style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: BorderSide(
                            color: AppColors.errorRed.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
