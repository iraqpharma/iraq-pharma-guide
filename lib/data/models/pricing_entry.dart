class PricingEntry {
  final String id;
  final String barcode;
  final String tradeName;
  final double sellingPrice;
  final String? notes;
  final int viewCount;
  final DateTime updatedAt;

  const PricingEntry({
    required this.id,
    required this.barcode,
    required this.tradeName,
    required this.sellingPrice,
    this.notes,
    this.viewCount = 0,
    required this.updatedAt,
  });

  factory PricingEntry.fromJson(Map<String, dynamic> json) => PricingEntry(
        id: json['id'] as String,
        barcode: json['barcode'] as String? ?? '',
        tradeName: json['trade_name'] as String,
        sellingPrice: (json['selling_price'] as num).toDouble(),
        notes: json['notes'] as String?,
        viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
