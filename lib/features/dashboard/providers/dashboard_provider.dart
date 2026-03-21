import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal/analytics/trade_analytics.dart';
import 'package:journal/domain/models/account.dart';
import 'package:journal/domain/models/trade.dart';
import 'package:journal/features/auth/providers/repository_providers.dart';
import 'package:journal/features/accounts/providers/account_provider.dart';

// ── All trades (no filter) ────────────────────────────────────────────────────

final allTradesProvider = FutureProvider<List<Trade>>((ref) async {
  return ref.watch(tradeRepositoryProvider).fetchAll();
});

// ── Accounts ──────────────────────────────────────────────────────────────────
// NOTE: accountListProvider and selectedAccountProvider now live in
// features/accounts/providers/account_provider.dart — kept here as aliases
// so existing code that imports dashboard_provider doesn't break.

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.watch(accountRepositoryProvider).fetchAll();
});

// ── Dashboard stats — per-account when an account is selected ─────────────────

final dashboardStatsProvider = FutureProvider<PortfolioStats>((ref) async {
  final selectedAccount = ref.watch(selectedAccountProvider);
  final allTrades = await ref.watch(allTradesProvider.future);
  final accounts = await ref.watch(accountsProvider.future);

  List<Trade> trades;
  double balance;

  if (selectedAccount != null) {
    // Filter to only this account's trades
    trades = allTrades.where((t) => t.accountId == selectedAccount.id).toList();
    balance = selectedAccount.initialBalance;
  } else {
    // "All Accounts" — aggregate
    trades = allTrades;
    balance = accounts.isEmpty
        ? 10000.0
        : accounts.fold<double>(0, (sum, a) => sum + a.initialBalance);
  }

  return TradeAnalytics.compute(trades, balance);
});

// ── Starting balance for equity curve ────────────────────────────────────────

final startingBalanceProvider = FutureProvider<double>((ref) async {
  final selectedAccount = ref.watch(selectedAccountProvider);
  final accounts = await ref.watch(accountsProvider.future);

  if (selectedAccount != null) {
    return selectedAccount.initialBalance;
  }
  return accounts.isEmpty
      ? 10000.0
      : accounts.fold<double>(0, (sum, a) => sum + a.initialBalance);
});

// ── Recent trades (last 30 days for dashboard) ────────────────────────────────

final recentTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final selectedAccount = ref.watch(selectedAccountProvider);
  final from = DateTime.now().subtract(const Duration(days: 30));
  final trades = await ref.watch(tradeRepositoryProvider).fetchAll(from: from);
  if (selectedAccount == null) return trades;
  return trades.where((t) => t.accountId == selectedAccount.id).toList();
});

// ── Dashboard Alerts ──────────────────────────────────────────────────────────
// Aggregates daily review pending + risk rule violations into warning strings

final dashboardAlertsProvider = FutureProvider<List<String>>((ref) async {
  final account = ref.watch(selectedAccountProvider);
  if (account == null) return [];

  final alerts = <String>[];

  // 1. Daily review pending?
  final review = await ref
      .read(dailyReviewRepositoryProvider)
      .fetchForDate(account.id, DateTime.now());

  // Only alert if we also traded today
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tradesToday =
      await ref.watch(tradeRepositoryProvider).fetchAll(from: todayStart);
  final accountTradesToday =
      tradesToday.where((t) => t.accountId == account.id).toList();

  if (accountTradesToday.isNotEmpty && review == null) {
    alerts
        .add('Daily review pending — complete before you log your next trade');
  }

  // 2. Risk rule checks
  final rules =
      await ref.read(riskRuleRepositoryProvider).fetchForAccount(account.id);
  if (rules != null) {
    final stats = await ref.watch(dashboardStatsProvider.future);

    // Daily loss %
    final dailyPnl =
        stats.dailyPnl[DateTime(now.year, now.month, now.day)] ?? 0.0;
    final dailyLossPct = (dailyPnl / account.initialBalance) * 100;
    if (dailyLossPct < -rules.maxDailyLossPct) {
      alerts.add(
          'Daily loss limit breached (${dailyLossPct.toStringAsFixed(1)}%) — trading suspended for today');
    }

    // Max trades per day
    if (accountTradesToday.length >= rules.maxTradesPerDay) {
      alerts.add(
          'Max daily trades reached (${accountTradesToday.length}/${rules.maxTradesPerDay})');
    }
  }

  return alerts;
});
