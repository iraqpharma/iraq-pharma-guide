import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('المظهر'),
          Card(
            child: SwitchListTile(
              title: const Text('الوضع الداكن'),
              secondary: const Icon(Icons.dark_mode),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('اللغة'),
          Card(
            child: Column(
              children: [
                RadioListTile<Locale>(
                  title: const Text('العربية'),
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
          _SectionTitle('عن التطبيق'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('إخلاء مسؤولية طبية'),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('تنبيه مهم'),
                  content: const Text(
                    'هذا التطبيق للأغراض التعليمية والمرجعية فقط.\n'
                    'لا يُغني عن استشارة الطبيب أو الصيدلاني.\n'
                    'المعلومات مستمدة من FDA وقد لا تعكس الواقع المحلي بالكامل.',
                    style: TextStyle(height: 1.7),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('موافق'),
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
              subtitle: const Text('الإصدار 1.0.0'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
