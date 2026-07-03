class OtcMedication {
  final int    id;
  final String brandName;
  final String genericName;
  final String category;
  final String dosageForm;
  final String stockStatus; // 'available' | 'limited' | 'out_of_stock'

  const OtcMedication({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.category,
    required this.dosageForm,
    required this.stockStatus,
  });

  factory OtcMedication.fromJson(Map<String, dynamic> j) => OtcMedication(
    id:          j['id']           as int,
    brandName:   j['brand_name']   as String? ?? '',
    genericName: j['generic_name'] as String? ?? '',
    category:    j['category']     as String? ?? '',
    dosageForm:  j['dosage_form']  as String? ?? '',
    stockStatus: j['stock_status'] as String? ?? 'available',
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'brand_name':   brandName,
    'generic_name': genericName,
    'category':     category,
    'dosage_form':  dosageForm,
    'stock_status': stockStatus,
  };
}
