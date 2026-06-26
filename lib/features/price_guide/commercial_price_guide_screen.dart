import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/local_pricing_entry.dart';
import '../../providers/pricing_provider.dart';

const _green = Color(0xFF10B981);

class CommercialPriceGuideScreen extends ConsumerStatefulWidget {
  const CommercialPriceGuideScreen({super.key});

  @override
  ConsumerState<CommercialPriceGuideScreen> createState() =>
      _CommercialPriceGuideScreenState();
}

class _CommercialPriceGuideScreenState
    extends ConsumerState<CommercialPriceGuideScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(pricingSearchQueryProvider.notifier).state = val;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(pricingSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(pricingEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('دليل الأسعار التجاري',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('Commercial Price Guide',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Info banner ─────────────────────────────────────────────────
          const _InfoBanner(),

          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج أو الباركود...',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                    color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: entriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (entries) => entries.isEmpty
                  ? const _EmptyState()
                  : _PriceList(entries: entries),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'يعرض هذا القسم أسعار البيع للمنتجات التجارية المتوفرة في الصيدلية. '
              'يتم تحديث القائمة من قِبل الإدارة فقط.',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price list ────────────────────────────────────────────────────────────────
class _PriceList extends StatelessWidget {
  final List<LocalPricingEntry> entries;
  const _PriceList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PriceCard(entry: entries[i]),
    );
  }
}

// ── Single price card ─────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final LocalPricingEntry entry;
  const _PriceCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),

            // ── Name + barcode ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.tradeName,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  if (entry.barcode.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.qr_code,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(entry.barcode,
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Selling price chip ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('سعر البيع',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 10,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.sellingPrice.toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
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
            Icon(Icons.price_check_outlined,
                size: 72,
                color: AppColors.textSecondary.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text('القائمة فارغة حالياً',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'ستظهر هنا أسعار المنتجات التجارية بعد إضافتها من قِبل الإدارة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
