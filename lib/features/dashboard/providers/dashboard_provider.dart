import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal/analytics/trade_analytics.dart';
import 'package:journal/domain/models/account.dart';
import 'package:journal/domain/models/trade.dart';
import 'package:journal/features/auth/providers/repository_providers.dart';
import 'package:journal/features/accounts/providers/account_provider.dart';

// ── Current balance per account (initialBalance + sum of all trade netPnl) ────

/// Returns a map of accountId → currentBalance for every account.
final accountCurrentBalancesProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final allTrades = await ref.watch(allTradesProvider.future);

  final Map<String, double> balances = {};
  for (final account in accounts) {
    final trades = allTrades.where((t) => t.accountId == account.id).toList();
    final pnl = trades.fold<double>(0.0, (sum, t) => sum + t.netPnl);
    balances[account.id] = account.initialBalance + pnl;
  }
  return balances;
});

/// Current balance & blown status for the selected account (or aggregate).
final currentBalanceProvider =
    FutureProvider<({double initial, double current, bool isBlown})>(
        (ref) async {
  final selectedAccount = ref.watch(selectedAccountProvider);
  final allTrades = await ref.watch(allTradesProvider.future);
  final accounts = await ref.watch(accountsProvider.future);

  double initial;
  List<Trade> trades;

  if (selectedAccount != null) {
    initial = selectedAccount.initialBalance;
    trades = allTrades.where((t) => t.accountId == selectedAccount.id).toList();
  } else {
    initial = accounts.isEmpty
        ? 0.0
        : accounts.fold<double>(0, (s, a) => s + a.initialBalance);
    trades = allTrades;
  }

  final pnl = trades.fold<double>(0.0, (sum, t) => sum + t.netPnl);
  final current = initial + pnl;
  return (
    initial: initial,
    current: current,
    isBlown: current <= 0 && initial > 0
  );
});

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

// ── Monthly R-Target ──────────────────────────────────────────────────────────

final monthlyRTargetProvider =
    FutureProvider<({double current, double target})>((ref) async {
  final account = ref.watch(selectedAccountProvider);
  if (account == null) return (current: 0.0, target: 0.0);

  final trades = await ref.watch(allTradesProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final monthlyTrades = trades
      .where((t) => t.accountId == account.id && t.entryAt.isAfter(monthStart));

  final totalR = monthlyTrades.fold<double>(0, (sum, t) => sum + t.rMultiple);
  return (current: totalR, target: account.monthlyRTarget ?? 0.0);
});

// ── Best/Worst Trades ─────────────────────────────────────────────────────────

final bestWorstTradesProvider =
    FutureProvider<({Trade? best, Trade? worst})>((ref) async {
  final account = ref.watch(selectedAccountProvider);
  final trades = await ref.watch(allTradesProvider.future);

  final accountTrades = account == null
      ? trades
      : trades.where((t) => t.accountId == account.id).toList();

  if (accountTrades.isEmpty) return (best: null, worst: null);

  Trade? best;
  Trade? worst;

  for (final t in accountTrades) {
    if (best == null || t.rMultiple > best.rMultiple) best = t;
    if (worst == null || t.rMultiple < worst.rMultiple) worst = t;
  }

  return (best: best, worst: worst);
});
