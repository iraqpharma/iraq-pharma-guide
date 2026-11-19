import 'dart:convert';

class Drug {
  final int id;
  final String genericName;
  final String genericNameAr;
  final String tradeNames;
  final String drugClass;
  final String drugClassAr;
  final String category;
  final String mechanism;
  final String mechanismAr;
  final String indications;
  final String indicationsAr;
  final String adultDose;
  final String adultDoseAr;
  final String pediatricDose;
  final String renalDose;
  final String hepaticDose;
  final String contraindications;
  final String contraindicationsAr;
  final String sideEffects;
  final String sideEffectsAr;
  final String interactions;
  final String interactionsAr;
  final String pregnancyCategory;
  final String iraqMarketNote;
  final String iraqMarketNoteAr;

  // ── Phase 4 fields ────────────────────────────────────────────────────────
  final bool isRefrigerated;
  final bool isLasa;
  final String lasaNames;
  final String counselingNote;
  final String counselingNoteAr;
  final String ivReconstitution;
  final String lactationSafety;
  final String imageAsset;

  // ── Extended fields (from 1040-drug DB) ───────────────────────────────────
  final String administrationNotes;
  final String monitoringNotes;
  final String blackBox;
  final String rxOtc;
  final String appCategory;
  final String dosageForm;
  final String availableDoses;

  // ── Version 3.0 fields ────────────────────────────────────────────────────
  final int drugId;                   // معرّف الماستر
  final String atcCode;
  final String familyEn;
  final String subclassEn;
  final String maxDailyDose;
  final String storageCondition;
  final bool lightProtection;         // حماية من الضوء
  final bool isOncology;
  final bool isVesicant;              // دواء مُقرِّح
  final String reconstitutionDiluent;
  final String reconstitutionVolume;
  final String finalDilutionFluid;
  final String finalVolume;
  final String infusionTime;
  final String stabilityAfterPrep;
  final String ppeRequired;
  final String preparationNotesAr;
  final String sourcePrimary;
  final String sourceCitation;
  final String referenceDisplayAr;
  final String barcode;
  final String reviewedBy;
  final String dataVersion;

  const Drug({
    required this.id,
    required this.genericName,
    this.genericNameAr = '',
    required this.tradeNames,
    this.drugClass = '',
    this.drugClassAr = '',
    this.category = '',
    this.mechanism = '',
    this.mechanismAr = '',
    this.indications = '',
    this.indicationsAr = '',
    this.adultDose = '',
    this.adultDoseAr = '',
    this.pediatricDose = '',
    this.renalDose = '',
    this.hepaticDose = '',
    this.contraindications = '',
    this.contraindicationsAr = '',
    this.sideEffects = '',
    this.sideEffectsAr = '',
    this.interactions = '',
    this.interactionsAr = '',
    this.pregnancyCategory = '',
    this.iraqMarketNote = '',
    this.iraqMarketNoteAr = '',
    // Phase 4
    this.isRefrigerated = false,
    this.isLasa = false,
    this.lasaNames = '',
    this.counselingNote = '',
    this.counselingNoteAr = '',
    this.ivReconstitution = '',
    this.lactationSafety = '',
    this.imageAsset = '',
    this.administrationNotes = '',
    this.monitoringNotes = '',
    this.blackBox = '',
    this.rxOtc = 'Rx',
    this.appCategory = 'other',
    this.dosageForm = '',
    this.availableDoses = '',
    // Version 3.0
    this.drugId = 0,
    this.atcCode = '',
    this.familyEn = '',
    this.subclassEn = '',
    this.maxDailyDose = '',
    this.storageCondition = '',
    this.lightProtection = false,
    this.isOncology = false,
    this.isVesicant = false,
    this.reconstitutionDiluent = '',
    this.reconstitutionVolume = '',
    this.finalDilutionFluid = '',
    this.finalVolume = '',
    this.infusionTime = '',
    this.stabilityAfterPrep = '',
    this.ppeRequired = '',
    this.preparationNotesAr = '',
    this.sourcePrimary = '',
    this.sourceCitation = '',
    this.referenceDisplayAr = '',
    this.barcode = '',
    this.reviewedBy = '',
    this.dataVersion = '',
  });

  List<String> get tradeNamesList {
    try {
      final decoded = jsonDecode(tradeNames);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return tradeNames.isNotEmpty ? [tradeNames] : [];
  }

  /// Lactation level extracted as int (1-5), or 0 if unknown.
  int get lactationLevel {
    final m = RegExp(r'L(\d)').firstMatch(lactationSafety);
    return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
  }

  /// ملاحظة السوق العراقي — العربية أولاً ثم الإنجليزية.
  String get marketNote =>
      iraqMarketNoteAr.isNotEmpty ? iraqMarketNoteAr : iraqMarketNote;

  /// هل توجد بيانات تحضير كافية لعرض بطاقة التحضير؟
  bool get hasPreparationData =>
      reconstitutionDiluent.isNotEmpty ||
      finalDilutionFluid.isNotEmpty ||
      infusionTime.isNotEmpty ||
      stabilityAfterPrep.isNotEmpty;

  static bool _flag(dynamic v) {
    if (v is int) return v == 1;
    if (v is bool) return v;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  factory Drug.fromMap(Map<String, dynamic> m) => Drug(
        id: m['id'] as int,
        genericName: _str(m['generic_name']),
        genericNameAr: _str(m['generic_name_ar']),
        tradeNames: m['trade_names'] as String? ?? '[]',
        drugClass: _str(m['pharmacological_class'] ?? m['drug_class']),
        drugClassAr: _str(m['pharmacological_class_ar']),
        mechanism: _str(m['mechanism_of_action'] ?? m['mechanism']),
        mechanismAr: _str(m['mechanism_of_action_ar']),
        indications: _str(m['indications']),
        indicationsAr: _str(m['indications_ar']),
        adultDose: _str(m['adult_dosage'] ?? m['adult_dose']),
        adultDoseAr: _str(m['adult_dosage_ar']),
        pediatricDose: _str(m['pediatric_dosage'] ?? m['pediatric_dose']),
        renalDose: _str(m['renal_adjustment'] ?? m['renal_dose']),
        hepaticDose: _str(m['hepatic_adjustment'] ?? m['hepatic_dose']),
        contraindications: _str(m['contraindications']),
        contraindicationsAr: _str(m['contraindications_ar']),
        sideEffects: _str(m['side_effects']),
        sideEffectsAr: _str(m['side_effects_ar']),
        interactions: _str(m['drug_interactions'] ?? m['interactions']),
        interactionsAr: _str(m['drug_interactions_ar']),
        pregnancyCategory: _str(m['pregnancy_category']),
        iraqMarketNote: _str(m['iraq_market_note']),
        iraqMarketNoteAr: _str(m['iraq_market_note_ar']),
        // Phase 4
        isRefrigerated: _flag(m['is_refrigerated']),
        isLasa: _flag(m['is_lasa']),
        lasaNames: _str(m['lasa_names']),
        counselingNote: _str(m['counseling_note']),
        counselingNoteAr: _str(m['counseling_note_ar']),
        ivReconstitution: _str(m['iv_reconstitution']),
        lactationSafety: _str(m['lactation_safety']),
        imageAsset: _str(m['image_asset']),
        administrationNotes: _str(m['administration_notes']),
        monitoringNotes: _str(m['monitoring_notes']),
        blackBox: _str(m['black_box']),
        rxOtc: m['rx_otc'] as String? ?? 'Rx',
        appCategory: m['app_category'] as String? ?? 'other',
        dosageForm: _str(m['dosage_form_ar']),
        availableDoses: _str(m['available_doses']),
        // Version 3.0
        drugId: (m['drug_id'] as int?) ?? 0,
        atcCode: _str(m['atc_code']),
        familyEn: _str(m['family_en']),
        subclassEn: _str(m['subclass_en']),
        maxDailyDose: _str(m['max_daily_dose']),
        storageCondition: _str(m['storage_condition']),
        lightProtection: _flag(m['light_protection']),
        isOncology: _flag(m['is_oncology']),
        isVesicant: _flag(m['is_vesicant']),
        reconstitutionDiluent: _str(m['reconstitution_diluent']),
        reconstitutionVolume: _str(m['reconstitution_volume']),
        finalDilutionFluid: _str(m['final_dilution_fluid']),
        finalVolume: _str(m['final_volume']),
        infusionTime: _str(m['infusion_time']),
        stabilityAfterPrep: _str(m['stability_after_prep']),
        ppeRequired: _str(m['ppe_required']),
        preparationNotesAr: _str(m['preparation_notes_ar']),
        sourcePrimary: _str(m['source_primary']),
        sourceCitation: _str(m['source_citation']),
        referenceDisplayAr: _str(m['reference_display_ar']),
        barcode: _str(m['barcode']),
        reviewedBy: _str(m['reviewed_by']),
        dataVersion: _str(m['data_version']),
      );
}
