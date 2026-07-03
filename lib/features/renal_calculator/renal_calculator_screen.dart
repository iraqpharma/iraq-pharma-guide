import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../core/l10n/app_strings.dart';

class RenalCalculatorScreen extends StatefulWidget {
  const RenalCalculatorScreen({super.key});

  @override
  State<RenalCalculatorScreen> createState() => _RenalCalculatorScreenState();
}

class _RenalCalculatorScreenState extends State<RenalCalculatorScreen> {
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _creatCtrl = TextEditingController();
  bool _isFemale = false;
  double? _crcl;

  @override
  void initState() {
    super.initState();
    AuthService.instance.incrementToolUsage();
  }

  void _calculate() {
    final age = double.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final creat = double.tryParse(_creatCtrl.text);

    if (age == null || weight == null || creat == null || creat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.enterAllValues)),
      );
      return;
    }

    // Cockcroft-Gault: CrCl = ((140 - age) × weight) / (72 × SCr) × 0.85 if female
    double result = ((140 - age) * weight) / (72 * creat);
    if (_isFemale) result *= 0.85;

    setState(() => _crcl = result.clamp(0, 300));
  }

  Color get _crclColor {
    if (_crcl == null) return AppColors.primaryBlue;
    if (_crcl! >= 60) return AppColors.successGreen;
    if (_crcl! >= 30) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  String _crclStage(AppStrings s) {
    if (_crcl == null) return '';
    return s.crclStage(_crcl!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.crclTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.s.patientData,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue)),
            const SizedBox(height: 16),
            _buildField(_ageCtrl, context.s.ageYears, '45'),
            const SizedBox(height: 12),
            _buildField(_weightCtrl, context.s.weightKg, '70'),
            const SizedBox(height: 12),
            _buildField(_creatCtrl, 'الكرياتينين (mg/dL)', '1.2',
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(context.s.gender, style: const TextStyle(fontSize: 15)),
                ChoiceChip(
                  label: Text(context.s.male),
                  selected: !_isFemale,
                  onSelected: (_) => setState(() => _isFemale = false),
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                      color: !_isFemale ? Colors.white : Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(context.s.female),
                  selected: _isFemale,
                  onSelected: (_) => setState(() => _isFemale = true),
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                      color: _isFemale ? Colors.white : Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _calculate,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(context.s.calculate, style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (_crcl != null) ...[
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _crclColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _crclColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text('${_crcl!.toStringAsFixed(1)} mL/min',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _crclColor)),
                    const SizedBox(height: 4),
                    Text(_crclStage(context.s),
                        style: TextStyle(fontSize: 16, color: _crclColor)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _RenalGuidanceTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType ?? TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _creatCtrl.dispose();
    super.dispose();
  }
}

class _RenalGuidanceTable extends StatelessWidget {
  const _RenalGuidanceTable();

  @override
  Widget build(BuildContext context) {
    final rows = context.s.renalRows;
    final headers = context.s.renalTableHeaders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.s.dosageGuide,
            style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 14, color: AppColors.primaryBlue)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8)),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.lightBlue),
              children: [
                _Cell(headers[0], bold: true),
                _Cell(headers[1], bold: true),
                _Cell(headers[2], bold: true),
              ],
            ),
            for (final r in rows)
              TableRow(children: [_Cell(r[0]), _Cell(r[1]), _Cell(r[2])]),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  const _Cell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }
}
