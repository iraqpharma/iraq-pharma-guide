import 'dart:convert';

/// دواء يأخذه الزبون بانتظام.
class CustomerMed {
  final String name;
  final String dose;      // الجرعة كما تُصرف: قرص صباحاً ومساءً
  final String note;      // قبل الأكل، لا يُؤخذ مع الحليب…
  final int packDays;     // كم يوماً تكفي العلبة، للتذكير
  final DateTime? lastDispensed;

  const CustomerMed({
    required this.name,
    this.dose = '',
    this.note = '',
    this.packDays = 30,
    this.lastDispensed,
  });

  /// متى يُتوقّع أن ينفد ما صُرف آخر مرّة
  DateTime? get dueOn => lastDispensed?.add(Duration(days: packDays));

  /// بالسالب يعني تأخّر، بالموجب يعني ما تبقّى
  int? get daysLeft =>
      dueOn == null ? null : dueOn!.difference(DateTime.now()).inDays;

  CustomerMed copyWith({
    String? name,
    String? dose,
    String? note,
    int? packDays,
    DateTime? lastDispensed,
  }) =>
      CustomerMed(
        name: name ?? this.name,
        dose: dose ?? this.dose,
        note: note ?? this.note,
        packDays: packDays ?? this.packDays,
        lastDispensed: lastDispensed ?? this.lastDispensed,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose': dose,
        'note': note,
        'packDays': packDays,
        'lastDispensed': lastDispensed?.toIso8601String(),
      };

  factory CustomerMed.fromJson(Map<String, dynamic> j) => CustomerMed(
        name: (j['name'] ?? '') as String,
        dose: (j['dose'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        packDays: (j['packDays'] as num?)?.toInt() ?? 30,
        lastDispensed: j['lastDispensed'] == null
            ? null
            : DateTime.tryParse(j['lastDispensed'] as String),
      );
}

/// بطاقة زبون متكرّر.
///
/// تبقى على جهاز الصيدلاني وحده ولا تُرفع إلى أي خادم: هذه معلومات
/// صحّية تخصّ أشخاصاً، ورفعها يجعل التطبيق مسؤولاً عن بيانات مرضى أمام
/// المتجرين وأمام القانون. على الجهاز هي مجرّد دفتر خاص بصاحبه.
class CustomerCard {
  final String id;
  final String name;
  final String phone;
  final int? age;
  final String condition;     // السكري، ضغط، ربو…
  final String allergies;     // حساسية البنسلين…
  final String note;
  final List<CustomerMed> meds;
  final DateTime createdAt;
  final DateTime lastVisit;

  const CustomerCard({
    required this.id,
    required this.name,
    this.phone = '',
    this.age,
    this.condition = '',
    this.allergies = '',
    this.note = '',
    this.meds = const [],
    required this.createdAt,
    required this.lastVisit,
  });

  /// أقرب دواء يحتاج إعادة صرف، إن وُجد
  CustomerMed? get nextDue {
    final withDue = meds.where((m) => m.dueOn != null).toList()
      ..sort((a, b) => a.dueOn!.compareTo(b.dueOn!));
    return withDue.isEmpty ? null : withDue.first;
  }

  /// هل تأخّر عن موعد إعادة الصرف؟
  bool get isOverdue {
    final d = nextDue?.daysLeft;
    return d != null && d < 0;
  }

  /// هل يقترب موعده خلال أسبوع؟
  bool get isDueSoon {
    final d = nextDue?.daysLeft;
    return d != null && d >= 0 && d <= 7;
  }

  int get daysSinceVisit => DateTime.now().difference(lastVisit).inDays;

  CustomerCard copyWith({
    String? name,
    String? phone,
    int? age,
    String? condition,
    String? allergies,
    String? note,
    List<CustomerMed>? meds,
    DateTime? lastVisit,
  }) =>
      CustomerCard(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        age: age ?? this.age,
        condition: condition ?? this.condition,
        allergies: allergies ?? this.allergies,
        note: note ?? this.note,
        meds: meds ?? this.meds,
        createdAt: createdAt,
        lastVisit: lastVisit ?? this.lastVisit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'age': age,
        'condition': condition,
        'allergies': allergies,
        'note': note,
        'meds': meds.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastVisit': lastVisit.toIso8601String(),
      };

  factory CustomerCard.fromJson(Map<String, dynamic> j) => CustomerCard(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        age: (j['age'] as num?)?.toInt(),
        condition: (j['condition'] ?? '') as String,
        allergies: (j['allergies'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        meds: ((j['meds'] ?? const []) as List)
            .map((e) => CustomerMed.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        createdAt:
            DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
        lastVisit: DateTime.tryParse('${j['lastVisit']}') ?? DateTime.now(),
      );

  static String encodeList(List<CustomerCard> l) =>
      jsonEncode(l.map((e) => e.toJson()).toList());

  static List<CustomerCard> decodeList(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CustomerCard.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
