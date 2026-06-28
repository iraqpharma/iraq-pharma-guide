import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pricing_entry.dart';
import '../../providers/supabase_pricing_provider.dart';

const _green = Color(0xFF10B981);
const _gold  = Color(0xFFF59E0B);

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
  bool _refreshing = false;

  List<PricingEntry> _cached = [];
  bool _cacheLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final repo = ref.read(pricingRepoProvider);
    final cached = await repo.loadCached();
    if (mounted) setState(() { _cached = cached; _cacheLoaded = true; });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(supabasePricingQueryProvider.notifier).state = val;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(supabasePricingQueryProvider.notifier).state = '';
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final repo = ref.read(pricingRepoProvider);
      final fresh = await repo.fetchFresh();
      if (mounted) {
        setState(() { _cached = fresh; });
        ref.invalidate(supabasePricingProvider);
        _showRefreshSnackbar();
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _showRefreshSnackbar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'تم استيراد أحدث البيانات بنجاح',
              style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(PricingEntry entry) {
    final repo = ref.read(pricingRepoProvider);
    repo.incrementViewCount(entry.id);
    showDialog(
      context: context,
      builder: (_) => _PriceDetailDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(supabasePricingProvider);
    final displayEntries = entriesAsync.valueOrNull ?? _cached;
    final isConnecting = entriesAsync.isLoading && _cached.isEmpty;

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
        actions: [
          _refreshing
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: 'تحديث القائمة',
                  onPressed: _refresh,
                ),
        ],
      ),
      body: Column(
        children: [
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
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: isConnecting
                ? const Center(child: CircularProgressIndicator())
                : entriesAsync.hasError && displayEntries.isEmpty
                    ? const _ErrorState()
                    : displayEntries.isEmpty && _cacheLoaded
                        ? const _EmptyState()
                        : _PriceList(
                            entries: displayEntries,
                            onTap: _openDetail,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── القائمة ────────────────────────────────────────────────────────────────────
class _PriceList extends StatelessWidget {
  final List<PricingEntry> entries;
  final void Function(PricingEntry) onTap;
  const _PriceList({required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PriceCard(entry: entries[i], onTap: onTap),
    );
  }
}

// ── بطاقة المنتج ───────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final PricingEntry entry;
  final void Function(PricingEntry) onTap;
  const _PriceCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(entry),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.tradeName,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    if (entry.barcode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.qr_code,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(entry.barcode,
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withOpacity(0.22)),
                    ),
                    child: Text(
                      '${entry.sellingPrice.toStringAsFixed(0)} د.ع',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _green),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary.withOpacity(0.4), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── مودال التفاصيل في المنتصف ─────────────────────────────────────────────────
class _PriceDetailDialog extends StatelessWidget {
  final PricingEntry entry;
  const _PriceDetailDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الهيدر
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.tradeName,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // السعر
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _green.withOpacity(0.18)),
                    ),
                    child: Column(children: [
                      Text('سعر البيع',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('${entry.sellingPrice.toStringAsFixed(0)} د.ع',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _green)),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // التفاصيل
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 10, 14, 6),
                          child: Text('التفاصيل الفنية',
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                        const Divider(height: 1),
                        if (entry.barcode.isNotEmpty)
                          _DetailRow(
                            label: 'الباركود',
                            value: entry.barcode,
                            icon: Icons.qr_code_rounded,
                            mono: true,
                            copyable: true,
                          ),
                        _DetailRow(
                          label: 'المعرف (ID)',
                          value:
                              '#${entry.id.substring(0, 8).toUpperCase()}',
                          icon: Icons.tag_rounded,
                          mono: true,
                        ),
                        if (entry.notes != null &&
                            entry.notes!.isNotEmpty)
                          _DetailRow(
                            label: 'التعبئة',
                            value: entry.notes!,
                            icon: Icons.info_outline_rounded,
                            isLast: true,
                          ),
                      ],
                    ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool mono;
  final bool copyable;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.mono = false,
    this.copyable = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              if (copyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ الباركود',
                            style: GoogleFonts.ibmPlexSansArabic()),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Row(children: [
                    Text(value,
                        style: mono
                            ? GoogleFonts.ibmPlexMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)
                            : GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded,
                        size: 14,
                        color: AppColors.textSecondary.withOpacity(0.5)),
                  ]),
                )
              else
                Text(value,
                    style: mono
                        ? GoogleFonts.ibmPlexMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)
                        : GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────
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
                color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('القائمة فارغة حالياً',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('ستظهر هنا أسعار المنتجات بعد إضافتها من لوحة التحكم',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('تعذّر الاتصال بالخادم',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('تحقق من اتصالك بالإنترنت',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
