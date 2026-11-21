import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حالة النقص في الصيدلية.
enum ShortageStatus {
  /// نفد تماماً من الرفّ
  out,

  /// بقي القليل وسينفد قريباً
  low,

  /// أُمّن وعاد إلى الرفّ
  restocked,
}

ShortageStatus _statusFrom(String? s, {bool legacyDone = false}) {
  switch (s) {
    case 'out':
      return ShortageStatus.out;
    case 'low':
      return ShortageStatus.low;
    case 'restocked':
      return ShortageStatus.restocked;
  }
  // سجلات النسخ السابقة لم تكن تحمل حالة، كان فيها isDone فقط
  return legacyDone ? ShortageStatus.restocked : ShortageStatus.out;
}

String _statusKey(ShortageStatus s) => switch (s) {
      ShortageStatus.out       => 'out',
      ShortageStatus.low       => 'low',
      ShortageStatus.restocked => 'restocked',
    };

class NoteEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final ShortageStatus status;

  /// مسار صورة العلبة على الجهاز، لمن يصوّر الآن ويُكمل الاسم لاحقاً
  final String? photoPath;

  /// رقم الباركود إن أُضيف بالقراءة
  final String? barcode;

  /// ملاحظة حرّة: الكمّية المطلوبة، اسم المندوب، البديل المقترح
  final String note;

  const NoteEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.status = ShortageStatus.out,
    this.photoPath,
    this.barcode,
    this.note = '',
  });

  bool get isDone => status == ShortageStatus.restocked;

  /// السجل الذي فيه صورة بلا اسم ينتظر إكمالاً
  bool get needsName => text.trim().isEmpty && photoPath != null;

  NoteEntry copyWith({
    String? text,
    ShortageStatus? status,
    String? photoPath,
    String? barcode,
    String? note,
  }) =>
      NoteEntry(
        id: id,
        text: text ?? this.text,
        createdAt: createdAt,
        status: status ?? this.status,
        photoPath: photoPath ?? this.photoPath,
        barcode: barcode ?? this.barcode,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'status': _statusKey(status),
        'photoPath': photoPath,
        'barcode': barcode,
        'note': note,
        // نُبقي isDone للتوافق مع نسخة قديمة قد تقرأ الملف
        'isDone': status == ShortageStatus.restocked,
      };

  factory NoteEntry.fromJson(Map<String, dynamic> j) => NoteEntry(
        id: j['id'] as String,
        text: (j['text'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: _statusFrom(j['status'] as String?,
            legacyDone: j['isDone'] as bool? ?? false),
        photoPath: j['photoPath'] as String?,
        barcode: j['barcode'] as String?,
        note: (j['note'] ?? '') as String,
      );
}

final notebookProvider =
    StateNotifierProvider<NotebookNotifier, List<NoteEntry>>(
        (ref) => NotebookNotifier());

class NotebookNotifier extends StateNotifier<List<NoteEntry>> {
  static const _key = 'pharmacy_notebook';
  SharedPreferences? _prefs;

  NotebookNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        state = (jsonDecode(raw) as List)
            .map((e) => NoteEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // ملف تالف لا يُفقد التطبيق: نبدأ فارغين بدل الانهيار
        state = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void add(
    String text, {
    ShortageStatus status = ShortageStatus.out,
    String? photoPath,
    String? barcode,
    String note = '',
  }) {
    if (text.trim().isEmpty && photoPath == null && barcode == null) return;
    state = [
      NoteEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text.trim(),
        createdAt: DateTime.now(),
        status: status,
        photoPath: photoPath,
        barcode: barcode,
        note: note.trim(),
      ),
      ...state,
    ];
    _save();
  }

  void setStatus(String id, ShortageStatus s) {
    state =
        state.map((e) => e.id == id ? e.copyWith(status: s) : e).toList();
    _save();
  }

  /// يدوّر الحالة بضغطة واحدة: نفد ← على وشك ← أُمّن ← نفد
  void cycle(String id) {
    state = state.map((e) {
      if (e.id != id) return e;
      final next = switch (e.status) {
        ShortageStatus.out       => ShortageStatus.low,
        ShortageStatus.low       => ShortageStatus.restocked,
        ShortageStatus.restocked => ShortageStatus.out,
      };
      return e.copyWith(status: next);
    }).toList();
    _save();
  }

  void toggle(String id) => cycle(id);

  void edit(String id, {String? text, String? note}) {
    state = state
        .map((e) => e.id == id ? e.copyWith(text: text, note: note) : e)
        .toList();
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  void clearDone() {
    state = state.where((e) => !e.isDone).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }
}
