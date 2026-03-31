import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../domain/models/trade.dart';
import '../../../domain/enums/session.dart';
import '../../../domain/enums/emotion_type.dart';
import '../../auth/providers/repository_providers.dart';
import '../../accounts/providers/account_provider.dart';

// ── Analytics filter ──────────────────────────────────────────────────────────

class AnalyticsFilter {
  final DateTime? from;
  final DateTime? to;
  final String? strategyId;

  const AnalyticsFilter({this.from, this.to, this.strategyId});
}

final analyticsFilterProvider = StateProvider<AnalyticsFilter>(
  (_) => const AnalyticsFilter(),
);

// ── Trades for analytics window ───────────────────────────────────────────────

final analyticsTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final f = ref.watch(analyticsFilterProvider);
  final accountId = ref.watch(selectedAccountIdProvider);
  return ref
      .watch(tradeRepositoryProvider)
      .fetchAll(from: f.from, to: f.to, strategyId: f.strategyId,
          accountId: accountId);
});

// ── Segment breakdowns ────────────────────────────────────────────────────────

final strategySegmentProvider = FutureProvider<List<SegmentStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.segmentBy(
    trades,
    (t) => t.strategyId ?? 'none',
    (t) => t.strategyId ?? 'No Strategy',
  );
});

final symbolSegmentProvider = FutureProvider<List<SegmentStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.segmentBy(trades, (t) => t.symbol, (t) => t.symbol);
});

final sessionSegmentProvider = FutureProvider<List<SegmentStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.segmentBy(
    trades,
    (t) => t.session?.name ?? 'unknown',
    (t) => t.session?.label ?? 'Unknown',
  );
});

final emotionSegmentProvider = FutureProvider<List<SegmentStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.segmentBy(
    trades,
    (t) => t.emotionBefore?.name ?? 'none',
    (t) => t.emotionBefore?.label ?? 'Not recorded',
  );
});

final dayOfWeekSegmentProvider = FutureProvider<List<SegmentStats>>((
  ref,
) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return TradeAnalytics.segmentBy(
    trades,
    (t) => t.entryAt.weekday.toString(),
    (t) => days[t.entryAt.weekday - 1],
  )..sort((a, b) {
      final ai = days.indexOf(a.label);
      final bi = days.indexOf(b.label);
      return ai.compareTo(bi);
    });
});

final disciplineComparisonProvider =
    FutureProvider<Map<String, PortfolioStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.disciplineComparison(trades, 10000.0);
});

final checklistComparisonProvider =
    FutureProvider<Map<String, PortfolioStats>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  return TradeAnalytics.checklistComparison(trades, 10000.0);
});

// ── Calendar daily P&L for Analytics ─────────────────────────────────────────

final analyticsDailyPnlProvider =
    FutureProvider<Map<DateTime, double>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  final map = <DateTime, double>{};
  for (final t in trades) {
    final date = DateTime(t.exitAt.year, t.exitAt.month, t.exitAt.day);
    map[date] = (map[date] ?? 0.0) + t.netPnl;
  }
  return map;
});

final analyticsTradeCountProvider =
    FutureProvider<Map<DateTime, int>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);
  final map = <DateTime, int>{};
  for (final t in trades) {
    final date = DateTime(t.exitAt.year, t.exitAt.month, t.exitAt.day);
    map[date] = (map[date] ?? 0) + 1;
  }
  return map;
});

// ── R-Multiple histogram buckets ──────────────────────────────────────────────

class HistogramBucket {
  final String label;
  final int count;
  final double minR;
  final double maxR;
  const HistogramBucket({
    required this.label,
    required this.count,
    required this.minR,
    required this.maxR,
  });
}

final rMultipleHistogramProvider =
    FutureProvider<List<HistogramBucket>>((ref) async {
  final trades = await ref.watch(analyticsTradesProvider.future);

  // 8 buckets: < -3, -3→-2, -2→-1, -1→0, 0→1, 1→2, 2→3, > 3
  final edges = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0];
  final labels = [
    '< -3R',
    '-3→-2R',
    '-2→-1R',
    '-1→0R',
    '0→1R',
    '1→2R',
    '2→3R',
    '> 3R',
  ];

  final counts = List<int>.filled(8, 0);
  for (final t in trades) {
    final r = t.rMultiple;
    if (r < -3) {
      counts[0]++;
    } else if (r < -2) {
      counts[1]++;
    } else if (r < -1) {
      counts[2]++;
    } else if (r < 0) {
      counts[3]++;
    } else if (r < 1) {
      counts[4]++;
    } else if (r < 2) {
      counts[5]++;
    } else if (r < 3) {
      counts[6]++;
    } else {
      counts[7]++;
    }
  }

  final minRs = [double.negativeInfinity, ...edges];
  final maxRs = [...edges, double.infinity];

  return List.generate(
    8,
    (i) => HistogramBucket(
      label: labels[i],
      count: counts[i],
      minR: minRs[i],
      maxR: maxRs[i],
    ),
  );
});
