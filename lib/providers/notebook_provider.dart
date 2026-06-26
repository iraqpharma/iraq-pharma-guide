import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteEntry {
  final String id;
  final String text;
  final bool isDone;
  final DateTime createdAt;

  const NoteEntry({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.createdAt,
  });

  NoteEntry copyWith({String? text, bool? isDone}) => NoteEntry(
        id: id,
        text: text ?? this.text,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteEntry.fromJson(Map<String, dynamic> j) => NoteEntry(
        id: j['id'] as String,
        text: j['text'] as String,
        isDone: j['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
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
      final list = (jsonDecode(raw) as List)
          .map((e) => NoteEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void add(String text) {
    if (text.trim().isEmpty) return;
    state = [
      NoteEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.trim(),
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    _save();
  }

  void toggle(String id) {
    state = state
        .map((e) => e.id == id ? e.copyWith(isDone: !e.isDone) : e)
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
