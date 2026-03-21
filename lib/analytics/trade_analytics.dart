import '../domain/models/trade.dart';

/// Analytics result for a collection of trades.
class PortfolioStats {
  final int totalTrades;
  final int wins;
  final int losses;
  final int breakevens;
  final double winRate;
  final double totalR;
  final double avgWinR;
  final double avgLossR;
  final double expectancy;
  final double profitFactor;
  final double totalNetPnl;
  final double maxDrawdown;
  final double maxDrawdownPct;
  final double avgWinPnl;
  final double avgLossPnl;
  final double largestWin;
  final double largestLoss;
  final double rulesFollowedPct;
  final double impulseTradesPct;
  final double recoveryFactor;
  final double consistencyScore;
  // ── Advanced professional metrics ──────────────────────────────────────────
  final double sharpeRatio;
  final double sortinoRatio;
  final double calmarRatio;
  final double riskOfRuin;
  final int maxConsecWins;
  final int maxConsecLosses;
  final int currentWinStreak;
  final int currentLossStreak;
  final double avgHoldingMinutes;

  /// Checklist compliance 0–100 (percentage of items checked across all trades)
  final double checklistScore;

  /// Discipline score 0–100 (higher = more disciplined)

  final double disciplineScore;
  final Map<DateTime, double> dailyPnl;
  final List<EquityPoint> equityCurve;
  final List<DrawdownPoint> drawdownCurve;

  const PortfolioStats({
    required this.totalTrades,
    required this.wins,
    required this.losses,
    required this.breakevens,
    required this.winRate,
    required this.totalR,
    required this.avgWinR,
    required this.avgLossR,
    required this.expectancy,
    required this.profitFactor,
    required this.totalNetPnl,
    required this.maxDrawdown,
    required this.maxDrawdownPct,
    required this.avgWinPnl,
    required this.avgLossPnl,
    required this.largestWin,
    required this.largestLoss,
    required this.rulesFollowedPct,
    required this.impulseTradesPct,
    required this.recoveryFactor,
    required this.consistencyScore,
    required this.sharpeRatio,
    required this.sortinoRatio,
    required this.calmarRatio,
    required this.riskOfRuin,
    required this.maxConsecWins,
    required this.maxConsecLosses,
    required this.currentWinStreak,
    required this.currentLossStreak,
    required this.avgHoldingMinutes,
    required this.disciplineScore,
    required this.checklistScore,
    required this.dailyPnl,
    required this.equityCurve,
    required this.drawdownCurve,
  });
}

class EquityPoint {
  final DateTime date;
  final double equity;
  final double runningR;

  const EquityPoint({
    required this.date,
    required this.equity,
    required this.runningR,
  });
}

class DrawdownPoint {
  final DateTime date;
  final double drawdownPct;

  const DrawdownPoint({required this.date, required this.drawdownPct});
}

class StrategyStats {
  final String? strategyId;
  final String strategyName;
  final int trades;
  final double winRate;
  final double totalR;
  final double avgR;
  final double expectancy;

  const StrategyStats({
    this.strategyId,
    required this.strategyName,
    required this.trades,
    required this.winRate,
    required this.totalR,
    required this.avgR,
    required this.expectancy,
  });
}

class SegmentStats {
  final String label;
  final int trades;
  final double winRate;
  final double totalR;
  final double avgR;

  const SegmentStats({
    required this.label,
    required this.trades,
    required this.winRate,
    required this.totalR,
    required this.avgR,
  });
}

/// Core analytics engine — all calculations in pure Dart, no side effects.
class TradeAnalytics {
  TradeAnalytics._();

  // ─────────────────────────────────────────────────────────────────────────
  // Per-trade helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Gross PnL (direction-aware, before commission).
  static double grossPnl({
    required double entryPrice,
    required double exitPrice,
    required double positionSize,
    required bool isLong,
  }) {
    final priceDelta = isLong ? exitPrice - entryPrice : entryPrice - exitPrice;
    return priceDelta * positionSize;
  }

  /// Net PnL = grossPnl - commission.
  static double netPnl(double gross, double commission) => gross - commission;

  /// R-multiple = netPnl / riskAmount.
  static double rMultiple(double net, double riskAmount) {
    if (riskAmount == 0) return 0;
    return net / riskAmount;
  }

  /// Percentage return on account.
  static double returnPct(double netPnl, double balance) {
    if (balance == 0) return 0;
    return (netPnl / balance) * 100;
  }

  /// Risk-reward ratio: |TP - entry| / |entry - SL|.
  static double riskReward({
    required double entry,
    required double sl,
    required double tp,
  }) {
    final risk = (entry - sl).abs();
    final reward = (tp - entry).abs();
    if (risk == 0) return 0;
    return reward / risk;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Portfolio calculations
  // ─────────────────────────────────────────────────────────────────────────

  static PortfolioStats compute(List<Trade> trades, double startingBalance) {
    if (trades.isEmpty) return _empty(startingBalance);

    final sorted = List<Trade>.from(trades)
      ..sort((a, b) => a.exitAt.compareTo(b.exitAt));

    final wins = sorted.where((t) => t.isWin).toList();
    final losses = sorted.where((t) => t.isLoss).toList();
    final breakevens = sorted.where((t) => t.isBreakeven).length;

    final winCount = wins.length;
    final lossCount = losses.length;
    final total = sorted.length;

    final winRate = total > 0 ? winCount / total : 0.0;

    final totalR = sorted.fold<double>(0, (s, t) => s + t.rMultiple);
    final avgWinR = wins.isEmpty
        ? 0.0
        : wins.fold<double>(0, (s, t) => s + t.rMultiple) / winCount;
    final avgLossR = losses.isEmpty
        ? 0.0
        : losses.fold<double>(0, (s, t) => s + t.rMultiple) / lossCount;

    // Expectancy = (winRate × avgWinR) + (lossRate × avgLossR)
    final lossRate = 1.0 - winRate;
    final expectancy = (winRate * avgWinR) + (lossRate * avgLossR);

    // Profit factor = sum(winning pnl) / abs(sum(losing pnl))
    final grossWin = wins.fold<double>(0, (s, t) => s + t.netPnl);
    final grossLoss = losses.fold<double>(0, (s, t) => s + t.netPnl).abs();
    final profitFactor =
        grossLoss == 0 ? double.infinity : grossWin / grossLoss;

    final totalNetPnl = sorted.fold<double>(0, (s, t) => s + t.netPnl);

    final avgWinPnl = wins.isEmpty ? 0.0 : grossWin / winCount;
    final avgLossPnl = losses.isEmpty ? 0.0 : -grossLoss / lossCount;
    final largestWin = wins.isEmpty
        ? 0.0
        : wins.map((t) => t.netPnl).reduce((a, b) => a > b ? a : b);
    final largestLoss = losses.isEmpty
        ? 0.0
        : losses.map((t) => t.netPnl).reduce((a, b) => a < b ? a : b);

    final rulesFollowedPct =
        total > 0 ? sorted.where((t) => t.rulesFollowed).length / total : 0.0;
    final impulseTradesPct =
        total > 0 ? sorted.where((t) => t.isImpulse).length / total : 0.0;

    // Checklist Score (aggregate % of checks passed across all trades)
    double checklistScore = 0.0;
    if (total > 0) {
      int totalChecks = total * 5;
      int passedChecks = sorted.fold<int>(0, (s, t) {
        int count = 0;
        if (t.planMatch) count++;
        if (t.riskOk) count++;
        if (t.rrOk) count++;
        if (t.confirmation) count++;
        if (t.screenshotReady) count++;
        return s + count;
      });
      checklistScore = (passedChecks / totalChecks) * 100;
    }

    // Build equity curve
    final curve = <EquityPoint>[];
    final drawdownCurve = <DrawdownPoint>[];
    double equity = startingBalance;
    double runningR = 0;
    double peak = startingBalance;
    double maxDD = 0.0;
    double maxDDPct = 0.0;

    for (final trade in sorted) {
      equity += trade.netPnl;
      runningR += trade.rMultiple;
      curve.add(
        EquityPoint(date: trade.exitAt, equity: equity, runningR: runningR),
      );

      if (equity > peak) peak = equity;
      final dd = equity - peak;
      final ddPct = peak > 0 ? (dd / peak) * 100 : 0.0;
      if (dd < maxDD) {
        maxDD = dd;
        maxDDPct = ddPct;
      }
      drawdownCurve.add(DrawdownPoint(date: trade.exitAt, drawdownPct: ddPct));
    }

    // Recovery Factor = Net PnL / abs(Max Drawdown)
    final recoveryFactor = maxDD.abs() > 0 ? totalNetPnl / maxDD.abs() : 0.0;

    // Consistency Score (0.0 - 1.0)
    double consistencyScore = 1.0;
    if (total > 1) {
      final meanR = totalR / total;
      final variance = sorted.fold<double>(
              0, (s, t) => s + (t.rMultiple - meanR) * (t.rMultiple - meanR)) /
          total;
      // High consistency = low R-multiple variance relative to average R.
      consistencyScore = (1.0 - (variance / 1.0)).clamp(0.1, 1.0);
    }

    // Aggregate Daily P&L
    final dailyPnl = <DateTime, double>{};
    for (final t in sorted) {
      final date = DateTime(t.exitAt.year, t.exitAt.month, t.exitAt.day);
      dailyPnl[date] = (dailyPnl[date] ?? 0.0) + t.netPnl;
    }

    // ── Advanced metrics ────────────────────────────────────────────────────

    // Sharpe Ratio: (meanDailyReturn - riskFreeRate) / stdDev * sqrt(252)
    final dailyReturns = dailyPnl.values.toList();
    final sharpeRatio = _sharpe(dailyReturns, startingBalance);
    final sortinoRatio = _sortino(dailyReturns, startingBalance);

    // Calmar = annualizedReturn / |maxDrawdownPct|
    double calmarRatio = 0;
    if (maxDDPct.abs() > 0 && sorted.isNotEmpty) {
      final days = sorted.last.exitAt.difference(sorted.first.exitAt).inDays;
      final annualizedReturn = days > 0
          ? (totalNetPnl / startingBalance) * (365.0 / days) * 100
          : 0.0;
      calmarRatio = annualizedReturn / maxDDPct.abs();
    }

    // Risk of Ruin (simplified Kelly-based estimate)
    final riskOfRuin = _riskOfRuin(winRate, avgWinR.abs(), avgLossR.abs());

    // Max consecutive wins / losses
    final (maxCW, maxCL) = _maxConsecutive(sorted);

    // Average holding time in minutes
    final avgHoldingMinutes = sorted.isEmpty
        ? 0.0
        : sorted
                .map((t) => t.holdingDuration.inMinutes.toDouble())
                .reduce((a, b) => a + b) /
            sorted.length;

    // Discipline score (0–100)
    final disciplineScore = _disciplineScore(
      impulseTradesPct: impulseTradesPct,
      rulesFollowedPct: rulesFollowedPct,
    );

    // Current streak (count from end of sorted list)
    int currentWinStreak = 0;
    int currentLossStreak = 0;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].isWin) {
        if (currentLossStreak > 0) break;
        currentWinStreak++;
      } else if (sorted[i].isLoss) {
        if (currentWinStreak > 0) break;
        currentLossStreak++;
      } else {
        break; // breakeven stops streak
      }
    }

    return PortfolioStats(
      totalTrades: total,
      wins: winCount,
      losses: lossCount,
      breakevens: breakevens,
      winRate: winRate,
      totalR: totalR,
      avgWinR: avgWinR,
      avgLossR: avgLossR,
      expectancy: expectancy,
      profitFactor: profitFactor,
      totalNetPnl: totalNetPnl,
      maxDrawdown: maxDD,
      maxDrawdownPct: maxDDPct,
      avgWinPnl: avgWinPnl,
      avgLossPnl: avgLossPnl,
      largestWin: largestWin,
      largestLoss: largestLoss,
      rulesFollowedPct: rulesFollowedPct,
      impulseTradesPct: impulseTradesPct,
      recoveryFactor: recoveryFactor,
      consistencyScore: consistencyScore,
      sharpeRatio: sharpeRatio,
      sortinoRatio: sortinoRatio,
      calmarRatio: calmarRatio,
      riskOfRuin: riskOfRuin,
      maxConsecWins: maxCW,
      maxConsecLosses: maxCL,
      currentWinStreak: currentWinStreak,
      currentLossStreak: currentLossStreak,
      avgHoldingMinutes: avgHoldingMinutes,
      disciplineScore: disciplineScore,
      checklistScore: checklistScore,
      dailyPnl: dailyPnl,
      equityCurve: curve,
      drawdownCurve: drawdownCurve,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Segment breakdowns
  // ─────────────────────────────────────────────────────────────────────────

  /// Break down stats by a string key (strategy name, symbol, session, etc.)
  static List<SegmentStats> segmentBy(
    List<Trade> trades,
    String Function(Trade) keyFn,
    String Function(Trade) labelFn,
  ) {
    final groups = <String, List<Trade>>{};
    for (final t in trades) {
      final key = keyFn(t);
      groups.putIfAbsent(key, () => []).add(t);
    }

    return groups.entries.map((e) {
      final ts = e.value;
      final wins = ts.where((t) => t.isWin).length;
      final winRate = ts.isEmpty ? 0.0 : wins / ts.length;
      final totalR = ts.fold<double>(0, (s, t) => s + t.rMultiple);
      final avgR = ts.isEmpty ? 0.0 : totalR / ts.length;
      return SegmentStats(
        label: labelFn(ts.first),
        trades: ts.length,
        winRate: winRate,
        totalR: totalR,
        avgR: avgR,
      );
    }).toList()
      ..sort((a, b) => b.totalR.compareTo(a.totalR));
  }

  /// Checklist comparison: passed all checks vs skipped some.
  static Map<String, PortfolioStats> checklistComparison(
    List<Trade> trades,
    double balance,
  ) {
    final passedAll = trades.where((t) {
      return t.planMatch &&
          t.riskOk &&
          t.rrOk &&
          t.confirmation &&
          t.screenshotReady;
    }).toList();
    final skippedSome = trades.where((t) {
      return !(t.planMatch &&
          t.riskOk &&
          t.rrOk &&
          t.confirmation &&
          t.screenshotReady);
    }).toList();
    return {
      'passed_all': compute(passedAll, balance),
      'skipped_some': compute(skippedSome, balance),
    };
  }

  /// Discipline comparison: rules followed vs broken.
  static Map<String, PortfolioStats> disciplineComparison(
    List<Trade> trades,
    double balance,
  ) {
    final followed = trades.where((t) => t.rulesFollowed).toList();
    final broken = trades.where((t) => !t.rulesFollowed).toList();
    return {
      'followed': compute(followed, balance),
      'broken': compute(broken, balance),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  static PortfolioStats _empty(double balance) => PortfolioStats(
        totalTrades: 0,
        wins: 0,
        losses: 0,
        breakevens: 0,
        winRate: 0,
        totalR: 0,
        avgWinR: 0,
        avgLossR: 0,
        expectancy: 0,
        profitFactor: 0,
        totalNetPnl: 0,
        maxDrawdown: 0,
        maxDrawdownPct: 0,
        avgWinPnl: 0,
        avgLossPnl: 0,
        largestWin: 0,
        largestLoss: 0,
        rulesFollowedPct: 0,
        impulseTradesPct: 0,
        recoveryFactor: 0,
        consistencyScore: 0,
        sharpeRatio: 0,
        sortinoRatio: 0,
        calmarRatio: 0,
        riskOfRuin: 0,
        maxConsecWins: 0,
        maxConsecLosses: 0,
        currentWinStreak: 0,
        currentLossStreak: 0,
        avgHoldingMinutes: 0,
        disciplineScore: 100,
        checklistScore: 0,
        dailyPnl: {},
        equityCurve: [],
        drawdownCurve: [],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Advanced metric helpers
  // ─────────────────────────────────────────────────────────────────────────

  static double _sharpe(List<double> dailyPnl, double startBalance) {
    if (dailyPnl.length < 2) return 0;
    final returns = dailyPnl.map((p) => p / startBalance).toList();
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            returns.length;
    final std = variance > 0 ? variance * 0.5 : 0.0; // sqrt approximation
    // Use dart:math for sqrt when available; keep pure-Dart via iteration:
    final stdDev = _sqrt(variance);
    if (stdDev == 0) return 0;
    const riskFreeDaily = 0.0001; // ~2.6% annual risk-free
    return (mean - riskFreeDaily) / stdDev * _sqrt(252);
  }

  static double _sortino(List<double> dailyPnl, double startBalance) {
    if (dailyPnl.length < 2) return 0;
    final returns = dailyPnl.map((p) => p / startBalance).toList();
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final downside = returns.where((r) => r < 0).toList();
    if (downside.isEmpty) return 0;
    final downsideVariance =
        downside.map((r) => r * r).reduce((a, b) => a + b) / downside.length;
    final downsideStd = _sqrt(downsideVariance);
    if (downsideStd == 0) return 0;
    return (mean / downsideStd) * _sqrt(252);
  }

  /// Risk of Ruin approximation: ((1-P) / P) ^ N
  /// where P = win rate, N = number of consecutive losses to bust.
  static double _riskOfRuin(double winRate, double avgWinR, double avgLossR) {
    if (winRate <= 0 || winRate >= 1 || avgLossR <= 0) return 0;
    final p = winRate;
    final q = 1 - p;
    // Simplified: probability of ruin with Kelly fraction
    final edge = p * avgWinR - q * avgLossR;
    if (edge <= 0) return 1.0; // negative edge = certain ruin
    return (q / p).clamp(0.0, 1.0);
  }

  /// Max consecutive wins and losses in trade sequence.
  static (int wins, int losses) _maxConsecutive(List<Trade> sorted) {
    int maxW = 0, maxL = 0, curW = 0, curL = 0;
    for (final t in sorted) {
      if (t.isWin) {
        curW++;
        curL = 0;
        if (curW > maxW) maxW = curW;
      } else if (t.isLoss) {
        curL++;
        curW = 0;
        if (curL > maxL) maxL = curL;
      } else {
        curW = 0;
        curL = 0;
      }
    }
    return (maxW, maxL);
  }

  /// Pure-Dart Newton-Raphson square root (avoids dart:math import here).
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }

  /// Discipline score 0–100 based on rule compliance and impulse trades.
  static double _disciplineScore({
    required double impulseTradesPct,
    required double rulesFollowedPct,
  }) {
    double score = 100;
    score -= impulseTradesPct * 30; // up to -30 for impulse trades
    score -= (1 - rulesFollowedPct) * 40; // up to -40 for broken rules
    return score.clamp(0, 100);
  }
}
