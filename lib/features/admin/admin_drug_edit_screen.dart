import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/drug_model.dart';

const _kCategories = <String, String>{
  'analgesics': 'مسكنات',
  'antibiotics': 'مضادات حيوية',
  'gastrointestinal': 'هضمي',
  'vitamins': 'فيتامينات/هرمونات',
  'cardiovascular': 'قلبية',
  'diabetes': 'سكري',
  'respiratory': 'تنفسي',
  'neurology': 'أعصاب/نفسية',
  'cosmetic': 'جلدية/تجميل',
  'narcotics': 'مخدرة',
  'other': 'أخرى',
};

class AdminDrugEditScreen extends StatefulWidget {
  final int? drugId; // null = new drug
  const AdminDrugEditScreen({super.key, this.drugId});
  @override
  State<AdminDrugEditScreen> createState() => _AdminDrugEditScreenState();
}

class _AdminDrugEditScreenState extends State<AdminDrugEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _nameEn, _nameAr, _tradeNames, _classEn, _classAr,
      _mechEn, _mechAr, _indEn, _indAr, _doseEn, _doseAr, _pedDose, _renal,
      _hepatic, _contraEn, _contraAr, _sideEn, _sideAr, _interEn, _interAr,
      _counselEn, _counselAr, _pregnancy, _lactation, _blackBox, _marketAr;

  String _category = 'other';
  String _rxOtc = 'Rx';
  bool _isRefrigerated = false;
  bool _isLasa = false;

  @override
  void initState() {
    super.initState();
    _nameEn = TextEditingController(); _nameAr = TextEditingController();
    _tradeNames = TextEditingController(); _classEn = TextEditingController();
    _classAr = TextEditingController(); _mechEn = TextEditingController();
    _mechAr = TextEditingController(); _indEn = TextEditingController();
    _indAr = TextEditingController(); _doseEn = TextEditingController();
    _doseAr = TextEditingController(); _pedDose = TextEditingController();
    _renal = TextEditingController(); _hepatic = TextEditingController();
    _contraEn = TextEditingController(); _contraAr = TextEditingController();
    _sideEn = TextEditingController(); _sideAr = TextEditingController();
    _interEn = TextEditingController(); _interAr = TextEditingController();
    _counselEn = TextEditingController(); _counselAr = TextEditingController();
    _pregnancy = TextEditingController(); _lactation = TextEditingController();
    _blackBox = TextEditingController(); _marketAr = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    if (widget.drugId != null) {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('drugs', where: 'id = ?', whereArgs: [widget.drugId]);
      if (rows.isNotEmpty) {
        final d = Drug.fromMap(rows.first);
        _nameEn.text = d.genericName; _nameAr.text = d.genericNameAr;
        _tradeNames.text = d.tradeNamesList.join(', ');
        _classEn.text = d.drugClass; _classAr.text = d.drugClassAr;
        _mechEn.text = d.mechanism; _mechAr.text = d.mechanismAr;
        _indEn.text = d.indications; _indAr.text = d.indicationsAr;
        _doseEn.text = d.adultDose; _doseAr.text = d.adultDoseAr;
        _pedDose.text = d.pediatricDose; _renal.text = d.renalDose;
        _hepatic.text = d.hepaticDose;
        _contraEn.text = d.contraindications; _contraAr.text = (rows.first['contraindications_ar'] as String?) ?? '';
        _sideEn.text = d.sideEffects; _sideAr.text = d.sideEffectsAr;
        _interEn.text = d.interactions; _interAr.text = d.interactionsAr;
        _counselEn.text = d.counselingNote; _counselAr.text = d.counselingNoteAr;
        _pregnancy.text = d.pregnancyCategory; _lactation.text = d.lactationSafety;
        _blackBox.text = d.blackBox; _marketAr.text = d.iraqMarketNoteAr;
        _category = _kCategories.containsKey(d.appCategory) ? d.appCategory : 'other';
        _rxOtc = d.rxOtc.isEmpty ? 'Rx' : d.rxOtc;
        _isRefrigerated = d.isRefrigerated; _isLasa = d.isLasa;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_nameEn, _nameAr, _tradeNames, _classEn, _classAr, _mechEn, _mechAr,
        _indEn, _indAr, _doseEn, _doseAr, _pedDose, _renal, _hepatic, _contraEn, _contraAr,
        _sideEn, _sideAr, _interEn, _interAr, _counselEn, _counselAr, _pregnancy, _lactation,
        _blackBox, _marketAr]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tradeJson = _tradeNames.text
        .split(RegExp(r'[,،]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final tradeNamesStr = tradeJson.isEmpty
        ? '[]'
        : '[${tradeJson.map((e) => '"${e.replaceAll('"', '')}"').join(', ')}]';

    final data = <String, dynamic>{
      'generic_name': _nameEn.text.trim(),
      'generic_name_ar': _nameAr.text.trim(),
      'trade_names': tradeNamesStr,
      'pharmacological_class': _classEn.text.trim(),
      'pharmacological_class_ar': _classAr.text.trim(),
      'mechanism_of_action': _mechEn.text.trim(),
      'mechanism_of_action_ar': _mechAr.text.trim(),
      'indications': _indEn.text.trim(),
      'indications_ar': _indAr.text.trim(),
      'adult_dosage': _doseEn.text.trim(),
      'adult_dosage_ar': _doseAr.text.trim(),
      'pediatric_dosage': _pedDose.text.trim(),
      'renal_adjustment': _renal.text.trim(),
      'hepatic_adjustment': _hepatic.text.trim(),
      'contraindications': _contraEn.text.trim(),
      'contraindications_ar': _contraAr.text.trim(),
      'side_effects': _sideEn.text.trim(),
      'side_effects_ar': _sideAr.text.trim(),
      'drug_interactions': _interEn.text.trim(),
      'drug_interactions_ar': _interAr.text.trim(),
      'counseling_note': _counselEn.text.trim(),
      'counseling_note_ar': _counselAr.text.trim(),
      'pregnancy_category': _pregnancy.text.trim(),
      'lactation_safety': _lactation.text.trim(),
      'black_box': _blackBox.text.trim(),
      'iraq_market_note_ar': _marketAr.text.trim(),
      'app_category': _category,
      'rx_otc': _rxOtc,
      'is_refrigerated': _isRefrigerated ? 1 : 0,
      'is_lasa': _isLasa ? 1 : 0,
    };

    if (widget.drugId == null) {
      await DatabaseHelper.instance.insertDrug(data);
    } else {
      await DatabaseHelper.instance.updateDrug(widget.drugId!, data);
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.drugId == null ? 'إضافة دواء جديد' : 'تعديل الدواء',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('حفظ', style: GoogleFonts.ibmPlexSansArabic(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('الاسم العلمي'),
            _field(_nameEn, 'الاسم بالإنجليزي *', required: true),
            _field(_nameAr, 'الاسم بالعربي *', required: true, rtl: true),
            _field(_tradeNames, 'الأسماء التجارية (افصل بفاصلة)', rtl: true),

            _section('التصنيف'),
            _dropdownCategory(),
            _field(_classEn, 'التصنيف الدوائي (إنجليزي)'),
            _field(_classAr, 'التصنيف الدوائي (عربي)', rtl: true),
            _dropdownRxOtc(),

            _section('آلية العمل والاستطباب'),
            _field(_mechEn, 'آلية العمل (إنجليزي)', lines: 2),
            _field(_mechAr, 'آلية العمل (عربي)', lines: 2, rtl: true),
            _field(_indEn, 'دواعي الاستعمال (إنجليزي)', lines: 2),
            _field(_indAr, 'دواعي الاستعمال (عربي)', lines: 2, rtl: true),

            _section('الجرعة'),
            _field(_doseEn, 'جرعة البالغين (إنجليزي)', lines: 2),
            _field(_doseAr, 'جرعة البالغين (عربي)', lines: 2, rtl: true),
            _field(_pedDose, 'جرعة الأطفال', lines: 2, rtl: true),
            _field(_renal, 'تعديل الجرعة الكلوي', rtl: true),
            _field(_hepatic, 'تعديل الجرعة الكبدي', rtl: true),

            _section('السلامة'),
            _field(_contraEn, 'موانع الاستعمال (إنجليزي)', lines: 2),
            _field(_contraAr, 'موانع الاستعمال (عربي)', lines: 2, rtl: true),
            _field(_sideEn, 'الأعراض الجانبية (إنجليزي)', lines: 2),
            _field(_sideAr, 'الأعراض الجانبية (عربي)', lines: 2, rtl: true),
            _field(_interEn, 'التداخلات الدوائية (إنجليزي)', lines: 2),
            _field(_interAr, 'التداخلات الدوائية (عربي)', lines: 2, rtl: true),
            _field(_blackBox, 'تحذير صريح (Black Box) إن وجد', lines: 2),
            _field(_pregnancy, 'فئة الحمل (A/B/C/D/X)'),
            _field(_lactation, 'سلامة الرضاعة'),

            _section('إرشادات وملاحظات'),
            _field(_counselEn, 'إرشادات المريض (إنجليزي)', lines: 2),
            _field(_counselAr, 'إرشادات المريض (عربي)', lines: 2, rtl: true),
            _field(_marketAr, 'ملاحظة السوق العراقي (عربي)', lines: 2, rtl: true),

            _section('خصائص إضافية'),
            SwitchListTile(
              title: Text('يحتاج تبريد', style: GoogleFonts.ibmPlexSansArabic(fontSize: 14)),
              value: _isRefrigerated,
              onChanged: (v) => setState(() => _isRefrigerated = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('عالي الخطورة / يشبه دواءً آخر (LASA)', style: GoogleFonts.ibmPlexSansArabic(fontSize: 14)),
              value: _isLasa,
              onChanged: (v) => setState(() => _isLasa = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            if (widget.drugId != null)
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: Text('حذف الدواء', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
                        content: Text('هل تريد حذف "${_nameEn.text}" نهائياً؟', style: GoogleFonts.ibmPlexSansArabic()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic())),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0),
                            child: Text('حذف', style: GoogleFonts.ibmPlexSansArabic()),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && widget.drugId != null) {
                      await DatabaseHelper.instance.deleteDrug(widget.drugId!);
                      if (mounted) context.pop();
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  label: Text('حذف هذا الدواء', style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade300)),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title,
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
  );

  Widget _field(TextEditingController c, String label,
      {bool required = false, int lines = 1, bool rtl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        textAlign: rtl ? TextAlign.right : TextAlign.left,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'حقل إلزامي' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
          filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _dropdownCategory() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: _category,
      items: _kCategories.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.ibmPlexSansArabic(fontSize: 13))))
          .toList(),
      onChanged: (v) => setState(() => _category = v ?? 'other'),
      decoration: InputDecoration(
        labelText: 'فئة التطبيق *',
        labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
        filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
  );

  Widget _dropdownRxOtc() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: ['Rx', 'OTC', 'OTC/Rx'].contains(_rxOtc) ? _rxOtc : 'Rx',
      items: const ['Rx', 'OTC', 'OTC/Rx']
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) => setState(() => _rxOtc = v ?? 'Rx'),
      decoration: InputDecoration(
        labelText: 'وصفة طبية / دون وصفة',
        labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
        filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
  );
}
