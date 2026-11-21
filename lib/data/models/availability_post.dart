/// إعلان صيدلية عن توفّر دواء عندها.
///
/// الفائدة العملية: دواء ناقص من السوق يبحث عنه صيدلاني لمريضه، فيجد
/// هنا من عنده منه بدل الاتصال بعشرين صيدلية. الإعلان يسري 30 يوماً ثم
/// ينتهي تلقائياً، ولا يظهر لأحد قبل موافقة الإدارة.
class AvailabilityPost {
  final int id;
  final String postedBy;
  final String pharmacyName;
  final String city;
  final String area;
  final String drugName;
  final String dosageForm;
  final String strength;
  final String quantityNote;
  final int? priceIqd;
  final String notes;
  final String contactPhone;
  final String contactWhatsapp;
  final String status;        // pending | approved | rejected | closed | expired
  final String rejectReason;
  final int views;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AvailabilityPost({
    required this.id,
    this.postedBy = '',
    required this.pharmacyName,
    required this.city,
    this.area = '',
    required this.drugName,
    this.dosageForm = '',
    this.strength = '',
    this.quantityNote = '',
    this.priceIqd,
    this.notes = '',
    required this.contactPhone,
    this.contactWhatsapp = '',
    this.status = 'pending',
    this.rejectReason = '',
    this.views = 0,
    required this.createdAt,
    this.expiresAt,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory AvailabilityPost.fromMap(Map<String, dynamic> m) => AvailabilityPost(
        id: (m['id'] as num).toInt(),
        postedBy: _s(m['posted_by']),
        pharmacyName: _s(m['pharmacy_name']),
        city: _s(m['city']),
        area: _s(m['area']),
        drugName: _s(m['drug_name']),
        dosageForm: _s(m['dosage_form']),
        strength: _s(m['strength']),
        quantityNote: _s(m['quantity_note']),
        priceIqd:
            m['price_iqd'] == null ? null : (m['price_iqd'] as num).toInt(),
        notes: _s(m['notes']),
        contactPhone: _s(m['contact_phone']),
        contactWhatsapp: _s(m['contact_whatsapp']),
        status: _s(m['status']).isEmpty ? 'pending' : _s(m['status']),
        rejectReason: _s(m['reject_reason']),
        views: m['views'] == null ? 0 : (m['views'] as num).toInt(),
        createdAt:
            DateTime.tryParse(_s(m['created_at']))?.toLocal() ?? DateTime.now(),
        expiresAt: DateTime.tryParse(_s(m['expires_at']))?.toLocal(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'posted_by': userId,
        'pharmacy_name': pharmacyName,
        'city': city,
        'area': area,
        'drug_name': drugName,
        'dosage_form': dosageForm,
        'strength': strength,
        'quantity_note': quantityNote,
        'price_iqd': priceIqd,
        'notes': notes,
        'contact_phone': contactPhone,
        'contact_whatsapp': contactWhatsapp,
        'status': 'pending',
      };

  // ── عرض ─────────────────────────────────────────────────────────────────

  static String money(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
      b.write(s[i]);
    }
    return b.toString();
  }

  String get titleLine => [drugName, strength].where((e) => e.isNotEmpty).join(' ');

  String get formLine =>
      [dosageForm, quantityNote].where((e) => e.isNotEmpty).join(' · ');

  String get priceAr =>
      priceIqd == null ? 'السعر عند الاتصال' : '${money(priceIqd!)} د.ع';

  String get locationAr => area.isEmpty ? city : '$city · $area';

  String get agoAr {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    if (d.inDays == 1) return 'قبل يوم';
    if (d.inDays < 30) return 'قبل ${d.inDays} يوماً';
    return 'قبل ${(d.inDays / 30).floor()} شهر';
  }

  /// الأيام المتبقية قبل انتهاء الإعلان.
  int get daysLeft {
    final e = expiresAt;
    if (e == null) return 0;
    final d = e.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  bool get isLive => status == 'approved' && daysLeft > 0;
}
