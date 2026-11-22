import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/feature_flags.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/drug_detail/drug_detail_screen.dart';
import '../../features/drug_list/drug_list_screen.dart';
import '../../features/drug_list/category_families_screen.dart';
import '../../features/oncology/chemo_dose_screen.dart';
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
import '../../features/auth/profile_completion_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/interactive_reference_screen.dart';
import '../../features/profile/support_screen.dart';
import '../../features/profile/suggestion_screen.dart';
import '../../features/legal/sources_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/otc/otc_screen.dart';
import '../../features/admin/admin_pin_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/admin/admin_statistics_screen.dart';
import '../../features/admin/admin_drug_list_screen.dart';
import '../../features/admin/admin_drug_edit_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/jobs/job_form_screen.dart';
import '../../features/jobs/jobs_admin_screen.dart';
import '../../features/clinic_today/clinic_today_screen.dart';
import '../../features/clinic_today/clinic_hub_screen.dart';
import '../../features/clinic_today/drug_of_day_screen.dart';
import '../../features/clinic_today/weekly_case_screen.dart';
import '../../features/clinic_today/interaction_challenge_screen.dart';
import '../../features/clinic_today/speed_calc_screen.dart';
import '../../features/videos/videos_screen.dart';
import '../../features/availability/availability_screen.dart';
import '../../features/calculators/fluid_calculator_screen.dart';
import '../../features/calculators/shelf_life_screen.dart';
import '../../features/calculators/supply_days_screen.dart';
import '../../features/calculators/lab_units_screen.dart';
import '../../features/calculators/vaccine_schedule_screen.dart';
import '../../features/admin/app_settings_screen.dart';
import '../../features/admin/availability_admin_screen.dart';
import '../../features/admin/pricing_review_screen.dart';
import '../../features/admin/barcode_admin_screen.dart';
import '../../features/admin/notification_composer_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/admin/drug_requests_admin_screen.dart';
import '../../features/admin/ads_admin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',  builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),

    // Auth
    GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup',          builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/forgot-password',  builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password',   builder: (_, __) => const ResetPasswordScreen()),
    GoRoute(path: '/register-success',         builder: (_, __) => const RegistrationSuccessScreen()),
    GoRoute(path: '/notification-permission',  builder: (_, __) => const NotificationPermissionScreen()),
    GoRoute(path: '/complete-profile',         builder: (_, __) => const ProfileCompletionScreen()),
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
    // قسم ← عوائل دوائية ← أدوية. المفتاح `all` يتجاوز العوائل ويعرض
    // كل الأدوية مباشرة (يُستعمل من زر «عرض الكل» في الرئيسية).
    GoRoute(
      path: '/category/:key',
      builder: (_, state) {
        final key = state.pathParameters['key']!;
        return key == 'all'
            ? const DrugListScreen(categoryKey: 'all')
            : CategoryFamiliesScreen(categoryKey: key);
      },
    ),
    GoRoute(
      path: '/category/:key/all',
      builder: (_, state) =>
          DrugListScreen(categoryKey: state.pathParameters['key']!),
    ),
    GoRoute(
      path: '/category/:key/family/:fam',
      builder: (_, state) => DrugListScreen(
        categoryKey: state.pathParameters['key']!,
        // go_router يفكّ ترميز معاملات المسار بنفسه. فكّها مرّة ثانية كان
        // يرمي «Illegal percent encoding in URI» مع كل عائلة في اسمها حرف
        // غير لاتيني بسيط (مثل الشرطة الطويلة «—» أو β)، فتفشل الشاشة كلها.
        familyName: state.pathParameters['fam']!,
      ),
    ),
    GoRoute(
      path: '/quick-filter/:key',
      builder: (_, state) => QuickFilterScreen(filterKey: state.pathParameters['key']!),
    ),

    // Tools & screens
    GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    // Removed on iOS under guideline 1.4.1 — second layer, so a stale deep
    // link cannot reach a screen whose tile is already gone.
    if (FeatureFlags.doseToolsOnThisPlatform)
      GoRoute(path: '/calc',        builder: (_, __) => const DosageCalculatorScreen()),
    if (FeatureFlags.doseToolsOnThisPlatform)
      GoRoute(path: '/renal-calc',  builder: (_, __) => const RenalCalculatorScreen()),
    GoRoute(path: '/interactions',  builder: (_, __) => const InteractionsScreen()),
    if (FeatureFlags.doseToolsOnThisPlatform)
      GoRoute(path: '/chemo-dose',  builder: (_, __) => const ChemoDoseScreen()),
    GoRoute(path: '/sources',       builder: (_, __) => const SourcesScreen()),
    GoRoute(path: '/notebook',      builder: (_, __) => const NotebookScreen()),
    GoRoute(path: '/price-guide',   builder: (_, __) => const CommercialPriceGuideScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/pricing-calc',  builder: (_, __) => const PricingCalculatorScreen()),
    GoRoute(path: '/substitution',  builder: (_, __) => const SubstitutionScreen()),
    GoRoute(path: '/otc',           builder: (_, __) => const OtcScreen()),

    // ── فرص عمل للصيادلة ──────────────────────────────────────────────────
    GoRoute(path: '/jobs',        builder: (_, __) => const JobsScreen()),
    GoRoute(path: '/jobs/new',    builder: (_, __) => const JobFormScreen()),
    GoRoute(path: '/jobs/mine',   builder: (_, __) => const MyJobsScreen()),
    GoRoute(path: '/jobs/review', builder: (_, __) => const JobsAdminScreen()),

    // ── عيادتك اليوم ──────────────────────────────────────────────────────
    // «عيادتك اليوم» صارت لوحة أنشطة، وأسئلة اليوم نشاطٌ فيها.
    GoRoute(path: '/clinic-today', builder: (_, __) => const ClinicTodayHubScreen()),
    GoRoute(path: '/clinic-today/quiz', builder: (_, __) => const ClinicTodayScreen()),
    GoRoute(path: '/clinic-today/drug', builder: (_, __) => const DrugOfDayScreen()),
    GoRoute(path: '/clinic-today/case', builder: (_, __) => const WeeklyCaseScreen()),
    GoRoute(path: '/clinic-today/interactions',
        builder: (_, __) => const InteractionChallengeScreen()),
    GoRoute(path: '/clinic-today/speed', builder: (_, __) => const SpeedCalcScreen()),

    // توفّر الأدوية في الصيدليات
    GoRoute(path: '/availability', builder: (_, __) => const AvailabilityScreen()),

    // حاسبة السوائل والتخفيف
    if (FeatureFlags.doseToolsOnThisPlatform)
      GoRoute(path: '/fluid-calc', builder: (_, __) => const FluidCalculatorScreen()),

    // أدوات سريرية إضافية
    GoRoute(path: '/customers',
        builder: (_, __) => const CustomersScreen()),
    GoRoute(path: '/shelf-life',
        builder: (_, __) => const ShelfLifeScreen()),
    GoRoute(path: '/supply-days',
        builder: (_, __) => const SupplyDaysScreen()),
    GoRoute(path: '/lab-units',
        builder: (_, __) => const LabUnitsScreen()),
    GoRoute(path: '/vaccine-schedule',
        builder: (_, __) => const VaccineScheduleScreen()),
    GoRoute(path: '/videos',       builder: (_, __) => const VideosScreen()),
    GoRoute(path: '/profile',        builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/edit-profile',          builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/interactive-reference', builder: (_, __) => const InteractiveReferenceScreen()),
    GoRoute(path: '/support',               builder: (_, __) => const SupportScreen()),
    GoRoute(path: '/suggestion',            builder: (_, __) => const SuggestionScreen()),
    GoRoute(path: '/legal/privacy',    builder: (_, __) => const LegalScreen(type: LegalType.privacy)),
    GoRoute(path: '/legal/terms',      builder: (_, __) => const LegalScreen(type: LegalType.terms)),
    GoRoute(path: '/legal/disclaimer', builder: (_, __) => const LegalScreen(type: LegalType.disclaimer)),

    // Admin (PIN-protected data management)
    GoRoute(
      path: '/admin-pin',
      builder: (_, state) => AdminPinScreen(
        destination: state.uri.queryParameters['to'] ?? '/admin/drugs',
      ),
    ),
    // Reached only through /admin-pin?to=… — the same code guards both areas.
    GoRoute(path: '/admin/app-settings', builder: (_, __) => const AppSettingsScreen()),
    GoRoute(path: '/admin/availability', builder: (_, __) => const AvailabilityAdminScreen()),
    GoRoute(path: '/admin/drug-requests', builder: (_, __) => const DrugRequestsAdminScreen()),
    GoRoute(path: '/admin/ads', builder: (_, __) => const AdsAdminScreen()),
    GoRoute(path: '/admin/pricing-review',
        builder: (_, __) => const PricingReviewScreen()),
    GoRoute(path: '/admin/barcodes',
        builder: (_, __) => const BarcodeAdminScreen()),
    GoRoute(path: '/admin/send-notification',
        builder: (_, __) => const NotificationComposerScreen()),
    GoRoute(path: '/admin/statistics',  builder: (_, __) => const AdminStatisticsScreen()),
    GoRoute(path: '/admin/drugs',   builder: (_, __) => const AdminDrugListScreen()),
    GoRoute(
      path: '/admin/drug/new',
      builder: (_, __) => const AdminDrugEditScreen(),
    ),
    GoRoute(
      path: '/admin/drug/:id',
      builder: (_, state) => AdminDrugEditScreen(
        drugId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
