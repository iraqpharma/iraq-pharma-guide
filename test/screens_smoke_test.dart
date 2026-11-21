// فحص رسم لكل شاشات المستخدم: تُبنى كل شاشة من جدول المسارات الحقيقي بحجمَي
// هاتف، ويُسجَّل أي خطأ بناء أو تخطيط. لا شبكة ولا قاعدة بيانات في الاختبار،
// فالشاشات تُفحص في حالات «التحميل/تعذّر الاتصال/الفارغ» وهي أكثر ما يُهمَل.
//   flutter test test/screens_smoke_test.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iraq_pharma_guide/core/theme/app_theme.dart';
import 'package:iraq_pharma_guide/shared/router/app_router.dart';

final _fam = Uri.encodeComponent('Lipid agents — other');
final _paths = <String>[
  '/home', '/login', '/signup', '/forgot-password',
  '/category/all', '/category/cardiovascular', '/category/cardiovascular/all',
  '/category/cardiovascular/family/$_fam',
  '/category/oncology/family/${Uri.encodeComponent('CDK4/6 inhibitors')}',
  '/quick-filter/pregnancy', '/quick-filter/cold', '/quick-filter/renal', '/quick-filter/drops',
  '/drug/1', '/settings', '/calc', '/renal-calc', '/interactions', '/chemo-dose',
  '/sources', '/notebook', '/price-guide', '/notifications', '/pricing-calc',
  '/substitution', '/otc', '/jobs', '/jobs/new', '/jobs/mine',
  '/clinic-today', '/clinic-today/quiz', '/clinic-today/drug', '/clinic-today/case',
  '/clinic-today/interactions', '/clinic-today/speed', '/availability', '/fluid-calc',
  '/customers', '/shelf-life', '/supply-days', '/lab-units', '/vaccine-schedule',
  '/videos', '/profile', '/edit-profile', '/support', '/suggestion',
  '/legal/privacy', '/legal/terms', '/legal/disclaimer',
];
// (الحجم، اللغة، تكبير الخط، الوضع الداكن). 1.10 هو أقصى تكبير يسمح به app.dart.
const _sizes = <String, (Size, String, double, bool)>{
  'android-360x740-ar': (Size(360, 740), 'ar', 1.0, false),
  'iphone-393x852-ar': (Size(393, 852), 'ar', 1.0, false),
  'android-360x740-ar-x1.10-dark': (Size(360, 740), 'ar', 1.10, true),
  'android-360x740-en-x1.10': (Size(360, 740), 'en', 1.10, false),
};
bool _noise(String e) =>
    e.contains('google_fonts') || e.contains('MissingPluginException') ||
    e.contains('SocketException') || e.contains('HttpException') ||
    e.contains('ClientException') || e.contains('PostgrestException') ||
    e.contains('AuthException') || e.contains('databaseFactory') ||
    e.contains('Bad state: No element') && e.contains('sqflite') ||
    e.contains('HTTP request failed') || e.contains('FirebaseException') ||
    e.contains('No Firebase App') || e.contains('PlatformException') ||
    e.contains('Unable to load asset') || e.contains('StorageException') ||
    e.contains('RealtimeSubscribeException') || e.contains('WebSocket');

void main() {
  final report = <String>[];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GoogleFonts.config.allowRuntimeFetching = false;
    // خط الاختبار الافتراضي (Ahem) أعرض بكثير من الخط الحقيقي فيُظهر تجاوزات
    // وهمية. نحمّل الخطوط الحقيقية (test/fonts) تحت أسماء العائلات التي يطلبها
    // google_fonts حتى تكون قياسات النص مطابقة للجهاز.
    ByteData f(String n) => ByteData.sublistView(File('test/fonts/$n.ttf').readAsBytesSync());
    Future<void> reg(String family, String file) =>
        (FontLoader(family)..addFont(Future.value(f(file)))).load();
    const weights = {
      '': 'Regular', '_regular': 'Regular', '_100': 'Regular', '_200': 'Regular',
      '_300': 'Regular', '_italic': 'Regular', '_500': 'Medium', '_600': 'SemiBold',
      '_700': 'Bold', '_800': 'Bold', '_900': 'Bold', '_700italic': 'Bold',
    };
    for (final w in weights.entries) {
      final cairo = (w.value == 'Regular' || w.value == 'Medium') ? 'Regular' : 'Bold';
      await reg('Cairo${w.key}', 'Cairo-$cairo');
      for (final fam in const ['IBMPlexSansArabic', 'IBM Plex Sans Arabic', 'Inter', 'IBMPlexMono', 'IBM Plex Mono']) {
        await reg('$fam${w.key}', 'IBMPlexSansArabic-${w.value}');
      }
    }
    // النصوص التي لا تحدّد خطاً (خط النظام) تُقاس بالخط الأساسي للتطبيق.
    for (final sys in const ['Roboto', '.SF UI Text', '.SF UI Display', 'CupertinoSystemText', 'CupertinoSystemDisplay', 'Segoe UI']) {
      await reg(sys, 'IBMPlexSansArabic-Regular');
    }
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(), detectSessionInUri: false, autoRefreshToken: false),
    );
  });
  tearDownAll(() {
    File('screens_report.txt').writeAsStringSync(report.join('\n'));
  });

  for (final sz in _sizes.entries) {
    for (final path in _paths) {
      testWidgets('${sz.key} $path', (t) async {
        final (size, lang, scale, dark) = sz.value;
        SharedPreferences.setMockInitialValues(<String, Object>{'locale': lang});
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final errs = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final where = RegExp(r'file:///\S+?/lib/(\S+)').firstMatch(d.toString())?.group(1) ?? '';
          errs.add('${d.exceptionAsString().split('\n').take(3).join(' ⏎ ')}  @ $where');
        };
        try {
          final router = GoRouter(initialLocation: path, routes: appRouter.configuration.routes);
          await t.pumpWidget(ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              theme: dark ? AppTheme.dark : AppTheme.light,
              locale: Locale(lang),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: child!),
              ),
            ),
          ));
          for (var i = 0; i < 6; i++) {
            await t.pump(const Duration(milliseconds: 350));
          }
        } catch (e) {
          errs.add('THROW: ${e.toString().split('\n').first}');
        }
        Object? ex;
        while ((ex = t.takeException()) != null) {
          errs.add('EXC: ${ex.toString().split('\n').take(2).join(' ⏎ ')}');
        }
        FlutterError.onError = old;
        final real = errs.where((e) => !_noise(e)).toSet().toList();
        final shown = find.textContaining('تعذّر عرض هذا الجزء').evaluate().isNotEmpty;
        report.add('${real.isEmpty && !shown ? 'OK  ' : 'FAIL'} ${sz.key} $path'
            '${shown ? '  [شاشة الخطأ ظاهرة]' : ''}'
            '${real.isEmpty ? '' : '\n      ' + real.take(4).map((e) => e.length > 260 ? e.substring(0, 260) : e).join('\n      ')}');
        // أنهِ المؤقّتات المعلّقة حتى لا يفشل الاختبار بسببها
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 6));
      });
    }
  }
}
