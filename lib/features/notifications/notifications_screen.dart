import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/app_notification.dart';
import '../../providers/notification_provider.dart';

// ── Navigation helper ─────────────────────────────────────────────────────────
// الروابط الداخلية تبدأ بـ app://
// مثال: app:///price-guide   →  context.push('/price-guide')
//        app:///drug/42       →  context.push('/drug/42')
//        https://...          →  url_launcher
Future<void> handleActionUrl(BuildContext context, String url) async {
  if (url.isEmpty) return;

  if (url.startsWith('app://')) {
    final path = url.replaceFirst('app:/', '');
    if (context.mounted) context.push(path);
  } else {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);
    final svc         = ref.watch(notificationActionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('الإشعارات',
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorState(message: e.toString()),
        data: (notifications) {
          final valid     = notifications.where((n) => !n.isExpired).toList();
          final hasUnread = valid.any((n) => !n.isRead);
          if (valid.isEmpty) return const _EmptyState();

          final grouped = _groupByDate(valid);

          return Column(
            children: [
              if (hasUnread) _MarkAllBanner(onTap: () => svc.markAllAsRead()),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: _countItems(grouped),
                  itemBuilder: (ctx, i) {
                    final item = _itemAt(grouped, i);
                    if (item is String) return _DateHeader(label: item);
                    final notif = item as AppNotification;
                    return _NotificationTile(
                      notif: notif,
                      onTap: () {
                        svc.markAsRead(notif.id);
                        _openDetail(ctx, notif);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Map<String, List<AppNotification>> _groupByDate(
      List<AppNotification> list) {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final groups  = <String, List<AppNotification>>{
      'اليوم': [],
      'هذا الأسبوع': [],
      'أقدم': [],
    };
    for (final n in list) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        groups['اليوم']!.add(n);
      } else if (d.isAfter(weekAgo)) {
        groups['هذا الأسبوع']!.add(n);
      } else {
        groups['أقدم']!.add(n);
      }
    }
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  static int _countItems(Map<String, List<AppNotification>> g) {
    int c = 0;
    for (final e in g.entries) { c += 1 + e.value.length; }
    return c;
  }

  static dynamic _itemAt(Map<String, List<AppNotification>> g, int index) {
    int cursor = 0;
    for (final e in g.entries) {
      if (index == cursor) return e.key;
      cursor++;
      final local = index - cursor;
      if (local < e.value.length) return e.value[local];
      cursor += e.value.length;
    }
    return null;
  }

  void _openDetail(BuildContext context, AppNotification notif) {
    showDialog(
      context: context,
      builder: (_) => _NotificationDetailDialog(notif: notif),
    );
  }
}

// ── Date header ───────────────────────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.divider, height: 1)),
        ],
      ),
    );
  }
}

// ── Mark all banner ───────────────────────────────────────────────────────────
class _MarkAllBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _MarkAllBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.done_all_rounded, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Text('اضغط على الإشعار لفتحه وتعيينه كمقروء',
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('تعيين الكل',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotificationTile({required this.notif, required this.onTap});

  bool get _hasAction =>
      notif.actionUrl != null && notif.actionUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final type = notif.type;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: notif.isRead ? Colors.transparent : type.tint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة النوع
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان + الوقت + نقطة
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatTime(notif.createdAt),
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.textSecondary.withOpacity(0.65))),
                      if (!notif.isRead) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                              color: type.color, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // معاينة النص
                  Text(notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.textSecondary, height: 1.4)),

                  const SizedBox(height: 7),

                  // الصف الأخير: شارة النوع + زر التفاصيل
                  Row(
                    children: [
                      // شارة النوع
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type.icon, size: 10, color: type.color),
                            const SizedBox(width: 3),
                            Text(type.arabicLabel,
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: type.color,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 12, right: 4),
              child: Icon(Icons.chevron_left_rounded,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.35)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'الآن';
    if (diff.inMinutes < 60)  return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24)    return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1)     return 'منذ يوم';
    if (diff.inDays < 7)      return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30)     return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
    if (diff.inDays < 365)    return 'منذ ${(diff.inDays / 30).floor()} شهر';
    return 'منذ ${(diff.inDays / 365).floor()} سنة';
  }
}

// ── Detail dialog ─────────────────────────────────────────────────────────────
class _NotificationDetailDialog extends StatelessWidget {
  final AppNotification notif;
  const _NotificationDetailDialog({required this.notif});

  bool get _hasAction =>
      notif.actionUrl != null && notif.actionUrl!.trim().isNotEmpty;

  bool get _isInternal =>
      notif.actionUrl?.startsWith('app://') ?? false;

  @override
  Widget build(BuildContext context) {
    final type = notif.type;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── هيدر ملوّن ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: type.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(type.icon, color: type.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type.icon, size: 11, color: type.color),
                              const SizedBox(width: 4),
                              Text(type.arabicLabel,
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: type.color,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(notif.title,
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── النص الكامل ────────────────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(notif.body,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.7)),
              ),
            ),

            // ── زر التفاصيل (إذا يوجد action_url) ────────────────────
            if (_hasAction)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      handleActionUrl(context, notif.actionUrl!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _isInternal
                          ? Icons.launch_rounded
                          : Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    label: Text(
                        notif.actionLabel?.isNotEmpty == true
                            ? notif.actionLabel!
                            : 'اضغط للتفاصيل',
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

            // ── الفوتر: الوقت + الكود ──────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(20, _hasAction ? 12 : 10, 20, 20),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 5),
                  Text(_fullDate(notif.createdAt),
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.7))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      '#${notif.id.substring(0, 4).toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fullDate(DateTime dt) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}  $h:$m';
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_off_outlined,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('لا توجد إشعارات',
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('ستظهر هنا الإشعارات الجديدة عند وصولها',
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 60, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 14),
          Text('تعذّر تحميل الإشعارات',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
