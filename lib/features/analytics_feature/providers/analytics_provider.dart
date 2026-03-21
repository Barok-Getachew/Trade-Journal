import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../domain/models/trade.dart';
import '../../../domain/enums/session.dart';
import '../../../domain/enums/emotion_type.dart';
import '../../auth/providers/repository_providers.dart';

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
  return ref
      .watch(tradeRepositoryProvider)
      .fetchAll(from: f.from, to: f.to, strategyId: f.strategyId);
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
