import '../../shared/widgets/t_text.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

/// كم يوماً تكفي العلبة؟
///
/// يحسب مدّة كفاية العبوة من الجرعة وعدد المرّات، ويعطي تاريخ النفاد
/// وتاريخ تذكير إعادة الصرف. يعمل للأقراص والشراب والقطرة والأنسولين.
enum _Mode { tablet, syrup, drops, insulin }

class SupplyDaysScreen extends StatefulWidget {
  const SupplyDaysScreen({super.key});

  @override
  State<SupplyDaysScreen> createState() => _SupplyDaysScreenState();
}

class _SupplyDaysScreenState extends State<SupplyDaysScreen> {
  _Mode _mode = _Mode.tablet;

  final _pack = TextEditingController();
  final _dose = TextEditingController();
  final _conc = TextEditingController();
  int _times = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntro.showOnce(context, id: 'supply_days');
    });
  }

  @override
  void dispose() {
    _pack.dispose();
    _dose.dispose();
    _conc.dispose();
    super.dispose();
  }

  double? get _n => double.tryParse(_pack.text.trim());
  double? get _d => double.tryParse(_dose.text.trim());
  double? get _c => double.tryParse(_conc.text.trim());

  String get _packLabel => switch (_mode) {
        _Mode.tablet  => 'عدد الأقراص في العلبة',
        _Mode.syrup   => 'حجم القنينة (مل)',
        _Mode.drops   => 'حجم القنينة (مل)',
        _Mode.insulin => 'وحدات القلم أو القنينة',
      };

  String get _doseLabel => switch (_mode) {
        _Mode.tablet  => 'عدد الأقراص في المرّة',
        _Mode.syrup   => 'الجرعة في المرّة (ملغم)',
        _Mode.drops   => 'عدد القطرات في المرّة',
        _Mode.insulin => 'الوحدات في المرّة',
      };

  /// عدد الوحدات المستهلكة يومياً
  double? get _perDay {
    final d = _d, t = _times.toDouble();
    if (d == null || d <= 0) return null;
    if (_mode == _Mode.syrup) {
      final c = _c;
      if (c == null || c <= 0) return null;
      // الجرعة بالملغم ÷ التركيز (ملغم/مل) = مل في المرّة
      return (d / c) * t;
    }
    if (_mode == _Mode.drops) {
      // التقدير المعتمد: 20 قطرة ≈ 1 مل
      return (d / 20) * t;
    }
    return d * t;
  }

  int? get _days {
    final n = _n, pd = _perDay;
    if (n == null || n <= 0 || pd == null || pd <= 0) return null;
    return (n / pd).floor();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final days   = _days;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TText('كم يوماً تكفي العلبة؟',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _card(
            isDark,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TText('نوع الشكل الدوائي',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('أقراص وكبسولات', _Mode.tablet),
                  _chip('شراب ومعلّق', _Mode.syrup),
                  _chip('قطرة', _Mode.drops),
                  _chip('أنسولين', _Mode.insulin),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            isDark,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_pack, _packLabel),
                const SizedBox(height: 12),
                if (_mode == _Mode.syrup) ...[
                  _field(_conc, 'التركيز (ملغم في كل مل)',
                      hint: 'مثال: شراب 250 ملغم / 5 مل يعني 50'),
                  const SizedBox(height: 12),
                ],
                _field(_dose, _doseLabel),
                const SizedBox(height: 14),
                const TText('عدد المرّات في اليوم',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 9),
                Wrap(spacing: 8, children: [
                  for (final t in [1, 2, 3, 4, 6])
                    ChoiceChip(
                      label: TText(
                          t == 1
                              ? 'مرّة'
                              : (t == 2
                                  ? 'مرّتان'
                                  : '$t مرّات'),
                          style: const TextStyle(fontSize: 12)),
                      selected: _times == t,
                      onSelected: (_) {
                        Haptics.select();
                        setState(() => _times = t);
                      },
                      selectedColor: AppColors.primary.withOpacity(0.16),
                      labelStyle: TextStyle(
                          color: _times == t
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: _times == t
                              ? FontWeight.bold
                              : FontWeight.normal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(
                            color: _times == t
                                ? AppColors.primary.withOpacity(0.4)
                                : (isDark
                                    ? Colors.white24
                                    : const Color(0xFFDFE4E8))),
                      ),
                      backgroundColor: Colors.transparent,
                      showCheckmark: false,
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (days == null)
            _card(
              isDark,
              Row(children: [
                Icon(Icons.calculate_outlined,
                    size: 19, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: TText('أكمل الحقول أعلاه ليظهر الناتج',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ]),
            )
          else
            _result(days, isDark),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: AppColors.warningAmber.withOpacity(0.22)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 17, color: AppColors.warningAmber),
              const SizedBox(width: 9),
              Expanded(
                child: TText(
                    'القطرة محسوبة على أنّ كل 20 قطرة تساوي ملليلتراً واحداً، '
                    'وهو تقدير يتغيّر بحسب لزوجة المحلول وفوهة القنينة. '
                    'الشراب بعد التحضير له مدّة صلاحية قد تنتهي قبل أن ينفد',
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.7,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Mode m) {
    final theme = Theme.of(context);
    final sel   = _mode == m;
    return ChoiceChip(
      label: TText(label, style: const TextStyle(fontSize: 12)),
      selected: sel,
      onSelected: (_) {
        Haptics.select();
        setState(() {
          _mode = m;
          _conc.clear();
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.16),
      backgroundColor: Colors.transparent,
      showCheckmark: false,
      labelStyle: TextStyle(
          color: sel ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
            color: sel
                ? AppColors.primary.withOpacity(0.4)
                : (theme.brightness == Brightness.dark
                    ? Colors.white24
                    : const Color(0xFFDFE4E8))),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {String? hint}) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: trN(context, label),
        labelStyle: const TextStyle(fontSize: 12.5),
        hintText: trN(context, hint),
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

  Widget _result(int days, bool isDark) {
    final theme = Theme.of(context);
    final out   = DateTime.now().add(Duration(days: days));
    final remind = days > 5
        ? DateTime.now().add(Duration(days: days - 5))
        : DateTime.now();
    final unit = switch (_mode) {
      _Mode.tablet  => 'قرصاً في اليوم',
      _Mode.syrup   => 'مل في اليوم',
      _Mode.drops   => 'مل في اليوم',
      _Mode.insulin => 'وحدة في اليوم',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(isDark ? 0.26 : 0.12),
            AppColors.primary.withOpacity(isDark ? 0.14 : 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_available_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 9),
            TText('تكفي $days يوماً',
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          _row('الاستهلاك اليومي',
              '${_perDay!.toStringAsFixed(_perDay! % 1 == 0 ? 0 : 1)} $unit'),
          _row('تاريخ النفاد المتوقّع', '${out.year}/${out.month}/${out.day}'),
          _row('ذكّر المريض بإعادة الصرف',
              '${remind.year}/${remind.month}/${remind.day}'),
          if (days < 7) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(children: [
                const Icon(Icons.priority_high_rounded,
                    size: 16, color: AppColors.errorRed),
                const SizedBox(width: 8),
                Expanded(
                  child: TText(
                      'العبوة لا تكفي أسبوعاً. راجع حجم العبوة أو اصرف '
                      'أكثر من واحدة لتغطية مدّة العلاج',
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.6,
                          color: theme.colorScheme.onSurface)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Expanded(
          child: TText(k,
              style: TextStyle(
                  fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
        ),
        TText(v,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
