import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../shared/widgets/section_intro.dart';
import '../../services/haptics_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(s.appearance),
          Card(
            child: SwitchListTile(
              title: Text(s.darkMode),
              secondary: const Icon(Icons.dark_mode),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 8),
          // الردّ اللمسي والصوتي: يُشعر الصيدلاني أن الإجابة سُجّلت دون
          // أن ينظر إلى الشاشة، ويُطفأ لمن يعمل في مكان يحتاج الهدوء.
          Card(
            child: Column(children: [
              SwitchListTile(
                title: Text((context.s.isAr ? 'الاهتزاز اللمسي' : 'Haptic feedback')),
                subtitle: Text(
                    (context.s.isAr ? 'نبضة خفيفة عند الإجابة والاختيار وقراءة الباركود' : 'A light pulse on answers, selections and barcode scans'),
                    style: TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.vibration_rounded),
                value: Haptics.hapticsOn,
                onChanged: (v) async {
                  await Haptics.setHaptics(v);
                  if (v) Haptics.select();
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text((context.s.isAr ? 'أصوات التفاعل' : 'Interaction sounds')),
                subtitle: Text(
                    (context.s.isAr ? 'نقرة عند الإجابة الصحيحة وتنبيه عند الخاطئة' : 'A click for correct answers and an alert for wrong ones'),
                    style: TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.volume_up_outlined),
                value: Haptics.soundsOn,
                onChanged: (v) async {
                  await Haptics.setSounds(v);
                  if (v) Haptics.success();
                  setState(() {});
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionTitle(s.language_),
          Card(
            child: Column(
              children: [
                RadioListTile<Locale>(
                  title: Text(s.arabicLabel),
                  value: const Locale('ar'),
                  groupValue: locale,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v!),
                ),
                RadioListTile<Locale>(
                  title: const Text('English'),
                  value: const Locale('en'),
                  groupValue: locale,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(s.aboutApp_),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(s.medicalDisclaimer),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.importantNotice),
                  content: Text(
                    s.disclaimerContent,
                    style: const TextStyle(height: 1.7),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.okLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // من فاتته شاشات التعريف أو أراد مراجعتها
          Card(
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text((context.s.isAr ? 'أعِد شرح الأقسام' : 'Replay section guides')),
              subtitle: Text((context.s.isAr ? 'تظهر شاشة التعريف مرّة أخرى عند فتح كل قسم' : 'Show the intro again when each section opens'),
                  style: TextStyle(fontSize: 12)),
              onTap: () async {
                await SectionIntro.resetAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text((context.s.isAr ? 'سيظهر شرح كل قسم عند فتحه مجدّداً' : 'Each section guide will show again when opened'))));
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: AppColors.primaryBlue),
              title: const Text('Iraq Pharma Guide'),
              subtitle: Text(s.appVersion),
              trailing: IconButton(
                icon: Icon(Icons.admin_panel_settings_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                tooltip: (context.s.isAr ? 'إعدادات التطبيق' : 'App settings'),
                onPressed: () =>
                    context.push('/admin-pin?to=/admin/app-settings'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
