import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/drug_provider.dart';
import '../../../providers/recent_searches_provider.dart';
import '../../barcode/barcode_scanner_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PharmaSearchBar
// ═════════════════════════════════════════════════════════════════════════════

class PharmaSearchBar extends ConsumerStatefulWidget {
  const PharmaSearchBar({super.key});

  @override
  ConsumerState<PharmaSearchBar> createState() => _PharmaSearchBarState();
}

class _PharmaSearchBarState extends ConsumerState<PharmaSearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _layerLink = LayerLink();

  Timer? _debounce;
  OverlayEntry? _overlay;

  bool _hasText = false;
  String _liveQuery = '';

  static const double _barHeight = 52;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _focus.removeListener(_onFocusChanged);
    _ctrl.dispose();
    _focus.dispose();
    _hideOverlay();
    super.dispose();
  }

  // ── Text change with debounce ─────────────────────────────────────────────
  void _onTextChanged() {
    final text = _ctrl.text;
    setState(() => _hasText = text.isNotEmpty);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _liveQuery = text);
      ref.read(searchQueryProvider.notifier).state = text;
      _refreshOverlay();
    });
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
      final q = _ctrl.text.trim();
      if (q.length >= 2) {
        ref.read(recentSearchesProvider.notifier).add(q);
      }
    }
  }

  // ── Overlay lifecycle ─────────────────────────────────────────────────────
  void _showOverlay() {
    _hideOverlay();
    _overlay = OverlayEntry(builder: (_) => _buildDropdown());
    Overlay.of(context).insert(_overlay!);
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _refreshOverlay() => _overlay?.markNeedsBuild();

  Widget _buildDropdown() {
    return Positioned(
      width: double.infinity,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, _barHeight + 6),
        child: Material(
          color: Colors.transparent,
          child: _SearchDropdown(
            query: _liveQuery,
            onSelect: _applyQuery,
            onRemoveRecent: (s) {
              ref.read(recentSearchesProvider.notifier).remove(s);
              _refreshOverlay();
            },
            onClearRecent: () {
              ref.read(recentSearchesProvider.notifier).clear();
              _refreshOverlay();
            },
          ),
        ),
      ),
    );
  }

  // ── Apply a query (from tap or barcode) ──────────────────────────────────
  void _applyQuery(String query) {
    _ctrl.text = query;
    _ctrl.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _hasText = query.isNotEmpty;
      _liveQuery = query;
    });
    ref.read(searchQueryProvider.notifier).state = query;
    if (query.trim().length >= 2) {
      ref.read(recentSearchesProvider.notifier).add(query.trim());
    }
    _focus.unfocus();
  }

  // ── Scanner logic ─────────────────────────────────────────────────────────
  Future<void> _onScanTap() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      _openScanner();
      return;
    }
    if (!mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CameraPermissionDialog(),
    );
    if (allow != true) return;
    final result = await Permission.camera.request();
    if (result.isGranted) {
      _openScanner();
    } else if (result.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يرجى السماح بالكاميرا من إعدادات الجهاز',
            style: GoogleFonts.cairo()),
        backgroundColor: AppColors.errorRed,
        action: SnackBarAction(
            label: 'الإعدادات',
            textColor: Colors.white,
            onPressed: openAppSettings),
      ));
    }
  }

  Future<void> _openScanner() async {
    if (!mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.isNotEmpty && mounted) _applyQuery(code);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.cairo(fontSize: 14),
                onSubmitted: (v) {
                  if (v.trim().length >= 2) {
                    ref.read(recentSearchesProvider.notifier).add(v.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن دواء... (عربي أو إنجليزي)',
                  hintStyle: GoogleFonts.cairo(
                      color: AppColors.textSecondary, fontSize: 13.5),
                  border:        InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder:   InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _hasText = false;
                          _liveQuery = '';
                        });
                        ref.read(searchQueryProvider.notifier).state = '';
                        _refreshOverlay();
                      },
                    )
                  : _ScannerChip(
                      key: const ValueKey('scan'),
                      onTap: _onScanTap,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Scanner chip button
// ═════════════════════════════════════════════════════════════════════════════

class _ScannerChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ScannerChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.primary, size: 19),
              const SizedBox(width: 5),
              Text('مسح',
                  style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Dropdown shell — chooses between Recent or Autocomplete
// ═════════════════════════════════════════════════════════════════════════════

class _SearchDropdown extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearRecent;

  const _SearchDropdown({
    required this.query,
    required this.onSelect,
    required this.onRemoveRecent,
    required this.onClearRecent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRecent = query.trim().length < 2;
    final recents = ref.watch(recentSearchesProvider);

    if (showRecent && recents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: showRecent
              ? _RecentList(
                  items: recents,
                  onSelect: onSelect,
                  onRemove: onRemoveRecent,
                  onClear: onClearRecent,
                )
              : _AutocompleteList(
                  query: query,
                  onSelect: onSelect,
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Recent searches list
// ═════════════════════════════════════════════════════════════════════════════

class _RecentList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _RecentList({
    required this.items,
    required this.onSelect,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('عمليات البحث الأخيرة',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text('مسح الكل',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
        ...items.map((item) => _RecentTile(
              item: item,
              onSelect: onSelect,
              onRemove: onRemove,
            )),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final String item;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  const _RecentTile({
    required this.item,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                size: 17, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item,
                  style: GoogleFonts.cairo(
                      fontSize: 13.5, color: AppColors.textPrimary)),
            ),
            GestureDetector(
              onTap: () => onRemove(item),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Autocomplete suggestions list (generic vs trade badge)
// ═════════════════════════════════════════════════════════════════════════════

class _AutocompleteList extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onSelect;

  const _AutocompleteList({required this.query, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(autocompleteSuggestionsProvider(query));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ...suggestions.map((s) => _SuggestionTile(
                  item: s,
                  query: query,
                  onSelect: onSelect,
                )),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final SuggestionItem item;
  final String query;
  final ValueChanged<String> onSelect;

  const _SuggestionTile({
    required this.item,
    required this.query,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(item.display),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.isGeneric
                  ? Icons.medication_outlined
                  : Icons.local_pharmacy_outlined,
              size: 17,
              color: item.isGeneric ? AppColors.primary : const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 10),
            Expanded(child: _HighlightedText(text: item.display, query: query)),
            const SizedBox(width: 8),
            // Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: item.isGeneric
                    ? AppColors.primaryLight
                    : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.isGeneric ? 'جنيس' : 'تجاري',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: item.isGeneric
                      ? AppColors.primary
                      : const Color(0xFF6D28D9),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.north_west_rounded,
                size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Highlights the matching part of a suggestion in bold teal.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx < 0) {
      return Text(text,
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textPrimary));
    }
    return Text.rich(TextSpan(children: [
      if (idx > 0)
        TextSpan(
            text: text.substring(0, idx),
            style: GoogleFonts.inter(
                fontSize: 13.5, color: AppColors.textSecondary)),
      TextSpan(
          text: text.substring(idx, idx + query.length),
          style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.primary,
              fontWeight: FontWeight.bold)),
      if (idx + query.length < text.length)
        TextSpan(
            text: text.substring(idx + query.length),
            style: GoogleFonts.inter(
                fontSize: 13.5, color: AppColors.textPrimary)),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Camera Permission Dialog
// ═════════════════════════════════════════════════════════════════════════════

class _CameraPermissionDialog extends StatelessWidget {
  const _CameraPermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            Text('إذن الكاميرا',
                style: GoogleFonts.cairo(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'نحتاج إلى إذن استخدام الكاميرا لمسح باركود الدواء بسرعة وبدقة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.65),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('السماح',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
