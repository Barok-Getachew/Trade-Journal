import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../domain/models/trade.dart';
import '../../../domain/enums/asset_class.dart';
import '../../../domain/enums/direction.dart';
import '../../../domain/enums/session.dart';
import '../../auth/providers/repository_providers.dart';

// ── Trade filters state ───────────────────────────────────────────────────────

class TradeFilter {
  final DateTime? from;
  final DateTime? to;
  final String? strategyId;
  final String? symbol;
  final bool? rulesFollowed;
  final AssetClass? assetClass;
  final TradeDirection? direction;
  final TradingSession? session;

  const TradeFilter({
    this.from,
    this.to,
    this.strategyId,
    this.symbol,
    this.rulesFollowed,
    this.assetClass,
    this.direction,
    this.session,
  });

  TradeFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? strategyId,
    String? symbol,
    bool? rulesFollowed,
    AssetClass? assetClass,
    TradeDirection? direction,
    TradingSession? session,
  }) {
    return TradeFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      strategyId: strategyId ?? this.strategyId,
      symbol: symbol ?? this.symbol,
      rulesFollowed: rulesFollowed ?? this.rulesFollowed,
      assetClass: assetClass ?? this.assetClass,
      direction: direction ?? this.direction,
      session: session ?? this.session,
    );
  }

  bool get isEmpty =>
      from == null &&
      to == null &&
      strategyId == null &&
      symbol == null &&
      rulesFollowed == null &&
      assetClass == null &&
      direction == null &&
      session == null;
}

class TradeFilterNotifier extends StateNotifier<TradeFilter> {
  TradeFilterNotifier() : super(const TradeFilter());

  void update(TradeFilter f) => state = f;
  void reset() => state = const TradeFilter();

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(from: from, to: to);
  }

  void setStrategy(String? id) => state = state.copyWith(strategyId: id);
  void setSymbol(String? s) => state = state.copyWith(symbol: s);
  void setRulesFollowed(bool? v) => state = state.copyWith(rulesFollowed: v);
}

final tradeFilterProvider =
    StateNotifierProvider<TradeFilterNotifier, TradeFilter>(
      (_) => TradeFilterNotifier(),
    );

// ── Filtered trades provider ──────────────────────────────────────────────────

final filteredTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final filter = ref.watch(tradeFilterProvider);
  return ref
      .watch(tradeRepositoryProvider)
      .fetchAll(
        from: filter.from,
        to: filter.to,
        strategyId: filter.strategyId,
        symbol: filter.symbol,
        rulesFollowed: filter.rulesFollowed,
      );
});

// ── Filtered portfolio stats ────────────────────────────────────────────────────

final filteredStatsProvider = FutureProvider<PortfolioStats>((ref) async {
  final trades = await ref.watch(filteredTradesProvider.future);
  return TradeAnalytics.compute(trades, 10000.0);
});

// ── Distinct symbols (for filter dropdowns) ──────────────────────────────────

final distinctSymbolsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(tradeRepositoryProvider).fetchDistinctSymbols();
});
