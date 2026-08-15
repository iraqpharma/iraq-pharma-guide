import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'shared/router/app_router.dart';

class IraqPharmaApp extends ConsumerWidget {
  const IraqPharmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final isAr = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'Iraq Pharma Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Force RTL/LTR based on active locale — MaterialApp alone isn't
      // always sufficient when widgets use hardcoded Row children ordering.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          // Some Android skins (Samsung One UI in particular) ship a display
          // font scale well above 1.0. Every fixed-height control in this app
          // — the 52px primary button, the compact header — was laid out for
          // scale 1.0, so an unclamped scaler clips glyphs instead of growing
          // the box. Clamping is a no-op at the default scale and only caps
          // the extremes. Text still grows, just not past what the layout can
          // hold.
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.10,
            ),
          ),
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
