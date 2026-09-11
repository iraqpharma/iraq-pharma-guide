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
  runApp(const ProviderScope(child: IraqPharmaApp()));
}
