import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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

  void _calculate() {
    final age = double.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final creat = double.tryParse(_creatCtrl.text);

    if (age == null || weight == null || creat == null || creat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع القيم بشكل صحيح')),
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

  String get _crclStage {
    if (_crcl == null) return '';
    if (_crcl! >= 90) return 'طبيعي';
    if (_crcl! >= 60) return 'قصور خفيف (G2)';
    if (_crcl! >= 30) return 'قصور متوسط (G3)';
    if (_crcl! >= 15) return 'قصور شديد (G4)';
    return 'فشل كلوي (G5)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة CrCl (Cockcroft-Gault)'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات المريض',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue)),
            const SizedBox(height: 16),
            _buildField(_ageCtrl, 'العمر (سنة)', '45'),
            const SizedBox(height: 12),
            _buildField(_weightCtrl, 'الوزن (كغ)', '70'),
            const SizedBox(height: 12),
            _buildField(_creatCtrl, 'الكرياتينين (mg/dL)', '1.2',
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('الجنس: ', style: TextStyle(fontSize: 15)),
                ChoiceChip(
                  label: const Text('ذكر'),
                  selected: !_isFemale,
                  onSelected: (_) => setState(() => _isFemale = false),
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                      color: !_isFemale ? Colors.white : AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('أنثى'),
                  selected: _isFemale,
                  onSelected: (_) => setState(() => _isFemale = true),
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                      color: _isFemale ? Colors.white : AppColors.textPrimary),
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
                child: const Text('احسب', style: TextStyle(fontSize: 16)),
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
                    Text(_crclStage,
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
    const rows = [
      ['≥ 90', 'طبيعي', 'لا تعديل'],
      ['60–89', 'G2 خفيف', 'مراقبة فقط'],
      ['30–59', 'G3 متوسط', 'تعديل الجرعة'],
      ['15–29', 'G4 شديد', 'تقليل كبير'],
      ['< 15', 'G5 فشل كلوي', 'يُمنع أو الغسيل'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('دليل تعديل الجرعات',
            style: TextStyle(fontWeight: FontWeight.bold,
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
            const TableRow(
              decoration: BoxDecoration(color: AppColors.lightBlue),
              children: [
                _Cell('CrCl', bold: true),
                _Cell('المرحلة', bold: true),
                _Cell('التوجيه', bold: true),
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
