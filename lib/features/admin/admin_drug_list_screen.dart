import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/drug_csv_service.dart';
import '../../data/models/drug_model.dart';

class AdminDrugListScreen extends StatefulWidget {
  const AdminDrugListScreen({super.key});
  @override
  State<AdminDrugListScreen> createState() => _AdminDrugListScreenState();
}

class _AdminDrugListScreenState extends State<AdminDrugListScreen> {
  final _searchCtrl = TextEditingController();
  List<Drug> _drugs = [];
  bool _loading = true;
  bool _busy = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final drugs = await DatabaseHelper.instance.getAllDrugs(query: _query);
    if (mounted) setState(() { _drugs = drugs; _loading = false; });
  }

  Future<void> _confirmDelete(Drug d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف الدواء', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف "${d.genericName}" نهائياً من القاعدة؟',
            style: GoogleFonts.ibmPlexSansArabic()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('حذف', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteDrug(d.id);
      _load();
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _busy = true);
    try {
      final file = await DrugCsvService.exportToCsv();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'نسخة قاعدة بيانات Iraq Pharma Guide',
      );
    } catch (e) {
      if (mounted) _showMessage('فشل التصدير: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('استيراد البيانات', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: Text(
          'سيتم تحديث الأدوية المطابقة بالرقم (id) وإضافة أي صفوف جديدة. هل تريد المتابعة؟',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
            child: Text('استيراد', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final res = await DrugCsvService.importFromCsv(File(result.files.single.path!));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('نتيجة الاستيراد', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أضيف: ${res.inserted}', style: GoogleFonts.ibmPlexSansArabic()),
              Text('حُدّث: ${res.updated}', style: GoogleFonts.ibmPlexSansArabic()),
              Text('تخطّي: ${res.skipped}', style: GoogleFonts.ibmPlexSansArabic()),
              if (res.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('الأخطاء:', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
                ...res.errors.take(10).map((e) => Text('• $e', style: GoogleFonts.ibmPlexSansArabic(fontSize: 12))),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('حسناً', style: GoogleFonts.ibmPlexSansArabic())),
          ],
        ),
      );
      _load();
    } catch (e) {
      if (mounted) _showMessage('فشل الاستيراد: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
      backgroundColor: isError ? Colors.red.shade400 : AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('إدارة الأدوية (${_drugs.length})',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            tooltip: 'استيراد من CSV',
            icon: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
            onPressed: _busy ? null : _importCsv,
          ),
          IconButton(
            tooltip: 'تصدير إلى CSV',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: _busy ? null : _exportCsv,
          ),
        ],
      ),
      body: Column(children: [
        if (_busy) const LinearProgressIndicator(color: AppColors.primary, minHeight: 3),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم العربي أو الإنجليزي...',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                      _searchCtrl.clear(); setState(() => _query = ''); _load();
                    })
                  : null,
              filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: (v) { setState(() => _query = v); _load(); },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _drugs.isEmpty
                  ? Center(child: Text('لا توجد نتائج', style: GoogleFonts.ibmPlexSansArabic(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: _drugs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final d = _drugs[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            title: Text(d.genericName,
                                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            subtitle: Text(d.genericNameAr.isEmpty ? '(بدون ترجمة عربية)' : d.genericNameAr,
                                style: GoogleFonts.ibmPlexSansArabic(fontSize: 12,
                                    color: d.genericNameAr.isEmpty ? Colors.orange : Theme.of(context).colorScheme.onSurfaceVariant)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                onPressed: () => context.push('/admin/drug/${d.id}').then((_) => _load()),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                onPressed: () => _confirmDelete(d),
                              ),
                            ]),
                            onTap: () => context.push('/admin/drug/${d.id}').then((_) => _load()),
                          ),
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/drug/new').then((_) => _load()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('إضافة دواء', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
