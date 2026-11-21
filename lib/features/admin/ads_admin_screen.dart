import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_admin_service.dart';

/// الإعلانات التجارية في الشاشة الرئيسية — تشغيل وإيقاف.
///
/// الرفع نفسه يبقى من لوحة سوبابيس (الصورة إلى bucket `ads` ثم صف في
/// جدول `advertisements`)، وهذه الشاشة للتحكّم السريع بما يظهر للمستخدم.
class AdsAdminScreen extends StatefulWidget {
  const AdsAdminScreen({super.key});

  @override
  State<AdsAdminScreen> createState() => _AdsAdminScreenState();
}

class _AdsAdminScreenState extends State<AdsAdminScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _future = AppAdminService.instance.advertisements());
  }

  Future<void> _toggle(Map<String, dynamic> ad, bool v) async {
    try {
      await AppAdminService.instance.setAdActive(ad['id'].toString(), v);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر التحديث: $e'),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعلانات التجارية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ads = snap.data ?? const <Map<String, dynamic>>[];
          if (ads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                    'لا إعلانات بعد\nارفع الصورة إلى bucket «ads» في سوبابيس '
                    'ثم أضف صفاً في جدول advertisements',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.7,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: ads.length,
              itemBuilder: (_, i) {
                final ad     = ads[i];
                final active = ad['is_active'] == true;
                final img    = (ad['image_url'] ?? '').toString();
                final link   = (ad['action_url'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.dividerColor.withOpacity(0.35)),
                  ),
                  child: Column(children: [
                    if (img.isNotEmpty)
                      Opacity(
                        opacity: active ? 1 : 0.4,
                        child: AspectRatio(
                          aspectRatio: 3,
                          child: CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: theme.dividerColor.withOpacity(0.15)),
                            errorWidget: (_, __, ___) => Container(
                              color: theme.dividerColor.withOpacity(0.15),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    SwitchListTile(
                      value: active,
                      onChanged: (v) => _toggle(ad, v),
                      title: Text(active ? 'ظاهر للمستخدمين' : 'موقوف',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: active
                                ? AppColors.successGreen
                                : theme.colorScheme.onSurfaceVariant,
                          )),
                      subtitle: link.isEmpty
                          ? null
                          : Text(link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5)),
                    ),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
