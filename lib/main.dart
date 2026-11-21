import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'shared/router/app_router.dart';
import 'services/haptics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Play rejects apps that hold broad media permissions for a one-off
  // image selection. The avatar picker is exactly that, so route it through
  // the Android Photo Picker, which grants access to the chosen image only
  // and needs no permission. The media permissions are removed from the
  // manifest to match.
  final imagePicker = ImagePickerPlatform.instance;
  if (imagePicker is ImagePickerAndroid) {
    imagePicker.useAndroidPhotoPicker = true;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Handle deep links (OAuth + password reset)
  AppLinks().uriLinkStream.listen((uri) async {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  });

  // Navigate to reset-password screen on passwordRecovery event
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      appRouter.go('/reset-password');
    }
  });

  // Fire-and-forget: FCM setup (in particular fcm.getToken()) can take
  // several seconds on iOS. Awaiting it here was blocking the first frame
  // from rendering at all — the white-screen delay on launch. It's not
  // needed before the UI can show, so let it finish in the background.
  NotificationService.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  // في وضع الإصدار (release) تُستبدل أي استثناء في بناء الواجهة بشاشة
  // رمادية فارغة بلا نص، فتظهر للمستخدم «صفحة بيضاء» بلا أي دليل على
  // السبب — وهذا ما حدث في قسم مسكنات الألم. هذا البديل يُظهر رسالة
  // عربية مع نصّ الخطأ، فيصل الخطأ إلينا بصورة شاشة من المستخدم بدل
  // التخمين.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFFBFA),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 52, color: Color(0xFFC2454B)),
                const SizedBox(height: 14),
                const Text(
                  'حدث خطأ في عرض هذه الشاشة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A1C24)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أرسل صورة لهذه الرسالة إلى فريق التطبيق ليُصلح السبب',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF6E7B88)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          details.exceptionAsString(),
                          style: const TextStyle(
                              fontSize: 11, height: 1.5, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // تفضيلات الاهتزاز والصوت تُقرأ قبل أول شاشة كي لا تهتزّ قبل أن
  // نعرف أن المستخدم أوقفها.
  await Haptics.load();

  runApp(const ProviderScope(child: IraqPharmaApp()));
}
