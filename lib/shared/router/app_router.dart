import 'package:go_router/go_router.dart';
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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/drug/:id',
      builder: (_, state) => DrugDetailScreen(
        drugId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/category/:key',
      builder: (_, state) => DrugListScreen(
        categoryKey: state.pathParameters['key']!,
      ),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/calc', builder: (_, __) => const DosageCalculatorScreen()),
    GoRoute(path: '/renal-calc', builder: (_, __) => const RenalCalculatorScreen()),
    GoRoute(path: '/interactions', builder: (_, __) => const InteractionsScreen()),
    GoRoute(path: '/notebook', builder: (_, __) => const NotebookScreen()),
    GoRoute(
      path: '/quick-filter/:key',
      builder: (_, state) => QuickFilterScreen(
        filterKey: state.pathParameters['key']!,
      ),
    ),
    GoRoute(
      path: '/price-guide',
      builder: (_, __) => const CommercialPriceGuideScreen(),
    ),
  ],
);
