import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/drug_detail/drug_detail_screen.dart';
import '../../features/drug_list/drug_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/dosage_calculator/dosage_calculator_screen.dart';
import '../../features/renal_calculator/renal_calculator_screen.dart';
import '../../features/interactions/interactions_screen.dart';
import '../../features/notebook/notebook_screen.dart';
import '../../features/drug_list/quick_filter_screen.dart';
import '../../features/price_guide/commercial_price_guide_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/tools/pricing_calculator_screen.dart';
import '../../features/tools/substitution_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/success_screen.dart';
import '../../features/auth/notification_permission_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/interactive_reference_screen.dart';
import '../../features/profile/support_screen.dart';
import '../../features/profile/suggestion_screen.dart';
import '../../features/legal/legal_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',  builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),

    // Auth
    GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup',          builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/register-success',         builder: (_, __) => const RegistrationSuccessScreen()),
    GoRoute(path: '/notification-permission',  builder: (_, __) => const NotificationPermissionScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpScreen(
          email:   (extra['email'] as String?) ?? '',
          otpType: extra['type'] as OtpType,
          isLogin: (extra['isLogin'] as bool?) ?? false,
        );
      },
    ),

    // Drugs
    GoRoute(
      path: '/drug/:id',
      builder: (_, state) => DrugDetailScreen(
        drugId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/category/:key',
      builder: (_, state) => DrugListScreen(categoryKey: state.pathParameters['key']!),
    ),
    GoRoute(
      path: '/quick-filter/:key',
      builder: (_, state) => QuickFilterScreen(filterKey: state.pathParameters['key']!),
    ),

    // Tools & screens
    GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/calc',          builder: (_, __) => const DosageCalculatorScreen()),
    GoRoute(path: '/renal-calc',    builder: (_, __) => const RenalCalculatorScreen()),
    GoRoute(path: '/interactions',  builder: (_, __) => const InteractionsScreen()),
    GoRoute(path: '/notebook',      builder: (_, __) => const NotebookScreen()),
    GoRoute(path: '/price-guide',   builder: (_, __) => const CommercialPriceGuideScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/pricing-calc',  builder: (_, __) => const PricingCalculatorScreen()),
    GoRoute(path: '/substitution',  builder: (_, __) => const SubstitutionScreen()),
    GoRoute(path: '/profile',        builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/edit-profile',          builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/interactive-reference', builder: (_, __) => const InteractiveReferenceScreen()),
    GoRoute(path: '/support',               builder: (_, __) => const SupportScreen()),
    GoRoute(path: '/suggestion',            builder: (_, __) => const SuggestionScreen()),
    GoRoute(path: '/legal/privacy',    builder: (_, __) => const LegalScreen(type: LegalType.privacy)),
    GoRoute(path: '/legal/terms',      builder: (_, __) => const LegalScreen(type: LegalType.terms)),
    GoRoute(path: '/legal/disclaimer', builder: (_, __) => const LegalScreen(type: LegalType.disclaimer)),
  ],
);
