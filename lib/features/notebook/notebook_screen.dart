import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notebook_provider.dart';

class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key});

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    ref.read(notebookProvider.notifier).add(text);
    _ctrl.clear();
    _focusNode.requestFocus();
  }

  Future<void> _sendWhatsApp(List<NoteEntry> entries) async {
    final pending =
        entries.where((e) => !e.isDone).toList();
    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('لا توجد عناصر غير مكتملة للإرسال')),
        );
      }
      return;
    }

    final date = DateTime.now();
    final dateStr =
        '${date.day}/${date.month}/${date.year}';
    final lines = pending
        .map((e) => '• ${e.text}')
        .join('\n');
    final message =
        'قائمة الأدوية المفقودة - $dateStr\n\n$lines\n\n_أُرسلت من Iraq Pharma Guide_';

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تعذّر فتح واتساب. تأكد من تثبيته.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(notebookProvider);
    final pendingCount = entries.where((e) => !e.isDone).length;
    final doneCount = entries.where((e) => e.isDone).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('دفتر الصيدلاني'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (doneCount > 0)
            TextButton.icon(
              onPressed: () => ref
                  .read(notebookProvider.notifier)
                  .clearDone(),
              icon: const Icon(Icons.done_all,
                  color: Colors.white70, size: 18),
              label: const Text('مسح المكتملة',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats header ───────────────────────────────────────────────
          _StatsHeader(
              total: entries.length,
              pending: pendingCount,
              done: doneCount),

          // ── Input area ─────────────────────────────────────────────────
          _InputBar(ctrl: _ctrl, focusNode: _focusNode, onAdd: _add),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: entries.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _NoteCard(entry: entries[i]),
                  ),
          ),
        ],
      ),

      // ── WhatsApp FAB ───────────────────────────────────────────────────
      floatingActionButton: pendingCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _sendWhatsApp(entries),
              backgroundColor: const Color(0xFF25D366),
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                'إرسال ($pendingCount) عبر واتساب',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ─── Stats header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int total, pending, done;
  const _StatsHeader(
      {required this.total,
      required this.pending,
      required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _StatChip(label: 'الكل', value: total, color: Colors.white),
          const SizedBox(width: 10),
          _StatChip(
              label: 'مفقود',
              value: pending,
              color: const Color(0xFFFFE082)),
          const SizedBox(width: 10),
          _StatChip(
              label: 'تم',
              value: done,
              color: const Color(0xFF80CBC4)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  const _InputBar(
      {required this.ctrl,
      required this.focusNode,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              decoration: InputDecoration(
                hintText: 'اسم الدواء المفقود...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                isDense: true,
                prefixIcon: const Icon(Icons.medication_outlined,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
            ),
            child: const Text('إضافة',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Note card ────────────────────────────────────────────────────────────────

class _NoteCard extends ConsumerWidget {
  final NoteEntry entry;
  const _NoteCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(notebookProvider.notifier).remove(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.isDone
                ? AppColors.successGreen.withOpacity(0.3)
                : AppColors.warningAmber.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () =>
                ref.read(notebookProvider.notifier).toggle(entry.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.isDone
                    ? AppColors.successGreen
                    : Colors.transparent,
                border: Border.all(
                  color: entry.isDone
                      ? AppColors.successGreen
                      : AppColors.warningAmber,
                  width: 2,
                ),
              ),
              child: entry.isDone
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            entry.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: entry.isDone
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: entry.isDone
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            _timeAgo(entry.createdAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: entry.isDone
              ? const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 20)
              : const Icon(Icons.radio_button_unchecked,
                  color: AppColors.warningAmber, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
                color: AppColors.lightBlue, shape: BoxShape.circle),
            child: const Icon(Icons.edit_note_rounded,
                size: 44, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 20),
          const Text('الدفتر فارغ',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text(
            'أضف أسماء الأدوية المفقودة\nثم أرسلها مباشرة عبر واتساب',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
