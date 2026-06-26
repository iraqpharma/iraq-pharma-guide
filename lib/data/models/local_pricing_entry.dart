class LocalPricingEntry {
  final int? id;
  final String barcode;
  final String tradeName;
  final double costPrice;
  final double sellingPrice;

  const LocalPricingEntry({
    this.id,
    required this.barcode,
    required this.tradeName,
    required this.costPrice,
    required this.sellingPrice,
  });

  double get profitMargin =>
      costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'barcode': barcode,
        'trade_name': tradeName,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
      };

  factory LocalPricingEntry.fromMap(Map<String, dynamic> m) =>
      LocalPricingEntry(
        id: m['id'] as int?,
        barcode: m['barcode'] as String? ?? '',
        tradeName: m['trade_name'] as String,
        costPrice: (m['cost_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (m['selling_price'] as num?)?.toDouble() ?? 0,
      );

  LocalPricingEntry copyWith({
    int? id,
    String? barcode,
    String? tradeName,
    double? costPrice,
    double? sellingPrice,
  }) =>
      LocalPricingEntry(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        tradeName: tradeName ?? this.tradeName,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
      );
}
