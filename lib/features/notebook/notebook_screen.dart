import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database_helper.dart';
import '../../providers/notebook_provider.dart';
import '../../services/auth_service.dart';
import '../barcode/barcode_resolver.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

/// سجلّ نواقص الصيدلية.
///
/// الصيدلاني يكتشف النقص وهو واقف عند الرفّ أمام مريض، لا وهو جالس على
/// الحاسوب. لذلك ثلاث طرق للإضافة في ثانية واحدة: يكتب حرفين فيأتيه
/// الاسم من قاعدة الأدوية، أو يقرأ الباركود، أو يصوّر العلبة ويُكمل
/// الاسم لاحقاً. ثم يُرسل القائمة للمندوب بضغطة واحدة.
class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key});

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  List<String> _hints = [];
  ShortageStatus _newStatus = ShortageStatus.out;
  ShortageStatus? _filter;

  @override
  void initState() {
    super.initState();
    AuthService.instance.incrementToolUsage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'notebook');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── الإكمال التلقائي من قاعدة الأدوية المحلّية ────────────────────

  Future<void> _suggest(String q) async {
    if (q.trim().length < 2) {
      if (_hints.isNotEmpty) setState(() => _hints = []);
      return;
    }
    final r = await DatabaseHelper.instance.searchNames(q, limit: 7);
    if (mounted) setState(() => _hints = r);
  }

  void _add([String? name]) {
    final text = (name ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    Haptics.success();
    ref.read(notebookProvider.notifier).add(text, status: _newStatus);
    _ctrl.clear();
    setState(() => _hints = []);
    _focus.requestFocus();
  }

  // ── الإضافة بالباركود ─────────────────────────────────────────────

  Future<void> _addByScan() async {
    final code = await BarcodeResolver.scan(context);
    if (code == null || code.trim().isEmpty || !mounted) return;
    final name = await BarcodeResolver.resolve(context, code);
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      ref
          .read(notebookProvider.notifier)
          .add(name, status: _newStatus, barcode: code);
    } else {
      // رقم لم يُسنَد: نسجّله برقمه كي لا يضيع، والاسم يُكمل لاحقاً
      ref.read(notebookProvider.notifier).add('',
          status: _newStatus, barcode: code, note: 'باركود $code');
    }
  }

  // ── الإضافة بالصورة ───────────────────────────────────────────────

  Future<void> _addByPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text((context.s.isAr ? 'التقط صورة الآن' : 'Take a photo')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text((context.s.isAr ? 'اختر من المعرض' : 'Choose from gallery')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (src == null) return;
    final x = await ImagePicker()
        .pickImage(source: src, imageQuality: 70, maxWidth: 1400);
    if (x == null || !mounted) return;
    ref.read(notebookProvider.notifier).add(
          _ctrl.text.trim(),
          status: _newStatus,
          photoPath: x.path,
        );
    _ctrl.clear();
    setState(() => _hints = []);
  }

  // ── إكمال اسم سجل مصوّر ───────────────────────────────────────────

  Future<void> _completeName(NoteEntry e) async {
    final ctrl = TextEditingController(text: e.text);
    List<String> hints = [];
    final name = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, set) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(context.s.completeName,
              style: const TextStyle(fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              onChanged: (q) async {
                if (q.trim().length < 2) {
                  set(() => hints = []);
                  return;
                }
                final r =
                    await DatabaseHelper.instance.searchNames(q, limit: 6);
                set(() => hints = r);
              },
              decoration: InputDecoration(
                hintText: context.s.shortageHint,
                hintStyle: const TextStyle(fontSize: 12.5),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (hints.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final h in hints)
                  InkWell(
                    onTap: () {
                      ctrl.text = h;
                      set(() => hints = []);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ),
              ]),
            ],
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.s.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(context.s.addLabel),
            ),
          ],
        );
      }),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      ref.read(notebookProvider.notifier).edit(e.id, text: name);
    }
  }

  // ── إرسال القائمة ─────────────────────────────────────────────────

  Future<void> _send(List<NoteEntry> all) async {
    final out = all.where((e) => e.status == ShortageStatus.out).toList();
    final low = all.where((e) => e.status == ShortageStatus.low).toList();
    if (out.isEmpty && low.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.noPendingItems)));
      }
      return;
    }

    final d = DateTime.now();
    final b = StringBuffer()
      ..writeln('${context.s.shortageList}  ${d.day}/${d.month}/${d.year}')
      ..writeln();
    if (out.isNotEmpty) {
      b.writeln('${context.s.statusOut}:');
      for (final e in out) {
        b.writeln('• ${_lineOf(e)}');
      }
      b.writeln();
    }
    if (low.isNotEmpty) {
      b.writeln('${context.s.statusLow}:');
      for (final e in low) {
        b.writeln('• ${_lineOf(e)}');
      }
      b.writeln();
    }
    b.writeln('_Iraq Pharma Guide_');

    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(b.toString())}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.whatsappError)));
    }
  }

  String _lineOf(NoteEntry e) {
    final name = e.text.trim().isEmpty
        ? (e.barcode != null ? 'باركود ${e.barcode}' : (context.s.isAr ? 'بلا اسم' : 'Unnamed'))
        : e.text.trim();
    return e.note.trim().isEmpty ? name : '$name  —  ${e.note.trim()}';
  }

  // ── البناء ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final entries = ref.watch(notebookProvider);

    final nOut = entries.where((e) => e.status == ShortageStatus.out).length;
    final nLow = entries.where((e) => e.status == ShortageStatus.low).length;
    final nOk  = entries.where((e) => e.isDone).length;

    final shown = _filter == null
        ? entries
        : entries.where((e) => e.status == _filter).toList();
    // النافد أولاً، ثم ما أوشك، ثم ما أُمّن
    final sorted = [...shown]..sort((a, b) {
      int rank(ShortageStatus s) => switch (s) {
            ShortageStatus.out       => 0,
            ShortageStatus.low       => 1,
            ShortageStatus.restocked => 2,
          };
      final r = rank(a.status).compareTo(rank(b.status));
      return r != 0 ? r : b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.s.notebook,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (nOk > 0)
            IconButton(
              tooltip: context.s.clearDone,
              onPressed: () =>
                  ref.read(notebookProvider.notifier).clearDone(),
              icon: const Icon(Icons.cleaning_services_outlined, size: 20),
            ),
        ],
      ),
      body: Column(children: [
        // ── عدّادات قابلة للتصفية ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(children: [
            _count(context.s.statusOut, nOut, AppColors.errorRed,
                ShortageStatus.out),
            const SizedBox(width: 8),
            _count(context.s.statusLow, nLow, AppColors.warningAmber,
                ShortageStatus.low),
            const SizedBox(width: 8),
            _count(context.s.statusRestocked, nOk, AppColors.successGreen,
                ShortageStatus.restocked),
          ]),
        ),

        // ── شريط الإضافة ─────────────────────────────────────────────
        _addBar(isDark),

        // ── الاقتراحات ───────────────────────────────────────────────
        if (_hints.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: Wrap(spacing: 7, runSpacing: 7, children: [
              for (final h in _hints)
                InkWell(
                  onTap: () => _add(h),
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
                    child: Row(children: [
                      const Icon(Icons.add_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(h,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ]),
                  ),
                ),
            ]),
          ),

        // ── القائمة ──────────────────────────────────────────────────
        Expanded(
          child: sorted.isEmpty
              ? _empty(theme)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => _card(sorted[i], isDark),
                ),
        ),
      ]),
      floatingActionButton: (nOut + nLow) > 0
          ? FloatingActionButton.extended(
              onPressed: () => _send(entries),
              backgroundColor: const Color(0xFF25D366),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text('${context.s.sendWhatsApp}  (${nOut + nLow})',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _count(String label, int n, Color c, ShortageStatus s) {
    final on = _filter == s;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = on ? null : s),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: c.withOpacity(on ? 0.18 : 0.07),
            borderRadius: BorderRadius.circular(13),
            border:
                Border.all(color: c.withOpacity(on ? 0.55 : 0.18)),
          ),
          child: Column(children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: c)),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: c)),
          ]),
        ),
      ),
    );
  }

  Widget _addBar(bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _suggest,
              onSubmitted: (_) => _add(),
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: context.s.shortageHint,
                hintStyle: const TextStyle(fontSize: 12.5),
                isDense: true,
                prefixIcon:
                    const Icon(Icons.medication_outlined, size: 19),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: context.s.addByScan,
            onPressed: _addByScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 21),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.10),
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: context.s.addByPhoto,
            onPressed: _addByPhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: 21),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.10),
              foregroundColor: AppColors.primary,
            ),
          ),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(
            child: _statusPick(context.s.statusOut, ShortageStatus.out,
                AppColors.errorRed),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statusPick(context.s.statusLow, ShortageStatus.low,
                AppColors.warningAmber),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(context.s.addLabel,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _statusPick(String label, ShortageStatus s, Color c) {
    final on = _newStatus == s;
    return InkWell(
      onTap: () {
        Haptics.select();
        setState(() => _newStatus = s);
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withOpacity(on ? 0.16 : 0.04),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: c.withOpacity(on ? 0.5 : 0.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 14, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.bold : FontWeight.w500,
                  color: c)),
        ]),
      ),
    );
  }

  Widget _card(NoteEntry e, bool isDark) {
    final theme = Theme.of(context);
    final (Color c, String label, IconData icon) = switch (e.status) {
      ShortageStatus.out => (
          AppColors.errorRed,
          context.s.statusOut,
          Icons.remove_shopping_cart_outlined
        ),
      ShortageStatus.low => (
          AppColors.warningAmber,
          context.s.statusLow,
          Icons.trending_down_rounded
        ),
      ShortageStatus.restocked => (
          AppColors.successGreen,
          context.s.statusRestocked,
          Icons.check_circle_outline_rounded
        ),
    };

    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        Haptics.heavy();
        ref.read(notebookProvider.notifier).remove(e.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.28)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Haptics.select();
              ref.read(notebookProvider.notifier).cycle(e.id);
            },
            onLongPress: () => _editNote(e),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(children: [
                if (e.photoPath != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(e.photoPath!),
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46,
                          height: 46,
                          color: c.withOpacity(0.10),
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 18, color: c),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 19, color: c),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          e.text.trim().isEmpty
                              ? context.s.photoNoName
                              : e.text,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontStyle: e.text.trim().isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            decoration: e.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: e.text.trim().isEmpty
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          )),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: c)),
                        ),
                        const SizedBox(width: 7),
                        Text(_ago(e.createdAt),
                            style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                      if (e.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(e.note,
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.5,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                if (e.text.trim().isEmpty)
                  TextButton(
                    onPressed: () => _completeName(e),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: Text(context.s.completeName,
                        style: const TextStyle(fontSize: 11.5)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editNote(NoteEntry e) async {
    final ctrl = TextEditingController(text: e.note);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(e.text.trim().isEmpty ? context.s.photoNoName : e.text,
            style: const TextStyle(fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: context.s.qtyNoteHint,
            hintStyle: const TextStyle(fontSize: 12),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.s.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(context.s.addLabel),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (v != null) ref.read(notebookProvider.notifier).edit(e.id, note: v);
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(context.s.emptyShortages,
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 9),
            Text(context.s.emptyShortagesSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.8,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return (context.s.isAr ? 'الآن' : 'Now');
    if (d.inMinutes < 60) return (context.s.isAr ? 'قبل ${d.inMinutes} دقيقة' : '${d.inMinutes} min ago');
    if (d.inHours < 24) return (context.s.isAr ? 'قبل ${d.inHours} ساعة' : '${d.inHours} h ago');
    if (d.inDays < 30) return (context.s.isAr ? 'قبل ${d.inDays} يوماً' : '${d.inDays} d ago');
    return '${dt.year}/${dt.month}/${dt.day}';
  }
}
