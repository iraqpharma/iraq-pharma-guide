import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/customer_card.dart';
import '../../providers/customers_provider.dart';
import '../../services/haptics_service.dart';
import '../../shared/widgets/section_intro.dart';

/// بطاقات الزبائن المتكرّرين.
///
/// المريض المزمن يراجع الصيدلية كل شهر ويسأل «شنو كان علاجي؟»، ويتوقّع
/// من الصيدلاني أن يتذكّر. هذه البطاقة تتذكّر بدله: العلاج والجرعة
/// وتاريخ آخر صرف ومتى يُتوقّع أن ينفد، فتعود إليه بكلمة واحدة.
///
/// كل شيء على الجهاز، لا يُرفع إلى أي خادم.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _q = '';
  bool _dueOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'customers');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final all    = ref.watch(customersProvider);
    final due    = ref.watch(dueCustomersProvider);

    var rows = _dueOnly ? due : all;
    if (_q.trim().isNotEmpty) {
      final q = _q.trim();
      rows = rows
          .where((c) =>
              c.name.contains(q) ||
              c.phone.contains(q) ||
              c.condition.contains(q) ||
              c.meds.any((m) =>
                  m.name.toLowerCase().contains(q.toLowerCase())))
          .toList();
    }
    rows = [...rows]..sort((a, b) {
      // المتأخّرون أولاً، ثم من اقترب موعده، ثم الأحدث زيارة
      int rank(CustomerCard c) =>
          c.isOverdue ? 0 : (c.isDueSoon ? 1 : 2);
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : b.lastVisit.compareTo(a.lastVisit);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('زبائني',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'عن هذا القسم',
            onPressed: () =>
                SectionIntro.showNow(context, id: 'customers'),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث باسم الزبون أو هاتفه أو دوائه',
              hintStyle: const TextStyle(fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
        if (due.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: InkWell(
              onTap: () {
                Haptics.select();
                setState(() => _dueOnly = !_dueOnly);
              },
              borderRadius: BorderRadius.circular(13),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber
                      .withOpacity(_dueOnly ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: AppColors.warningAmber
                          .withOpacity(_dueOnly ? 0.5 : 0.22)),
                ),
                child: Row(children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 18, color: AppColors.warningAmber),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                        '${due.length} زبوناً حان أو قرب موعد إعادة صرفه',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                  ),
                  Icon(
                      _dueOnly
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      size: 17,
                      color: AppColors.warningAmber),
                ]),
              ),
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? _empty(theme, all.isEmpty)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 96),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _card(rows[i], isDark, theme),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('زبون جديد',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── البطاقة ───────────────────────────────────────────────────────

  Widget _card(CustomerCard c, bool isDark, ThemeData theme) {
    final next = c.nextDue;
    final left = next?.daysLeft;
    final accent = c.isOverdue
        ? AppColors.errorRed
        : (c.isDueSoon ? AppColors.warningAmber : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (c.isOverdue || c.isDueSoon)
                ? accent.withOpacity(0.38)
                : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFECEFF2))),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _edit(c),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(_initials(c.name),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accent)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                            [
                              if (c.age != null) '${c.age} سنة',
                              if (c.condition.isNotEmpty) c.condition,
                              'آخر زيارة قبل ${c.daysSinceVisit} يوماً',
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (c.phone.trim().isNotEmpty)
                    IconButton(
                      tooltip: 'اتّصل',
                      onPressed: () => _call(c.phone),
                      icon: const Icon(Icons.phone_outlined,
                          size: 19, color: AppColors.primary),
                    ),
                ]),
                if (c.allergies.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.dangerous_outlined,
                          size: 15, color: AppColors.errorRed),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text('حساسية: ${c.allergies}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.errorRed)),
                      ),
                    ]),
                  ),
                ],
                if (c.meds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final m in c.meds.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                m.dose.trim().isEmpty
                                    ? m.name
                                    : '${m.name}  —  ${m.dose}',
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  if (c.meds.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(right: 13, top: 2),
                      child: Text('و${c.meds.length - 3} دواءً آخر',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                ],
                if (left != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          c.isOverdue
                              ? Icons.priority_high_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: accent),
                      const SizedBox(width: 6),
                      Text(
                          left < 0
                              ? 'تأخّر ${-left} يوماً عن ${next!.name}'
                              : (left == 0
                                  ? 'ينفد ${next!.name} اليوم'
                                  : 'يبقى $left يوماً من ${next!.name}'),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: accent)),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _visit(c),
                      icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                      label: const Text('سجّل زيارة وصرف',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.35)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'احذف البطاقة',
                    onPressed: () => _delete(c),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 19, color: AppColors.errorRed),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (p.isEmpty) return '؟';
    final l = p.toList();
    String head(String w) =>
        w.runes.isEmpty ? '' : String.fromCharCode(w.runes.first);
    return l.length == 1
        ? String.fromCharCodes(l.first.runes.take(2))
        : '${head(l[0])}${head(l[1])}';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.trim()}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── تسجيل زيارة ───────────────────────────────────────────────────

  Future<void> _visit(CustomerCard c) async {
    if (c.meds.isEmpty) {
      ref.read(customersProvider.notifier).recordVisit(c.id);
      Haptics.success();
      return;
    }
    final picked = <String>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ماذا صرفت له اليوم؟',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('ما تختاره يُحدّث تاريخ آخر صرف وموعد التذكير',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              for (final m in c.meds)
                CheckboxListTile(
                  dense: true,
                  value: picked.contains(m.name),
                  onChanged: (v) {
                    Haptics.select();
                    set(() => v == true
                        ? picked.add(m.name)
                        : picked.remove(m.name));
                  },
                  title: Text(m.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: m.dose.trim().isEmpty
                      ? null
                      : Text(m.dose,
                          style: const TextStyle(fontSize: 11.5)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('سجّل الزيارة',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ]),
          ),
        );
      }),
    );
    if (ok == true) {
      ref
          .read(customersProvider.notifier)
          .recordVisit(c.id, dispensed: picked);
      Haptics.success();
    }
  }

  Future<void> _delete(CustomerCard c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف البطاقة', style: TextStyle(fontSize: 16)),
        content: Text('ستُحذف بطاقة ${c.name} وكل أدويتها نهائياً',
            style: const TextStyle(fontSize: 13, height: 1.7)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white),
            child: const Text('احذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      Haptics.heavy();
      ref.read(customersProvider.notifier).remove(c.id);
    }
  }

  Future<void> _edit(CustomerCard? existing) async {
    final saved = await Navigator.of(context).push<CustomerCard>(
      MaterialPageRoute(builder: (_) => _CustomerEditor(card: existing)),
    );
    if (saved == null) return;
    final n = ref.read(customersProvider.notifier);
    existing == null ? n.add(saved) : n.update(saved);
    Haptics.success();
  }

  Widget _empty(ThemeData theme, bool noneAtAll) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(noneAtAll ? 'لا بطاقات بعد' : 'لا نتائج',
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 9),
            Text(
                noneAtAll
                    ? 'سجّل زبونك المزمن الأول: اسمه وعلاجه وجرعته،\n'
                        'فيذكّرك التطبيق بموعده في كل زيارة'
                    : 'جرّب كلمة أخرى',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.8,
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════
// محرّر البطاقة
// ════════════════════════════════════════════════════════════════════════

class _CustomerEditor extends StatefulWidget {
  final CustomerCard? card;
  const _CustomerEditor({this.card});

  @override
  State<_CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends State<_CustomerEditor> {
  late final _name      = TextEditingController(text: widget.card?.name ?? '');
  late final _phone     = TextEditingController(text: widget.card?.phone ?? '');
  late final _age       =
      TextEditingController(text: widget.card?.age?.toString() ?? '');
  late final _condition =
      TextEditingController(text: widget.card?.condition ?? '');
  late final _allergies =
      TextEditingController(text: widget.card?.allergies ?? '');
  late final _note      = TextEditingController(text: widget.card?.note ?? '');

  late List<CustomerMed> _meds = [...(widget.card?.meds ?? const [])];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    _condition.dispose();
    _allergies.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.length < 2) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب اسم الزبون')));
      return;
    }
    final now = DateTime.now();
    final c = widget.card == null
        ? CustomerCard(
            id: now.microsecondsSinceEpoch.toString(),
            name: n,
            phone: _phone.text.trim(),
            age: int.tryParse(_age.text.trim()),
            condition: _condition.text.trim(),
            allergies: _allergies.text.trim(),
            note: _note.text.trim(),
            meds: _meds,
            createdAt: now,
            lastVisit: now,
          )
        : widget.card!.copyWith(
            name: n,
            phone: _phone.text.trim(),
            age: int.tryParse(_age.text.trim()),
            condition: _condition.text.trim(),
            allergies: _allergies.text.trim(),
            note: _note.text.trim(),
            meds: _meds,
          );
    Navigator.of(context).pop(c);
  }

  Future<void> _addMed([int? index]) async {
    final m = await showModalBottomSheet<CustomerMed>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedSheet(med: index == null ? null : _meds[index]),
    );
    if (m == null) return;
    setState(() {
      if (index == null) {
        _meds = [..._meds, m];
      } else {
        _meds = [..._meds]..[index] = m;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.card == null ? 'زبون جديد' : 'تعديل البطاقة',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('حفظ',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _card(isDark, Column(children: [
            _field(_name, 'اسم الزبون'),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(
                  child: _field(_phone, 'الهاتف',
                      keyboard: TextInputType.phone)),
              const SizedBox(width: 10),
              SizedBox(
                  width: 90,
                  child: _field(_age, 'العمر',
                      keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 11),
            _field(_condition, 'الحالة المزمنة',
                hint: 'سكري، ضغط، ربو'),
            const SizedBox(height: 11),
            _field(_allergies, 'حساسية معروفة',
                hint: 'بنسلين، أسبرين'),
            const SizedBox(height: 11),
            _field(_note, 'ملاحظة', lines: 2),
          ])),
          const SizedBox(height: 14),
          _card(isDark, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                  child: Text('أدويته',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () => _addMed(),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('أضف دواء',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ]),
              if (_meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                      'لم تُضف أدوية بعد. الدواء مع جرعته وعدد أيام العلبة '
                      'هو ما يجعل التذكير ممكناً',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.75,
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              else
                for (var i = 0; i < _meds.length; i++)
                  _medTile(i, _meds[i], isDark, theme),
            ],
          )),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: AppColors.successGreen.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 17, color: AppColors.successGreen),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                    'هذه البطاقة محفوظة على هاتفك وحده ولا تُرفع إلى أي '
                    'خادم. معلومات المرضى أمانة، ومكانها جهازك لا الإنترنت',
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.75,
                        color: theme.colorScheme.onSurface)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _medTile(int i, CustomerMed m, bool isDark, ThemeData theme) =>
      Container(
        margin: const EdgeInsets.only(top: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.bold)),
                if (m.dose.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(m.dose,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 2),
                Text('العلبة تكفي ${m.packDays} يوماً',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addMed(i),
            icon: const Icon(Icons.edit_outlined, size: 17),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () {
              Haptics.heavy();
              setState(() => _meds = [..._meds]..removeAt(i));
            },
            icon: const Icon(Icons.close_rounded,
                size: 17, color: AppColors.errorRed),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      );

  Widget _field(TextEditingController c, String label,
      {String? hint, int lines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12.5),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11.5),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
// إضافة دواء إلى البطاقة
// ════════════════════════════════════════════════════════════════════════

class _MedSheet extends StatefulWidget {
  final CustomerMed? med;
  const _MedSheet({this.med});

  @override
  State<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends State<_MedSheet> {
  late final _name = TextEditingController(text: widget.med?.name ?? '');
  late final _dose = TextEditingController(text: widget.med?.dose ?? '');
  late final _note = TextEditingController(text: widget.med?.note ?? '');
  late int _packDays = widget.med?.packDays ?? 30;

  List<String> _hints = [];

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _suggest(String q) async {
    if (q.trim().length < 2) {
      if (_hints.isNotEmpty) setState(() => _hints = []);
      return;
    }
    final r = await DatabaseHelper.instance.searchNames(q, limit: 6);
    if (mounted) setState(() => _hints = r);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.med == null ? 'أضف دواء' : 'تعديل الدواء',
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: _suggest,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'اسم الدواء',
                  labelStyle: const TextStyle(fontSize: 12.5),
                  hintText: 'اكتب حرفين ليظهر الاقتراح',
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
                            horizontal: 10, vertical: 6),
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
              TextField(
                controller: _dose,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'الجرعة',
                  hintText: 'قرص صباحاً ومساءً بعد الأكل',
                  labelStyle: const TextStyle(fontSize: 12.5),
                  hintStyle: const TextStyle(fontSize: 11.5),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  hintText: 'لا يُؤخذ مع الحليب',
                  labelStyle: const TextStyle(fontSize: 12.5),
                  hintStyle: const TextStyle(fontSize: 11.5),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              const Text('العلبة تكفي',
                  style:
                      TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('على أساسه يُحسب موعد إعادة الصرف',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 9),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (final d in [7, 14, 20, 28, 30, 60, 90])
                  ChoiceChip(
                    label: Text('$d يوماً',
                        style: const TextStyle(fontSize: 12)),
                    selected: _packDays == d,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _packDays = d);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.16),
                    backgroundColor: Colors.transparent,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        color: _packDays == d
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: _packDays == d
                            ? FontWeight.bold
                            : FontWeight.normal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: BorderSide(
                          color: _packDays == d
                              ? AppColors.primary.withOpacity(0.4)
                              : (isDark
                                  ? Colors.white24
                                  : const Color(0xFFDFE4E8))),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final n = _name.text.trim();
                      if (n.length < 2) {
                        Haptics.error();
                        return;
                      }
                      Navigator.pop(
                        context,
                        CustomerMed(
                          name: n,
                          dose: _dose.text.trim(),
                          note: _note.text.trim(),
                          packDays: _packDays,
                          lastDispensed:
                              widget.med?.lastDispensed ?? DateTime.now(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('حفظ الدواء',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
