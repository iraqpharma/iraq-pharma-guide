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

  factory Drug.fromMap(Map<String, dynamic> m) => Drug(
        id: m['id'] as int,
        genericName: m['generic_name'] as String? ?? '',
        genericNameAr: m['generic_name_ar'] as String? ?? '',
        tradeNames: m['trade_names'] as String? ?? '[]',
        drugClass:
            (m['pharmacological_class'] ?? m['drug_class']) as String? ?? '',
        drugClassAr: m['pharmacological_class_ar'] as String? ?? '',
        mechanism:
            (m['mechanism_of_action'] ?? m['mechanism']) as String? ?? '',
        mechanismAr: m['mechanism_of_action_ar'] as String? ?? '',
        indications: m['indications'] as String? ?? '',
        indicationsAr: m['indications_ar'] as String? ?? '',
        adultDose: (m['adult_dosage'] ?? m['adult_dose']) as String? ?? '',
        adultDoseAr: m['adult_dosage_ar'] as String? ?? '',
        pediatricDose:
            (m['pediatric_dosage'] ?? m['pediatric_dose']) as String? ?? '',
        renalDose:
            (m['renal_adjustment'] ?? m['renal_dose']) as String? ?? '',
        hepaticDose:
            (m['hepatic_adjustment'] ?? m['hepatic_dose']) as String? ?? '',
        contraindications: m['contraindications'] as String? ?? '',
        sideEffects: m['side_effects'] as String? ?? '',
        sideEffectsAr: m['side_effects_ar'] as String? ?? '',
        interactions:
            (m['drug_interactions'] ?? m['interactions']) as String? ?? '',
        interactionsAr: m['drug_interactions_ar'] as String? ?? '',
        pregnancyCategory: m['pregnancy_category'] as String? ?? '',
        // Phase 4
        isRefrigerated: (m['is_refrigerated'] as int? ?? 0) == 1,
        isLasa: (m['is_lasa'] as int? ?? 0) == 1,
        lasaNames: m['lasa_names'] as String? ?? '',
        counselingNote: m['counseling_note'] as String? ?? '',
        counselingNoteAr: m['counseling_note_ar'] as String? ?? '',
        ivReconstitution: m['iv_reconstitution'] as String? ?? '',
        lactationSafety: m['lactation_safety'] as String? ?? '',
        imageAsset: m['image_asset'] as String? ?? '',
      );
}
