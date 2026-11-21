import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/customer_card.dart';

final customersProvider =
    StateNotifierProvider<CustomersNotifier, List<CustomerCard>>(
        (ref) => CustomersNotifier());

/// بطاقات الزبائن، محفوظة على الجهاز وحده.
///
/// لا يوجد أي رفع إلى الخادم هنا، عمداً. هذه معلومات صحّية تخصّ أشخاصاً
/// لم يوافقوا على تخزينها في أي مكان، والاحتفاظ بها محلّياً يجعلها
/// دفتر الصيدلاني الخاص لا قاعدة بيانات مرضى.
class CustomersNotifier extends StateNotifier<List<CustomerCard>> {
  static const _key = 'customer_cards_v1';
  SharedPreferences? _prefs;

  CustomersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) state = CustomerCard.decodeList(raw);
  }

  Future<void> _save() async {
    await _prefs?.setString(_key, CustomerCard.encodeList(state));
  }

  void add(CustomerCard c) {
    state = [c, ...state];
    _save();
  }

  void update(CustomerCard c) {
    state = state.map((e) => e.id == c.id ? c : e).toList();
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  /// يسجّل زيارة جديدة ويحدّث تاريخ آخر صرف للأدوية المختارة.
  void recordVisit(String id, {Set<String> dispensed = const {}}) {
    final now = DateTime.now();
    state = state.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        lastVisit: now,
        meds: c.meds
            .map((m) => dispensed.contains(m.name)
                ? m.copyWith(lastDispensed: now)
                : m)
            .toList(),
      );
    }).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }
}

/// الزبائن الذين تأخّروا عن إعادة الصرف، أو اقترب موعدهم.
final dueCustomersProvider = Provider<List<CustomerCard>>((ref) {
  final all = ref.watch(customersProvider);
  final due = all.where((c) => c.isOverdue || c.isDueSoon).toList()
    ..sort((a, b) {
      final x = a.nextDue?.daysLeft ?? 9999;
      final y = b.nextDue?.daysLeft ?? 9999;
      return x.compareTo(y);
    });
  return due;
});
