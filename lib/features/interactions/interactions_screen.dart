import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';
import '../../providers/interaction_provider.dart';

class InteractionsScreen extends ConsumerWidget {
  const InteractionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drugs = ref.watch(checkerDrugsProvider);
    final interactions = findInteractions(drugs);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('فاحص التفاعلات الدوائية'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (drugs.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(checkerDrugsProvider.notifier).clear(),
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              label: const Text('مسح الكل',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Drug picker strip ──────────────────────────────────────────
          _DrugPickerStrip(drugs: drugs),

          // ── Results ────────────────────────────────────────────────────
          Expanded(
            child: drugs.isEmpty
                ? const _EmptyState()
                : drugs.length == 1
                    ? const _OnedrugState()
                    : _ResultsSection(
                        drugs: drugs,
                        interactions: interactions,
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Drug picker strip ────────────────────────────────────────────────────────

class _DrugPickerStrip extends ConsumerWidget {
  final List<Drug> drugs;
  const _DrugPickerStrip({required this.drugs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('أضف الأدوية للفحص (2-8 أدوية)',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SearchAddButton(
                  onDrugSelected: (drug) =>
                      ref.read(checkerDrugsProvider.notifier).add(drug),
                ),
              ),
            ],
          ),
          if (drugs.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: drugs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _DrugChip(drug: drugs[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchAddButton extends ConsumerStatefulWidget {
  final ValueChanged<Drug> onDrugSelected;
  const _SearchAddButton({required this.onDrugSelected});

  @override
  ConsumerState<_SearchAddButton> createState() => _SearchAddButtonState();
}

class _SearchAddButtonState extends ConsumerState<_SearchAddButton> {
  final _ctrl = TextEditingController();
  List<Drug> _results = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    final drugs = await ref.read(drugRepositoryProvider).search(q);
    if (mounted) setState(() => _results = drugs.take(6).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن دواء للإضافة...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon:
                const Icon(Icons.search, color: Colors.white70, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          onChanged: (v) {
            setState(() => _searching = v.isNotEmpty);
            _search(v);
          },
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15), blurRadius: 8)
              ],
            ),
            child: Column(
              children: _results
                  .map((d) => ListTile(
                        dense: true,
                        title: Text(d.genericName,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: d.drugClass.isNotEmpty
                            ? Text(d.drugClass,
                                style: const TextStyle(fontSize: 11))
                            : null,
                        onTap: () {
                          widget.onDrugSelected(d);
                          _ctrl.clear();
                          setState(() => _results = []);
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _DrugChip extends ConsumerWidget {
  final Drug drug;
  const _DrugChip({required this.drug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Chip(
      label: Text(drug.genericName,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: AppColors.darkNavy,
      deleteIcon:
          const Icon(Icons.close, size: 14, color: Colors.white70),
      onDeleted: () =>
          ref.read(checkerDrugsProvider.notifier).remove(drug.id),
      side: BorderSide.none,
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final List<Drug> drugs;
  final List<DrugInteraction> interactions;
  const _ResultsSection(
      {required this.drugs, required this.interactions});

  int get _major =>
      interactions.where((i) => i.severity == InteractionSeverity.major).length;
  int get _moderate => interactions
      .where((i) => i.severity == InteractionSeverity.moderate)
      .length;
  int get _minor =>
      interactions.where((i) => i.severity == InteractionSeverity.minor).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary bar
        _SummaryBar(major: _major, moderate: _moderate, minor: _minor),
        // List
        Expanded(
          child: interactions.isEmpty
              ? _NoneFound(drugCount: drugs.length)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: interactions.length,
                  itemBuilder: (_, i) =>
                      _InteractionCard(interaction: interactions[i]),
                ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int major, moderate, minor;
  const _SummaryBar(
      {required this.major,
      required this.moderate,
      required this.minor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _SummaryDot('خطير', major, AppColors.errorRed),
          const SizedBox(width: 16),
          _SummaryDot('متوسط', moderate, AppColors.warningAmber),
          const SizedBox(width: 16),
          _SummaryDot('خفيف', minor, AppColors.accentTeal),
          const Spacer(),
          Text('${major + moderate + minor} تفاعل',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryDot extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryDot(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label: $count',
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;
  const _InteractionCard({required this.interaction});

  Color get _color => switch (interaction.severity) {
        InteractionSeverity.major => AppColors.errorRed,
        InteractionSeverity.moderate => AppColors.warningAmber,
        InteractionSeverity.minor => AppColors.accentTeal,
      };

  String get _severityLabel => switch (interaction.severity) {
        InteractionSeverity.major => 'تفاعل خطير',
        InteractionSeverity.moderate => 'تفاعل متوسط',
        InteractionSeverity.minor => 'تفاعل خفيف',
      };

  IconData get _icon => switch (interaction.severity) {
        InteractionSeverity.major => Icons.dangerous,
        InteractionSeverity.moderate => Icons.warning_amber_rounded,
        InteractionSeverity.minor => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_icon, color: _color, size: 20),
        ),
        title: Text(
          '${interaction.drug1}  ×  ${interaction.drug2}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(_severityLabel,
            style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(
              interaction.descriptionAr,
              style: const TextStyle(
                  height: 1.6,
                  color: AppColors.textPrimary,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  color: AppColors.lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.medication,
                  size: 44, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text('ابدأ بإضافة الأدوية',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'ابحث عن الدواء في الحقل أعلاه وأضف 2 أدوية أو أكثر لفحص التفاعلات بينها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnedrugState extends StatelessWidget {
  const _OnedrugState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline,
              size: 60, color: AppColors.accentTeal),
          SizedBox(height: 16),
          Text('أضف دواءً ثانياً على الأقل',
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoneFound extends StatelessWidget {
  final int drugCount;
  const _NoneFound({required this.drugCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: Color(0xFFD4EDDA), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                size: 44, color: AppColors.successGreen),
          ),
          const SizedBox(height: 16),
          const Text('لا تفاعلات معروفة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successGreen)),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على تفاعلات موثقة بين الأدوية الـ$drugCount المختارة.\nهذا لا يُغني عن المراجعة السريرية.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
