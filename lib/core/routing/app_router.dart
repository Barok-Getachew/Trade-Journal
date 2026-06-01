import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trades/screens/trades_screen.dart';
import '../../features/trades/screens/trade_form_screen.dart';
import '../../features/trades/screens/trade_detail_screen.dart';
import '../../features/trades/screens/import_trades_screen.dart';
import '../../features/analytics_feature/screens/analytics_screen.dart';
import '../../features/weekly_review/screens/weekly_review_list_screen.dart';
import '../../features/weekly_review/screens/weekly_new_review_screen.dart';
import '../../features/monthly_audit/screens/monthly_audit_screen.dart';
import '../../features/accounts/screens/account_manager_screen.dart';
import '../../features/accounts/screens/account_comparison_screen.dart';
import '../../features/daily_review/screens/daily_review_screen.dart';
import '../../features/risk_rules/screens/risk_rules_screen.dart';
import '../../features/narratives/screens/daily_narrative_screen.dart';
import '../../features/narratives/screens/weekly_narrative_screen.dart';
import '../../features/narratives/screens/narrative_history_screen.dart';
import '../../shared/widgets/layout/app_shell.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/accounts/providers/account_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) => refreshNotifier.value++);
  ref.listen(accountListProvider, (_, __) => refreshNotifier.value++);

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = auth?.session != null;
      final accounts = ref.read(accountListProvider).valueOrNull;

      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // Logged in
      if (isLoggingIn) return '/dashboard';

      // If we have accounts info and it's empty, and we aren't already onboarding
      if (accounts != null && accounts.isEmpty && !isOnboarding) {
        return '/onboarding';
      }

      // If we have accounts and we are on onboarding, go to dashboard
      if (accounts != null && accounts.isNotEmpty && isOnboarding) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/trades',
            builder: (_, __) => const TradesScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const TradeFormScreen()),
              GoRoute(
                  path: 'import',
                  builder: (_, __) => const ImportTradesScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    TradeDetailScreen(tradeId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) =>
                        TradeFormScreen(tradeId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/weekly-review',
            builder: (_, __) => const WeeklyReviewListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const WeeklyNewReviewScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => WeeklyReviewDetailScreen(
                  reviewId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/monthly-audit',
            builder: (_, __) => const MonthlyAuditScreen(),
            routes: [
              GoRoute(
                path: ':year/:month',
                builder: (_, state) => MonthlyAuditScreen(
                  year: int.parse(state.pathParameters['year']!),
                  month: int.parse(state.pathParameters['month']!),
                ),
              ),
            ],
          ),
          // ── Trading OS extensions ─────────────────────────────────────────
          GoRoute(
            path: '/accounts',
            builder: (_, __) => const AccountManagerScreen(),
            routes: [
              GoRoute(
                path: 'compare',
                builder: (_, __) => const AccountComparisonScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/daily-review',
            builder: (_, __) => const DailyReviewScreen(),
          ),
          GoRoute(
            path: '/risk-rules',
            builder: (_, __) => const RiskRulesScreen(),
          ),
          GoRoute(
            path: '/daily-narrative',
            builder: (_, __) => const DailyNarrativeScreen(),
          ),
          GoRoute(
            path: '/weekly-narrative-builder',
            builder: (_, __) => const WeeklyNarrativeScreen(),
          ),
          GoRoute(
            path: '/narrative-history',
            builder: (_, __) => const NarrativeHistoryScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
