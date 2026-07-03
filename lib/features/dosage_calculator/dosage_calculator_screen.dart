import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../core/l10n/app_strings.dart';

class DosageCalculatorScreen extends StatefulWidget {
  const DosageCalculatorScreen({super.key});

  @override
  State<DosageCalculatorScreen> createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    AuthService.instance.incrementToolUsage();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(context.s.doseCalc,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(icon: const Icon(Icons.child_care, size: 20), text: context.s.tabChildren),
            Tab(icon: const Icon(Icons.person, size: 20), text: context.s.tabAdults),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _PediatricTab(),
          _AdultTab(),
        ],
      ),
    );
  }
}

// ─── Pediatric Tab ────────────────────────────────────────────────────────────

class _PediatricTab extends StatefulWidget {
  const _PediatricTab();

  @override
  State<_PediatricTab> createState() => _PediatricTabState();
}

class _PediatricTabState extends State<_PediatricTab>
    with AutomaticKeepAliveClientMixin {
  final _weightCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _maxDoseCtrl = TextEditingController();
  double? _totalDose;
  bool _wasCapped = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _doseCtrl.dispose();
    _maxDoseCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightCtrl.text);
    final dose = double.tryParse(_doseCtrl.text);
    if (weight == null || dose == null || weight <= 0 || dose <= 0) return;
    final maxDose = double.tryParse(_maxDoseCtrl.text);
    double total = weight * dose;
    bool capped = false;
    if (maxDose != null && maxDose > 0 && total > maxDose) {
      total = maxDose;
      capped = true;
    }
    setState(() {
      _totalDose = total;
      _wasCapped = capped;
    });
  }

  void _reset() {
    _weightCtrl.clear();
    _doseCtrl.clear();
    _maxDoseCtrl.clear();
    setState(() {
      _totalDose = null;
      _wasCapped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBanner(
            icon: Icons.child_care,
            color: AppColors.primaryBlue,
            text: context.s.pediatricBanner,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InputField(
                    controller: _weightCtrl,
                    label: context.s.childWeight,
                    unit: context.s.kgUnit,
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _doseCtrl,
                    label: context.s.dosePerKg,
                    unit: context.s.mgKgUnit,
                    icon: Icons.medication_outlined,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _maxDoseCtrl,
                    label: context.s.maxDoseOptional,
                    unit: context.s.mgUnit,
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.warningAmber,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate, size: 18),
                          label: Text(context.s.calculate,
                              style: const TextStyle(fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(context.s.reset_),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_totalDose != null) ...[
            const SizedBox(height: 16),
            _ResultCard(
              label: _wasCapped ? context.s.doseCapped : context.s.totalDose,
              value: '${_totalDose!.toStringAsFixed(1)} ${context.s.mgUnit}',
              color: _wasCapped ? AppColors.warningAmber : AppColors.successGreen,
              icon: _wasCapped ? Icons.lock : Icons.check_circle,
              subtitle: _wasCapped
                  ? context.s.capNote
                  : '= ${_weightCtrl.text} ${context.s.kgUnit} × ${_doseCtrl.text} ${context.s.mgKgUnit}',
            ),
          ],
          const SizedBox(height: 16),
          _FormulaCard(
            title: context.s.formula,
            formula: context.s.pediatricFormula,
          ),
        ],
      ),
    );
  }
}

// ─── Adult Tab ────────────────────────────────────────────────────────────────

class _AdultTab extends StatefulWidget {
  const _AdultTab();

  @override
  State<_AdultTab> createState() => _AdultTabState();
}

class _AdultTabState extends State<_AdultTab>
    with AutomaticKeepAliveClientMixin {
  final _weightCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  double? _dailyDose;
  double? _perDose;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _doseCtrl.dispose();
    _freqCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightCtrl.text);
    final dose = double.tryParse(_doseCtrl.text);
    final freq = int.tryParse(_freqCtrl.text);
    if (weight == null || dose == null || weight <= 0 || dose <= 0) return;
    final daily = weight * dose;
    setState(() {
      _dailyDose = daily;
      _perDose = freq != null && freq > 0 ? daily / freq : null;
    });
  }

  void _reset() {
    _weightCtrl.clear();
    _doseCtrl.clear();
    _freqCtrl.clear();
    setState(() {
      _dailyDose = null;
      _perDose = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBanner(
            icon: Icons.person,
            color: Colors.deepPurple,
            text: context.s.adultBanner,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InputField(
                    controller: _weightCtrl,
                    label: context.s.adultWeight,
                    unit: context.s.kgUnit,
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _doseCtrl,
                    label: context.s.dailyDose,
                    unit: '${context.s.mgKgUnit}/day',
                    icon: Icons.medication_outlined,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _freqCtrl,
                    label: context.s.dailyFreq,
                    unit: context.s.timesDay,
                    icon: Icons.schedule,
                    color: AppColors.accentTeal,
                    isInteger: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate, size: 18),
                          label: Text(context.s.calculate,
                              style: const TextStyle(fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(context.s.reset_),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_dailyDose != null) ...[
            const SizedBox(height: 16),
            if (_perDose != null)
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      label: context.s.dailyDose,
                      value: '${_dailyDose!.toStringAsFixed(1)} ${context.s.mgUnit}/day',
                      color: Colors.deepPurple,
                      icon: Icons.today,
                      subtitle:
                          '${_weightCtrl.text} ${context.s.kgUnit} × ${_doseCtrl.text} ${context.s.mgKgUnit}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultCard(
                      label: context.s.perDose,
                      value: '${_perDose!.toStringAsFixed(1)} ${context.s.mgUnit}',
                      color: AppColors.accentTeal,
                      icon: Icons.schedule,
                      subtitle: '${_freqCtrl.text} ${context.s.timesDay}',
                    ),
                  ),
                ],
              )
            else
              _ResultCard(
                label: context.s.dailyDose,
                value: '${_dailyDose!.toStringAsFixed(1)} ${context.s.mgUnit}/day',
                color: Colors.deepPurple,
                icon: Icons.today,
                subtitle:
                    '= ${_weightCtrl.text} ${context.s.kgUnit} × ${_doseCtrl.text} ${context.s.mgKgUnit}',
              ),
          ],
          const SizedBox(height: 16),
          _FormulaCard(
            title: context.s.formula,
            formula: context.s.adultFormula,
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBanner(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final Color? color;
  final bool isInteger;

  const _InputField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    this.color,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryBlue;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      inputFormatters: [
        if (isInteger)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        suffixStyle: TextStyle(color: c, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: c, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String subtitle;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final String title;
  final String formula;
  const _FormulaCard({required this.title, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(formula,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  height: 1.6)),
        ],
      ),
    );
  }
}
