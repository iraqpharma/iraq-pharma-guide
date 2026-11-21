import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'shared/router/app_router.dart';

void _dismissKeyboard() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus != null && focus.hasFocus) focus.unfocus();
}

/// زر عائم صغير يظهر فوق الكيبورد ويُخفيه بضغطة واحدة.
class _KeyboardDismissBar extends StatelessWidget {
  const _KeyboardDismissBar();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    if (insets < 80) return const SizedBox.shrink();

    return Positioned(
      left: 14,
      right: 14,
      bottom: insets + 8,
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _dismissKeyboard,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_hide_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 7),
                    Text('إخفاء الكيبورد',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IraqPharmaApp extends ConsumerWidget {
  const IraqPharmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final isAr = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'دليل الأدوية العراقي',
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
            // أي لمسة على مكان فارغ تُغلق الكيبورد، فلا يبقى مغطّياً
            // على زر الرجوع أو على أزرار أسفل الشاشة.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismissKeyboard,
              child: Stack(
                children: [
                  child!,
                  // شريط «إخفاء الكيبورد»: يظهر فقط حين يكون الكيبورد مفتوحاً،
                  // فوقه مباشرة، فلا يبقى المستخدم محاصراً حين يغطّي الكيبورد
                  // زر الرجوع أو أزرار أسفل الشاشة.
                  const _KeyboardDismissBar(),
                ],
              ),
            ),
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
