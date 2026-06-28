import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PricingCalculatorScreen extends StatefulWidget {
  const PricingCalculatorScreen({super.key});

  @override
  State<PricingCalculatorScreen> createState() =>
      _PricingCalculatorScreenState();
}

class _PricingCalculatorScreenState extends State<PricingCalculatorScreen> {
  final _baseCostCtrl     = TextEditingController();
  final _purchasedCtrl    = TextEditingController();
  final _bonusCtrl        = TextEditingController();
  final _discountCtrl     = TextEditingController();
  final _cashCtrl         = TextEditingController();
  final _profitCtrl       = TextEditingController();

  double _netCost        = 0;
  double _sellingPrice   = 0;
  double _totalPieces    = 0;
  double _totalPaid      = 0;
  bool   _hasResult      = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_baseCostCtrl, _purchasedCtrl, _bonusCtrl,
                     _discountCtrl, _cashCtrl, _profitCtrl]) {
      c.addListener(_recalculate);
    }
  }

  @override
  void dispose() {
    for (final c in [_baseCostCtrl, _purchasedCtrl, _bonusCtrl,
                     _discountCtrl, _cashCtrl, _profitCtrl]) {
      c.removeListener(_recalculate);
      c.dispose();
    }
    super.dispose();
  }

  void _recalculate() {
    final base      = double.tryParse(_baseCostCtrl.text)  ?? 0;
    final purchased = double.tryParse(_purchasedCtrl.text) ?? 0;
    final bonus     = double.tryParse(_bonusCtrl.text)     ?? 0;
    final disc      = double.tryParse(_discountCtrl.text)  ?? 0;
    final cash      = double.tryParse(_cashCtrl.text)      ?? 0;
    final profit    = double.tryParse(_profitCtrl.text)    ?? 0;

    if (base <= 0 || purchased <= 0) {
      setState(() => _hasResult = false);
      return;
    }

    final pieces    = purchased + bonus;
    final costBefore = purchased * base;
    final paid      = (costBefore * (1 - disc / 100)) - cash;
    final net       = paid / pieces;
    final selling   = net * (1 + profit / 100);

    setState(() {
      _totalPieces  = pieces;
      _totalPaid    = paid;
      _netCost      = net;
      _sellingPrice = selling;
      _hasResult    = true;
    });
  }

  void _reset() {
    for (final c in [_baseCostCtrl, _purchasedCtrl, _bonusCtrl,
                     _discountCtrl, _cashCtrl, _profitCtrl]) {
      c.clear();
    }
    setState(() => _hasResult = false);
    FocusScope.of(context).unfocus();
  }

  String _fmt(double v) {
    if (v <= 0) return '—';
    if (v >= 1000) {
      return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return v.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final topPad  = mq.padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── AppBar يدوي ────────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(4, topPad + 4, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text('حاسبة التسعير الذكي',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 15),
                        const SizedBox(width: 4),
                        Text('مسح',
                            style: GoogleFonts.cairo(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── المحتوى ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── صف 1: سعر القطعة ───────────────────────────────────
                  _buildLabel('سعر القطعة في الفاتورة *'),
                  const SizedBox(height: 5),
                  _Field(
                    controller: _baseCostCtrl,
                    hint: '0.000',
                    suffix: 'د.ع',
                    icon: Icons.sell_outlined,
                  ),

                  const SizedBox(height: 10),

                  // ── صف 2: الكمية + البونص ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('الكمية المشتراة *'),
                            const SizedBox(height: 5),
                            _Field(
                              controller: _purchasedCtrl,
                              hint: '0',
                              suffix: 'قطعة',
                              icon: Icons.inventory_2_outlined,
                              isInt: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('البونص المجاني'),
                            const SizedBox(height: 5),
                            _Field(
                              controller: _bonusCtrl,
                              hint: '0',
                              suffix: 'قطعة',
                              icon: Icons.card_giftcard_rounded,
                              isInt: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── صف 3: الخصم % + خصم نقدي ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('نسبة الخصم'),
                            const SizedBox(height: 5),
                            _Field(
                              controller: _discountCtrl,
                              hint: '0',
                              suffix: '%',
                              icon: Icons.percent_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('خصم نقدي إضافي'),
                            const SizedBox(height: 5),
                            _Field(
                              controller: _cashCtrl,
                              hint: '0',
                              suffix: 'د.ع',
                              icon: Icons.money_off_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── نتيجة: تكلفة الوحدة + سعر البيع ───────────────────
                  Row(
                    children: [
                      // تكلفة الوحدة الصافية
                      Expanded(
                        child: _ResultTile(
                          label: 'تكلفة الوحدة الصافية',
                          value: _hasResult ? '${_fmt(_netCost)} د.ع' : '—',
                          color: AppColors.primary,
                          icon: Icons.calculate_outlined,
                          sub: _hasResult
                              ? '${_totalPieces.toInt()} قطعة • ${_fmt(_totalPaid)} د.ع'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // سعر البيع
                      Expanded(
                        child: _ResultTile(
                          label: 'سعر البيع',
                          value: _hasResult
                              ? '${_fmt(_sellingPrice)} د.ع'
                              : '—',
                          color: const Color(0xFF6A1B9A),
                          icon: Icons.storefront_outlined,
                          sub: _hasResult && _netCost > 0
                              ? 'ربح ${_fmt(_sellingPrice - _netCost)} د.ع'
                              : null,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── سعر البيع — إدخال نسبة الربح ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: const Color(0xFF6A1B9A).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded,
                            color: const Color(0xFF6A1B9A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('نسبة الربح لحساب سعر البيع',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6A1B9A))),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: _Field(
                            controller: _profitCtrl,
                            hint: '0',
                            suffix: '%',
                            icon: Icons.add_chart_rounded,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── توضيح الاستخدام ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('كيفية الاستخدام',
                                style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _HelpRow('*', 'الحقول المعلّمة بـ (*) إلزامية — الباقي اختياري'),
                        _HelpRow('🎁', 'البونص: القطع المجانية من المورد — تُحسب في التكلفة'),
                        _HelpRow('%', 'نسبة الخصم والخصم النقدي يُطرحان من الفاتورة'),
                        _HelpRow('⚡', 'النتائج تتحدث تلقائياً عند كل إدخال'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isOptional = !text.contains('*');
    return Row(
      children: [
        Text(text,
            style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        if (isOptional) ...[
          const SizedBox(width: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('اختياري',
                style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: AppColors.textSecondary)),
          ),
        ],
      ],
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint, suffix;
  final IconData icon;
  final bool isInt;
  final bool compact;

  const _Field({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.icon,
    this.isInt   = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          TextInputType.numberWithOptions(decimal: !isInt),
      inputFormatters: isInt
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.center,
      style: GoogleFonts.ibmPlexMono(
          fontSize: compact ? 13 : 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.ibmPlexMono(
            color: AppColors.textSecondary.withOpacity(0.35),
            fontSize: compact ? 12 : 13),
        prefixIcon: compact
            ? null
            : Icon(icon, size: 16, color: AppColors.primary),
        suffixText: suffix,
        suffixStyle: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 10, vertical: compact ? 10 : 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final String? sub;
  final bool isHighlight;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.sub,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isHighlight ? color : color.withOpacity(0.25),
            width: isHighlight ? 0 : 1),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: isHighlight ? Colors.white70 : color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isHighlight
                            ? Colors.white70
                            : AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.white : color)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: isHighlight
                        ? Colors.white60
                        : AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ── Help row ──────────────────────────────────────────────────────────────────
class _HelpRow extends StatelessWidget {
  final String icon, text;
  const _HelpRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon  ',
              style: const TextStyle(fontSize: 12)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.cairo(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
