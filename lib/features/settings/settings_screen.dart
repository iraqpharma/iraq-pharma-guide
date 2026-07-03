import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: AppColors.primaryBlue),
              title: const Text('Iraq Pharma Guide'),
              subtitle: Text(s.appVersion),
              trailing: IconButton(
                icon: Icon(Icons.admin_panel_settings_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                tooltip: 'إدارة قاعدة البيانات',
                onPressed: () => context.push('/admin-pin'),
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
