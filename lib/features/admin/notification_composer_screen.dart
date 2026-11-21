import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../services/haptics_service.dart';

/// إرسال إشعار من داخل التطبيق.
///
/// الإدراج في جدول notifications يُشغّل نفس الـ trigger الذي يُشغّله
/// الإدراج من لوحة سوبابيس، فيمرّ الإشعار على نفس مسار FCM ويصل بنفس
/// الطريقة. لا منطق إرسال جديد هنا، فلا خطر على ما ضُبط سابقاً.
class NotificationComposerScreen extends StatefulWidget {
  const NotificationComposerScreen({super.key});

  @override
  State<NotificationComposerScreen> createState() =>
      _NotificationComposerScreenState();
}

class _NotificationComposerScreenState
    extends State<NotificationComposerScreen> {
  final _title  = TextEditingController();
  final _body   = TextEditingController();
  final _url    = TextEditingController();
  final _label  = TextEditingController();

  String _type = 'general';
  int _expireDays = 14;
  bool _busy = false;

  List<Map<String, dynamic>> _sent = [];

  static const _types = <String, (String, IconData, Color)>{
    'general': ('عام',       Icons.campaign_outlined,      Color(0xFF3A72B8)),
    'update':  ('تحديث',     Icons.system_update_outlined, Color(0xFF2E8F63)),
    'alert':   ('تنبيه مهم', Icons.warning_amber_rounded,  Color(0xFFD9534F)),
    'price':   ('أسعار',     Icons.price_change_outlined,  Color(0xFF7A4EA8)),
    'promo':   ('ترويج',     Icons.local_offer_outlined,   Color(0xFFD08A3E)),
  };

  @override
  void initState() {
    super.initState();
    _loadSent();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _url.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _loadSent() async {
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .isFilter('user_id', null)
          .order('created_at', ascending: false)
          .limit(25);
      if (mounted) {
        setState(() => _sent = (rows as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final t = _title.text.trim();
    final b = _body.text.trim();
    if (t.length < 3 || b.length < 3) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اكتب عنواناً ونصّاً للإشعار')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تأكيد الإرسال', style: TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('سيصل هذا الإشعار إلى كل مستخدمي التطبيق فوراً، '
              'ولا يمكن سحبه بعد وصوله إلى الهواتف',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(b, style: const TextStyle(fontSize: 12, height: 1.6)),
              ],
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('أرسل للجميع'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await Supabase.instance.client.from('notifications').insert({
        'title': t,
        'body': b,
        'type': _type,
        'user_id': null, // للجميع
        'expires_at': DateTime.now()
            .add(Duration(days: _expireDays))
            .toUtc()
            .toIso8601String(),
        if (_url.text.trim().isNotEmpty) 'action_url': _url.text.trim(),
        if (_label.text.trim().isNotEmpty) 'action_label': _label.text.trim(),
      });
      if (!mounted) return;
      Haptics.celebrate();
      _title.clear();
      _body.clear();
      _url.clear();
      _label.clear();
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('أُرسل الإشعار')));
      _loadSent();
    } catch (e) {
      if (!mounted) return;
      Haptics.error();
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذّر الإرسال: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف الإشعار', style: TextStyle(fontSize: 16)),
        content: const Text(
            'يُحذف من داخل التطبيق فقط. الإشعار الذي وصل إلى الهواتف '
            'لا يمكن سحبه',
            style: TextStyle(fontSize: 13, height: 1.8)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white),
            child: const Text('احذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', n['id']);
      Haptics.heavy();
      _loadSent();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إرسال إشعار',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _card(isDark, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوع الإشعار',
                  style:
                      TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (final e in _types.entries)
                  _typeChip(e.key, e.value.$1, e.value.$2, e.value.$3),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                maxLength: 60,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: const TextStyle(fontSize: 12.5),
                  helperText: 'يظهر سطراً عريضاً في إشعار الهاتف',
                  helperStyle: const TextStyle(fontSize: 11),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _body,
                maxLines: 4,
                maxLength: 240,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'النص',
                  labelStyle: const TextStyle(fontSize: 12.5),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _label,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'نصّ الزرّ (اختياري)',
                      hintText: 'افتح القسم',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintStyle: const TextStyle(fontSize: 11.5),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _url,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'الوجهة (اختياري)',
                      hintText: '/clinic-today',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintStyle: const TextStyle(fontSize: 11.5),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const Text('يبقى داخل التطبيق',
                  style:
                      TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 7, children: [
                for (final d in [3, 7, 14, 30])
                  ChoiceChip(
                    label: Text('$d يوماً',
                        style: const TextStyle(fontSize: 12)),
                    selected: _expireDays == d,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _expireDays = d);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.16),
                    backgroundColor: Colors.transparent,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        color: _expireDays == d
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: _expireDays == d
                            ? FontWeight.bold
                            : FontWeight.normal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: BorderSide(
                          color: _expireDays == d
                              ? AppColors.primary.withOpacity(0.4)
                              : (isDark
                                  ? Colors.white24
                                  : const Color(0xFFDFE4E8))),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: _busy
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 19),
                  label: const Text('أرسل لكل المستخدمين',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
          )),
          if (_sent.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 20, 4, 9),
              child: Text('آخر ما أُرسل',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            ),
            for (final n in _sent) _sentTile(n, isDark, theme),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String key, String label, IconData icon, Color c) {
    final on = _type == key;
    return InkWell(
      onTap: () {
        Haptics.select();
        setState(() => _type = key);
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(on ? 0.16 : 0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: c.withOpacity(on ? 0.5 : 0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.bold : FontWeight.w500,
                  color: c)),
        ]),
      ),
    );
  }

  Widget _sentTile(
      Map<String, dynamic> n, bool isDark, ThemeData theme) {
    final t  = '${n['type'] ?? 'general'}';
    final cf = _types[t] ?? _types['general']!;
    final at = DateTime.tryParse('${n['created_at']}')?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cf.$3.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(cf.$2, size: 17, color: cf.$3),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${n['title'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                  at == null
                      ? '${n['body'] ?? ''}'
                      : '${at.year}/${at.month}/${at.day}  ·  ${n['body'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'احذف من داخل التطبيق',
          onPressed: () => _delete(n),
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.errorRed),
        ),
      ]),
    );
  }

  Widget _card(bool isDark, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: child,
    );
  }
}
