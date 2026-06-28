import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class InteractiveReferenceScreen extends StatefulWidget {
  const InteractiveReferenceScreen({super.key});
  @override
  State<InteractiveReferenceScreen> createState() => _InteractiveReferenceScreenState();
}

class _InteractiveReferenceScreenState extends State<InteractiveReferenceScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await _client
          .from('interactive_reference')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      if (!mounted) return;
      setState(() => _notes = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteNote(String id) async {
    await _client.from('interactive_reference').delete().eq('id', id);
    _loadNotes();
  }

  void _openEditor({Map<String, dynamic>? note}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditorSheet(note: note, onSaved: _loadNotes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('المرجع التفاعلي',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('إضافة', style: GoogleFonts.ibmPlexSansArabic(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notes.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _NoteCard(
                      note: _notes[i],
                      onEdit: () => _openEditor(note: _notes[i]),
                      onDelete: () => _confirmDelete(_notes[i]['id'] as String),
                    ),
                  ),
                ),
      floatingActionButton: _notes.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openEditor(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 40),
      ),
      const SizedBox(height: 20),
      Text('لا توجد ملاحظات بعد',
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('أضف بروتوكولاتك وملاحظاتك المهنية هنا',
          style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text('إضافة ملاحظة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    ]),
  );

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف الملاحظة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف هذه الملاحظة نهائياً؟',
            style: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('حذف', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteNote(id);
  }
}

// ── Note card ─────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.tryParse(note['updated_at'] as String? ?? '');
    final dateStr = updatedAt != null
        ? '${updatedAt.year}/${updatedAt.month.toString().padLeft(2,'0')}/${updatedAt.day.toString().padLeft(2,'0')}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(note['title'] as String? ?? '',
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('تعديل', style: GoogleFonts.ibmPlexSansArabic()),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text('حذف', style: GoogleFonts.ibmPlexSansArabic(color: Colors.red.shade400)),
                    ])),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ]),
              const SizedBox(height: 10),
              Text(note['content'] as String? ?? '',
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(dateStr,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Note editor bottom sheet ───────────────────────────────────────────────────
class _NoteEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? note;
  final VoidCallback onSaved;
  const _NoteEditorSheet({this.note, required this.onSaved});
  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  final _client   = Supabase.instance.client;
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.note?['title'] as String? ?? '');
    _contentCtrl = TextEditingController(text: widget.note?['content'] as String? ?? '');
  }

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('not logged in');
      final now = DateTime.now().toIso8601String();
      if (widget.note != null) {
        await _client.from('interactive_reference').update({
          'title':      _titleCtrl.text.trim(),
          'content':    _contentCtrl.text.trim(),
          'updated_at': now,
        }).eq('id', widget.note!['id'] as String);
      } else {
        await _client.from('interactive_reference').insert({
          'user_id':    uid,
          'title':      _titleCtrl.text.trim(),
          'content':    _contentCtrl.text.trim(),
          'updated_at': now,
        });
      }
      if (mounted) { widget.onSaved(); Navigator.pop(context); }
    } catch (_) {
      setState(() { _saving = false; _error = 'فشل الحفظ، حاول مجدداً'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(widget.note != null ? 'تعديل الملاحظة' : 'ملاحظة جديدة',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleCtrl,
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
            decoration: _deco('العنوان', Icons.title_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل عنوان الملاحظة' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentCtrl,
            textAlign: TextAlign.right,
            maxLines: 6, minLines: 4,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, height: 1.6),
            decoration: _deco('المحتوى', Icons.notes_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل محتوى الملاحظة' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.ibmPlexSansArabic(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('حفظ الملاحظة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
    filled: true, fillColor: const Color(0xFFF8F9FA),
    labelStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}
