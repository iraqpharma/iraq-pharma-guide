import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_admin_service.dart';

/// من سجّل في التطبيق اليوم، أو هذا الأسبوع، أو هذا الشهر.
///
/// الرقم وحده لا يُفيد: المهم من هم، ومن أي محافظة، وأي مهنة، وهل
/// أكملوا ملفاتهم. القراءة تمرّ على دالّة محميّة في القاعدة لا تستجيب
/// إلا لحساب إداري.
class RegistrantsScreen extends StatefulWidget {
  final String period;   // today | week | month
  final String title;
  const RegistrantsScreen(
      {super.key, required this.period, required this.title});

  @override
  State<RegistrantsScreen> createState() => _RegistrantsScreenState();
}

class _RegistrantsScreenState extends State<RegistrantsScreen> {
  List<Registrant>? _rows;
  String? _error;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final r = await AppAdminService.instance.registrants(widget.period);
      if (mounted) setState(() => _rows = r);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e.toString().contains('not authorized')
                ? 'هذه القائمة للمدراء فقط'
                : 'تعذّر التحميل. تحقّق من الاتصال');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _rows ?? const <Registrant>[];
    final rows = _q.trim().isEmpty
        ? all
        : all
            .where((r) =>
                r.name.contains(_q) ||
                r.city.contains(_q) ||
                r.role.contains(_q) ||
                r.specialty.contains(_q))
            .toList();

    // توزيع حسب المهنة، يُقرأ بلمحة
    final byRole = <String, int>{};
    for (final r in all) {
      final k = r.role.trim().isEmpty ? 'غير محدّد' : r.role.trim();
      byRole[k] = (byRole[k] ?? 0) + 1;
    }
    final roleList = byRole.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 21)),
        ],
      ),
      body: _error != null
          ? _msg(theme, Icons.lock_outline_rounded, _error!)
          : _rows == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : all.isEmpty
                  ? _msg(theme, Icons.person_off_outlined,
                      'لا تسجيلات في هذه المدّة')
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: TextField(
                          onChanged: (v) => setState(() => _q = v),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'ابحث بالاسم أو المحافظة أو المهنة',
                            hintStyle: const TextStyle(fontSize: 12.5),
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 19),
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                        ),
                      ),
                      if (roleList.isNotEmpty)
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            children: [
                              for (final e in roleList.take(6))
                                Container(
                                  margin:
                                      const EdgeInsetsDirectional.only(end: 7),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.18)),
                                  ),
                                  child: Text('${e.key}  ${e.value}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary)),
                                ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(14, 8, 14, 28),
                            itemCount: rows.length,
                            itemBuilder: (_, i) => _tile(rows[i], theme),
                          ),
                        ),
                      ),
                    ]),
    );
  }

  Widget _tile(Registrant r, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final incomplete = r.name.trim().isEmpty || r.role.trim().isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: Row(children: [
        _avatar(r),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name.trim().isEmpty ? 'بلا اسم' : r.name,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: r.name.trim().isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface)),
              const SizedBox(height: 3),
              Text(r.subtitle,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 5),
              Row(children: [
                _pill(Icons.search_rounded, '${r.searches}',
                    const Color(0xFF3C7FB0)),
                const SizedBox(width: 6),
                _pill(Icons.handyman_outlined, '${r.toolUses}',
                    const Color(0xFF2E8B82)),
                const SizedBox(width: 6),
                Text(_ago(r.createdAt),
                    style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ],
          ),
        ),
        if (incomplete)
          Tooltip(
            message: 'ملف ناقص',
            child: Icon(Icons.error_outline_rounded,
                size: 17, color: AppColors.warningAmber),
          ),
      ]),
    );
  }

  Widget _avatar(Registrant r) {
    const size = 46.0;
    if (r.avatarUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: r.avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initials(r),
          errorWidget: (_, __, ___) => _initials(r),
        ),
      );
    }
    return _initials(r);
  }

  Widget _initials(Registrant r) => Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(r.initials,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      );

  Widget _pill(IconData i, String v, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 11, color: c),
          const SizedBox(width: 3),
          Text(v,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.bold, color: c)),
        ]),
      );

  Widget _msg(ThemeData theme, IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 52,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      );

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    return 'قبل ${d.inDays} يوماً';
  }
}
