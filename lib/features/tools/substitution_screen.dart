import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/substitution_database.dart';

class SubstitutionScreen extends StatefulWidget {
  const SubstitutionScreen({super.key});

  @override
  State<SubstitutionScreen> createState() => _SubstitutionScreenState();
}

class _SubstitutionScreenState extends State<SubstitutionScreen> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  final _db     = SubstitutionDatabase.instance;

  SubstitutionResult? _result;
  bool  _loading = false;
  bool  _searched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() { _result = null; _searched = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(val));
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _searched = true; });
    final res = await _db.searchAlternatives(q);
    if (mounted) setState(() { _result = res; _loading = false; });
  }

  void _clear() {
    _ctrl.clear();
    setState(() { _result = null; _searched = false; });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── هيدر + شريط البحث ────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الباحث عن البدائل الذكي',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Text('ابحث باسم الدواء أو المادة الفعالة',
                              style: GoogleFonts.cairo(
                                  color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text('يعمل بدون إنترنت',
                              style: GoogleFonts.cairo(
                                  color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // شريط البحث
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode:  _focus,
                    onChanged:  _onChanged,
                    textAlign:  TextAlign.right,
                    style: GoogleFonts.cairo(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'مثال: Zofran  أو  Ondansetron  أو  Nexium',
                      hintStyle: GoogleFonts.cairo(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 13),
                      prefixIcon: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary)),
                            )
                          : const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              onPressed: _clear,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── النتائج ──────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_searched) return _WelcomeState();

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_result == null || !_result!.hasResults) {
      return _EmptyState(query: _ctrl.text);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── بطاقة المعلومات ─────────────────────────────────────────────
        _InfoCard(result: _result!),
        const SizedBox(height: 16),

        // ── البدائل المباشرة ─────────────────────────────────────────────
        if (_result!.directAlternatives.isNotEmpty) ...[
          _SectionHeader(
            title: 'البدائل المباشرة',
            subtitle: 'نفس المادة الفعالة • ${_result!.activeIngredient}',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.primary,
            count: _result!.directAlternatives.length,
          ),
          const SizedBox(height: 8),
          ..._result!.directAlternatives.map(
            (b) => _BrandCard(brand: b, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
        ],

        // ── البدائل العلاجية ─────────────────────────────────────────────
        if (_result!.therapeuticGroups.isNotEmpty) ...[
          _SectionHeader(
            title: 'بدائل من نفس العائلة',
            subtitle: _result!.drugClass,
            icon: Icons.account_tree_outlined,
            color: const Color(0xFF6A1B9A),
            count: _result!.therapeuticGroups
                .fold(0, (s, g) => s + g.brands.length),
          ),
          const SizedBox(height: 8),
          ..._result!.therapeuticGroups.map((group) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 3, height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(group.ingredientName,
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6A1B9A))),
                      ],
                    ),
                  ),
                  ...group.brands.map(
                    (b) => _BrandCard(
                        brand: b, color: const Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(height: 10),
                ],
              )),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final SubstitutionResult result;
  const _InfoCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result.searchedBrand,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(Icons.science_outlined,
              'المادة الفعالة', result.activeIngredient),
          const SizedBox(height: 4),
          _InfoRow(Icons.category_outlined,
              'العائلة الدوائية', result.drugClass),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 6),
        Text('$label: ',
            style: GoogleFonts.cairo(
                fontSize: 12, color: Colors.white60)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Brand card ────────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  final CommercialBrand brand;
  final Color color;
  const _BrandCard({required this.brand, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand.brandName,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                if (brand.company.isNotEmpty)
                  Text(brand.company,
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded,
              color: color.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }
}

// ── Welcome state ─────────────────────────────────────────────────────────────
class _WelcomeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final examples = [
      'Nexium', 'Zofran', 'Lipitor', 'Voltaren',
      'Concor', 'Zyrtec',  'Cipro',  'Panadol',
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_search_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('ابحث عن أي دواء',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('سيعرض لك البدائل المباشرة وبدائل من نفس العائلة الدوائية',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: examples
                .map((e) => _ExampleChip(label: e))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  const _ExampleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final state = context
            .findAncestorStateOfType<_SubstitutionScreenState>();
        if (state != null) {
          state._ctrl.text = label;
          state._onChanged(label);
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('لا توجد نتائج لـ "$query"',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('جرّب البحث باسم تجاري آخر أو بالاسم العلمي',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
