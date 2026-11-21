import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/governorate_style.dart';
import '../../data/models/availability_post.dart';
import '../../services/availability_service.dart';
import '../../services/jobs_service.dart';
import '../../shared/widgets/section_intro.dart';

/// «وين أحصّله؟» — دليل توفّر الأدوية في الصيدليات.
///
/// المشكلة التي يحلّها: دواء ناقص من السوق يحتاجه مريض، فيضيع الصيدلاني
/// ساعة على الهاتف يسأل الصيدليات. هنا يكتب اسم الدواء فيرى من أعلن
/// عن توفّره وفي أي محافظة، ويتّصل مباشرة.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _searchCtrl = TextEditingController();
  String _city  = '';
  String _query = '';
  late Future<List<AvailabilityPost>> _future;
  late Future<Map<String, int>> _counts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'availability');
    });
    _future = AvailabilityService.instance.listLive();
    _counts = AvailabilityService.instance.cityCounts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload({bool withCounts = false}) {
    setState(() {
      _future = AvailabilityService.instance.listLive(
        city: _city.isEmpty ? null : _city,
        query: _query.isEmpty ? null : _query,
      );
      if (withCounts) _counts = AvailabilityService.instance.cityCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('توفّر الأدوية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'إعلاناتي',
            icon: const Icon(Icons.inventory_2_outlined, size: 21),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MyAvailabilityScreen()));
              _reload(withCounts: true);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const AvailabilityFormSheet(),
          );
          if (added == true) _reload(withCounts: true);
        },
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text('أعلن عن توفّر دواء',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
      ),
      body: Column(children: [
        // ── البحث ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              _reload();
            },
            onChanged: (v) => _query = v.trim(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اكتب اسم الدواء الذي تبحث عنه…',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _query = '';
                        FocusScope.of(context).unfocus();
                        _reload();
                      },
                    ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: theme.dividerColor.withOpacity(0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: theme.dividerColor.withOpacity(0.4)),
              ),
            ),
          ),
        ),

        // ── المحافظات ───────────────────────────────────────────────────
        FutureBuilder<Map<String, int>>(
          future: _counts,
          builder: (_, snap) {
            final counts = snap.data ?? const <String, int>{};
            final cities = [...JobsService.iraqCities]..sort(
                (a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
            final shown = cities.where((c) => (counts[c] ?? 0) > 0).toList();
            if (shown.isEmpty) return const SizedBox(height: 4);
            return SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                children: [
                  _cityPill('الكل', Icons.public_rounded, AppColors.primary,
                      counts.values.fold<int>(0, (p, v) => p + v), ''),
                  for (final c in shown)
                    _cityPill(c, null, GovStyle.of(c).color,
                        counts[c] ?? 0, c),
                ],
              ),
            );
          },
        ),

        // ── القائمة ─────────────────────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<AvailabilityPost>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _msg(Icons.wifi_off_rounded, 'تعذّر التحميل',
                    'تأكّد من الاتصال بالإنترنت');
              }
              final list = snap.data ?? const <AvailabilityPost>[];
              if (list.isEmpty) {
                return _msg(
                  Icons.inventory_2_outlined,
                  _query.isEmpty
                      ? 'لا إعلانات توفّر حالياً'
                      : 'لا أحد أعلن عن «$_query»',
                  'إن كان الدواء متوفّراً عندك فأعلن عنه، يصل خبره لكل '
                      'صيدلاني يبحث عنه',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(withCounts: true),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 96),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      AvailabilityCard(post: list[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _cityPill(
      String label, IconData? icon, Color color, int count, String value) {
    final active = _city == value;
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() => _city = active ? '' : value);
          _reload();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: active ? color : Colors.transparent,
            border: Border.all(
                color: active
                    ? color
                    : Theme.of(context).dividerColor.withOpacity(0.45)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null)
              Icon(icon, size: 14, color: active ? Colors.white : color),
            if (icon != null) const SizedBox(width: 5),
            Text('$label  $count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  color: active
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _msg(IconData icon, String title, String body) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.07),
              ),
              child: Icon(icon,
                  size: 34, color: AppColors.primary.withOpacity(0.55)),
            ),
            const SizedBox(height: 13),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// البطاقة
// ═══════════════════════════════════════════════════════════════════════════════

class AvailabilityCard extends StatelessWidget {
  final AvailabilityPost post;
  final bool showStatus;
  const AvailabilityCard({
    super.key,
    required this.post,
    this.showStatus = false,
  });

  Future<void> _dial(String raw) async {
    final uri = Uri.parse('tel:${raw.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String raw) async {
    var n = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.startsWith('0')) n = '964${n.substring(1)}';
    final uri = Uri.parse('https://wa.me/$n');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gov    = GovStyle.of(post.city);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: gov.color.withOpacity(0.13),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(post.titleLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    GovMark(city: post.city, compact: true),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.local_pharmacy_outlined,
                        size: 12.5, color: gov.color),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('${post.pharmacyName} · ${post.locationAr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: gov.color)),
                    ),
                  ]),
                ],
              ),
            ),
            if (showStatus) _statusPill(post.status),
          ]),

          const SizedBox(height: 9),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (post.formLine.isNotEmpty)
              _tag(context, post.formLine, Icons.medication_outlined, null),
            _tag(
                context,
                post.priceAr,
                post.priceIqd == null
                    ? Icons.help_outline_rounded
                    : Icons.payments_rounded,
                post.priceIqd == null
                    ? AppColors.warningAmber
                    : AppColors.successGreen),
            if (post.daysLeft > 0 && post.status == 'approved')
              _tag(context, 'ينتهي بعد ${post.daysLeft} يوماً',
                  Icons.event_busy_outlined, null),
          ]),

          if (post.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: cs.onSurface.withOpacity(0.85))),
          ],

          const SizedBox(height: 8),
          Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF1F3F5)),
          Row(children: [
            Text(post.agoAr,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const Spacer(),
            if (post.contactWhatsapp.isNotEmpty)
              TextButton.icon(
                onPressed: () => _whatsapp(post.contactWhatsapp),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text('واتساب', style: TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF25A366),
                    visualDensity: VisualDensity.compact),
              ),
            TextButton.icon(
              onPressed: () => _dial(post.contactPhone),
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: const Text('اتصال', style: TextStyle(fontSize: 12.5)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _tag(
      BuildContext context, String text, IconData icon, Color? color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: color == null
                ? (isDark
                    ? Colors.white.withOpacity(0.10)
                    : const Color(0xFFE7EBEF))
                : c.withOpacity(0.32)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.5, color: c),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color == null
                    ? Theme.of(context).colorScheme.onSurface
                    : c)),
      ]),
    );
  }

  Widget _statusPill(String status) {
    const map = <String, List<dynamic>>{
      'pending':  ['بانتظار المراجعة', AppColors.warningAmber],
      'approved': ['منشور', AppColors.successGreen],
      'rejected': ['مرفوض', AppColors.errorRed],
      'closed':   ['مغلق', Colors.grey],
      'expired':  ['منتهٍ', Colors.grey],
    };
    final v = map[status] ?? ['—', Colors.grey];
    final color = v[1] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(v[0] as String,
          style: TextStyle(
              fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// نموذج الإعلان
// ═══════════════════════════════════════════════════════════════════════════════

class AvailabilityFormSheet extends StatefulWidget {
  final String initialDrugName;
  const AvailabilityFormSheet({super.key, this.initialDrugName = ''});

  @override
  State<AvailabilityFormSheet> createState() => _AvailabilityFormSheetState();
}

class _AvailabilityFormSheetState extends State<AvailabilityFormSheet> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _drug;
  final _pharmacy = TextEditingController();
  final _area     = TextEditingController();
  final _strength = TextEditingController();
  final _form     = TextEditingController();
  final _qty      = TextEditingController();
  final _price    = TextEditingController();
  final _notes    = TextEditingController();
  final _phone    = TextEditingController();
  final _whatsapp = TextEditingController();

  String _city = 'بغداد';
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drug = TextEditingController(text: widget.initialDrugName);
  }

  @override
  void dispose() {
    for (final c in [
      _drug, _pharmacy, _area, _strength, _form, _qty, _price, _notes,
      _phone, _whatsapp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      await AvailabilityService.instance.create(AvailabilityPost(
        id: 0,
        pharmacyName: _pharmacy.text.trim(),
        city: _city,
        area: _area.text.trim(),
        drugName: _drug.text.trim(),
        dosageForm: _form.text.trim(),
        strength: _strength.text.trim(),
        quantityNote: _qty.text.trim(),
        priceIqd: int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')),
        notes: _notes.text.trim(),
        contactPhone: _phone.text.trim(),
        contactWhatsapp: _whatsapp.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('وصل إعلانك، يظهر بعد موافقة الإدارة'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر الإرسال، تأكّد من تسجيل الدخول والاتصال';
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أعلن عن توفّر دواء',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  'يظهر إعلانك بعد موافقة الإدارة ويسري 30 يوماً'
                  'ويمكنك إغلاقه عند نفاد الكمية',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),

              _f(_drug, 'اسم الدواء *', 'مثال: Insulin glargine',
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'أدخل اسم الدواء'
                      : null),
              Row(children: [
                Expanded(child: _f(_strength, 'التركيز', '100 IU/mL')),
                const SizedBox(width: 10),
                Expanded(child: _f(_form, 'الشكل', 'قلم / حبوب')),
              ]),
              _f(_qty, 'الكمية المتوفّرة', 'مثال: 5 علب'),
              _f(_price, 'السعر بالدينار', 'اتركه فارغاً إن كان عند الاتصال',
                  keyboard: TextInputType.number),

              const SizedBox(height: 6),
              _f(_pharmacy, 'اسم الصيدلية *', 'صيدلية الشفاء',
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'أدخل اسم الصيدلية'
                      : null),
              DropdownButtonFormField<String>(
                initialValue: _city,
                isExpanded: true,
                decoration: _dec('المحافظة *', null),
                items: JobsService.iraqCities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v ?? 'بغداد'),
              ),
              const SizedBox(height: 12),
              _f(_area, 'المنطقة', 'الكرادة'),

              _f(_phone, 'رقم الهاتف *', '07xxxxxxxxx',
                  keyboard: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'أدخل رقماً صحيحاً'
                      : null),
              _f(_whatsapp, 'واتساب (اختياري)', '07xxxxxxxxx',
                  keyboard: TextInputType.phone),
              _f(_notes, 'ملاحظات', 'تاريخ الانتهاء، شرط الحفظ، أي تفصيل مفيد',
                  lines: 3),

              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.errorRed, fontSize: 12)),
              ],

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_sending ? 'جاري الإرسال…' : 'إرسال الإعلان',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, String? hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        labelStyle: const TextStyle(fontSize: 13),
        alignLabelWithHint: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.4)),
      );

  Widget _f(
    TextEditingController c,
    String label,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int lines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          validator: validator,
          keyboardType: keyboard,
          maxLines: lines,
          minLines: lines,
          style: const TextStyle(fontSize: 14),
          decoration: _dec(label, hint),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// إعلاناتي
// ═══════════════════════════════════════════════════════════════════════════════

class MyAvailabilityScreen extends StatefulWidget {
  const MyAvailabilityScreen({super.key});

  @override
  State<MyAvailabilityScreen> createState() => _MyAvailabilityScreenState();
}

class _MyAvailabilityScreenState extends State<MyAvailabilityScreen> {
  late Future<List<AvailabilityPost>> _future =
      AvailabilityService.instance.listMine();

  void _reload() =>
      setState(() => _future = AvailabilityService.instance.listMine());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعلانات التوفّر الخاصة بي')),
      body: FutureBuilder<List<AvailabilityPost>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? const <AvailabilityPost>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text('لم تنشر إعلاناً بعد',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              for (final p in list) ...[
                AvailabilityCard(post: p, showStatus: true),
                if (p.status == 'rejected' && p.rejectReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, right: 6),
                    child: Text('سبب الرفض: ${p.rejectReason}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.errorRed)),
                  ),
                if (p.status == 'approved')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await AvailabilityService.instance.close(p.id);
                          _reload();
                        },
                        icon: const Icon(Icons.inventory_rounded, size: 16),
                        label: const Text('نفدت الكمية، أغلق الإعلان',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
