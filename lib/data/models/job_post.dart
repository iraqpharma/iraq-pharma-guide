/// إعلان فرصة عمل لصيدلاني — الإصدار 3.0
class JobPost {
  final int id;
  final String postedBy;
  final String pharmacyName;
  final String city;
  final String area;
  final String addressNote;
  final String jobTitle;
  final String workType;        // full_time | part_time | shift | temporary
  final String shiftText;
  final String hoursText;
  final String daysText;
  final bool salaryNegotiable;
  final int? salaryMin;
  final int? salaryMax;
  final String salaryPeriod;    // monthly | daily | hourly
  final String currency;
  final String genderPref;      // any | male | female
  final String experienceText;
  final String description;
  final String contactName;
  final String contactPhone;
  final String contactWhatsapp;
  final String status;          // pending | approved | rejected | closed | expired
  final String rejectReason;
  final int views;
  /// عدد من ضغط «اتصال» أو «واتساب» على الإعلان.
  final int contactClicks;
  /// عدد الإعجابات — يُحدَّث بمُشغّل في قاعدة البيانات لا من التطبيق.
  final int likes;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const JobPost({
    required this.id,
    required this.postedBy,
    required this.pharmacyName,
    required this.city,
    this.area = '',
    this.addressNote = '',
    this.jobTitle = 'صيدلاني',
    this.workType = 'full_time',
    this.shiftText = '',
    this.hoursText = '',
    this.daysText = '',
    this.salaryNegotiable = false,
    this.salaryMin,
    this.salaryMax,
    this.salaryPeriod = 'monthly',
    this.currency = 'IQD',
    this.genderPref = 'any',
    this.experienceText = '',
    this.description = '',
    this.contactName = '',
    required this.contactPhone,
    this.contactWhatsapp = '',
    this.status = 'pending',
    this.rejectReason = '',
    this.views = 0,
    this.contactClicks = 0,
    this.likes = 0,
    required this.createdAt,
    this.expiresAt,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory JobPost.fromMap(Map<String, dynamic> m) => JobPost(
        id: (m['id'] as num).toInt(),
        postedBy: _s(m['posted_by']),
        pharmacyName: _s(m['pharmacy_name']),
        city: _s(m['city']),
        area: _s(m['area']),
        addressNote: _s(m['address_note']),
        jobTitle: _s(m['job_title']).isEmpty ? 'صيدلاني' : _s(m['job_title']),
        workType: _s(m['work_type']).isEmpty ? 'full_time' : _s(m['work_type']),
        shiftText: _s(m['shift_text']),
        hoursText: _s(m['hours_text']),
        daysText: _s(m['days_text']),
        salaryNegotiable: m['salary_negotiable'] == true,
        salaryMin: m['salary_min'] == null ? null : (m['salary_min'] as num).toInt(),
        salaryMax: m['salary_max'] == null ? null : (m['salary_max'] as num).toInt(),
        salaryPeriod: _s(m['salary_period']).isEmpty ? 'monthly' : _s(m['salary_period']),
        currency: _s(m['currency']).isEmpty ? 'IQD' : _s(m['currency']),
        genderPref: _s(m['gender_pref']).isEmpty ? 'any' : _s(m['gender_pref']),
        experienceText: _s(m['experience_text']),
        description: _s(m['description']),
        contactName: _s(m['contact_name']),
        contactPhone: _s(m['contact_phone']),
        contactWhatsapp: _s(m['contact_whatsapp']),
        status: _s(m['status']).isEmpty ? 'pending' : _s(m['status']),
        rejectReason: _s(m['reject_reason']),
        views: m['views'] == null ? 0 : (m['views'] as num).toInt(),
        contactClicks: m['contact_clicks'] == null
            ? 0
            : (m['contact_clicks'] as num).toInt(),
        likes: m['likes'] == null ? 0 : (m['likes'] as num).toInt(),
        createdAt:
            DateTime.tryParse(_s(m['created_at']))?.toLocal() ?? DateTime.now(),
        expiresAt: DateTime.tryParse(_s(m['expires_at']))?.toLocal(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'posted_by': userId,
        'pharmacy_name': pharmacyName,
        'city': city,
        'area': area,
        'address_note': addressNote,
        'job_title': jobTitle,
        'work_type': workType,
        'shift_text': shiftText,
        'hours_text': hoursText,
        'days_text': daysText,
        'salary_negotiable': salaryNegotiable,
        'salary_min': salaryNegotiable ? null : salaryMin,
        'salary_max': salaryNegotiable ? null : salaryMax,
        'salary_period': salaryPeriod,
        'currency': currency,
        'gender_pref': genderPref,
        'experience_text': experienceText,
        'description': description,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_whatsapp': contactWhatsapp,
        'status': 'pending',
      };

  // ── عرض ─────────────────────────────────────────────────────────────────

  static const workTypeLabels = <String, String>{
    'full_time': 'دوام كامل',
    'part_time': 'دوام جزئي',
    'shift': 'وردية',
    'temporary': 'مؤقّت',
  };

  static const genderLabels = <String, String>{
    'any': 'بلا تفضيل',
    'male': 'ذكر',
    'female': 'أنثى',
  };

  static const periodLabels = <String, String>{
    'monthly': 'شهرياً',
    'daily': 'يومياً',
    'hourly': 'بالساعة',
  };

  String get workTypeAr => workTypeLabels[workType] ?? workType;

  static String _money(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// نص الراتب جاهزاً للعرض.
  String get salaryAr {
    if (salaryNegotiable || salaryMin == null) {
      return 'الراتب يُحدَّد عند المقابلة';
    }
    final unit = currency == 'IQD' ? 'د.ع' : currency;
    final period = periodLabels[salaryPeriod] ?? '';
    if (salaryMax != null && salaryMax != salaryMin) {
      return '${_money(salaryMin!)} – ${_money(salaryMax!)} $unit $period';
    }
    return '${_money(salaryMin!)} $unit $period';
  }

  String get locationAr =>
      area.isEmpty ? city : '$city · $area';

  /// «قبل ٣ أيام»
  String get agoAr {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    if (d.inDays == 1) return 'قبل يوم';
    if (d.inDays < 30) return 'قبل ${d.inDays} يوماً';
    return 'قبل ${(d.inDays / 30).floor()} شهر';
  }

  bool get isLive => status == 'approved';
}
