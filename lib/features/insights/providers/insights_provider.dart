import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/trade.dart';
import '../../dashboard/providers/dashboard_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum InsightType { positive, warning, tip }

class TradeInsight {
  final InsightType type;
  final String title;
  final String body;
  final String icon;
  final double? metric;
  const TradeInsight({
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    this.metric,
  });
}

class StreakData {
  final int winStreak;
  final int disciplineStreak;
  final int impulseFreeDays;
  const StreakData({
    required this.winStreak,
    required this.disciplineStreak,
    required this.impulseFreeDays,
  });
}

class TradeBadge {
  final String icon;
  final String title;
  final String description;
  final bool earned;
  const TradeBadge({
    required this.icon,
    required this.title,
    required this.description,
    required this.earned,
  });
}

// ─── Insights Provider (P1) ───────────────────────────────────────────────────

final insightsProvider = FutureProvider<List<TradeInsight>>((ref) async {
  final trades = await ref.watch(allTradesProvider.future);
  if (trades.length < 5) return [];

  final out = <TradeInsight>[];
  _dayOfWeekInsight(trades, out);
  _sessionInsight(trades, out);
  _emotionInsight(trades, out);
  _impulseInsight(trades, out);
  _afterLossInsight(trades, out);
  _symbolInsight(trades, out);
  _newsDayInsight(trades, out);
  _setupQualityInsight(trades, out);

  out.sort((a, b) {
    const o = {InsightType.warning: 0, InsightType.tip: 1, InsightType.positive: 2};
    return o[a.type]!.compareTo(o[b.type]!);
  });
  return out.take(6).toList();
});

// ─── Streaks Provider (P4) ────────────────────────────────────────────────────

final streakProvider = FutureProvider<StreakData>((ref) async {
  final trades = await ref.watch(allTradesProvider.future);
  if (trades.isEmpty) {
    return const StreakData(winStreak: 0, disciplineStreak: 0, impulseFreeDays: 0);
  }

  final sorted = [...trades]..sort((a, b) => b.entryAt.compareTo(a.entryAt));

  int winStreak = 0;
  for (final t in sorted) {
    if (t.isWin) winStreak++;
    else break;
  }

  int disciplineStreak = 0;
  for (final t in sorted) {
    if (t.rulesFollowed) disciplineStreak++;
    else break;
  }

  final lastImpulse = sorted.firstWhere((t) => t.isImpulse, orElse: () => sorted.last);
  final impulseFreeDays = lastImpulse.isImpulse
      ? DateTime.now().difference(lastImpulse.entryAt).inDays
      : DateTime.now().difference(sorted.last.entryAt).inDays;

  return StreakData(
    winStreak: winStreak,
    disciplineStreak: disciplineStreak,
    impulseFreeDays: impulseFreeDays,
  );
});

// ─── Badges Provider (P4) ─────────────────────────────────────────────────────

final badgesProvider = FutureProvider<List<TradeBadge>>((ref) async {
  final trades = await ref.watch(allTradesProvider.future);
  final streak = await ref.watch(streakProvider.future);

  final totalR = trades.fold<double>(0, (s, t) => s + t.rMultiple);
  final winRate = trades.isEmpty
      ? 0.0
      : trades.where((t) => t.isWin).length / trades.length;
  final impulseCount = trades.where((t) => t.isImpulse).length;

  return [
    TradeBadge(icon: '🎯', title: 'First Blood', description: 'Logged your first trade', earned: trades.isNotEmpty),
    TradeBadge(icon: '📊', title: 'Getting Started', description: 'Logged 10+ trades', earned: trades.length >= 10),
    TradeBadge(icon: '🏆', title: 'Century Club', description: 'Logged 100 trades', earned: trades.length >= 100),
    TradeBadge(icon: '💰', title: '10R Club', description: 'Earned 10R total', earned: totalR >= 10),
    TradeBadge(icon: '🚀', title: '50R Rocket', description: 'Earned 50R total', earned: totalR >= 50),
    TradeBadge(icon: '🔥', title: 'On Fire', description: '5 consecutive wins', earned: streak.winStreak >= 5),
    TradeBadge(icon: '🧠', title: 'Disciplined', description: '10 consecutive rule-following trades', earned: streak.disciplineStreak >= 10),
    TradeBadge(icon: '🧘', title: 'Zen Trader', description: 'Zero impulse trades ever', earned: impulseCount == 0 && trades.isNotEmpty),
    TradeBadge(icon: '📈', title: 'Consistent Edge', description: '55%+ WR over 20+ trades', earned: trades.length >= 20 && winRate >= 0.55),
    TradeBadge(icon: '⭐', title: 'Sharp Shooter', description: '65%+ WR over 30+ trades', earned: trades.length >= 30 && winRate >= 0.65),
  ];
});

// ─── Emotion Performance Provider (P2) ───────────────────────────────────────

class EmotionStat {
  final String label;
  final int count;
  final double avgR;
  final double winRate;
  const EmotionStat({
    required this.label,
    required this.count,
    required this.avgR,
    required this.winRate,
  });
}

final emotionPerformanceProvider = FutureProvider<List<EmotionStat>>((ref) async {
  final trades = await ref.watch(allTradesProvider.future);
  final withEmotion = trades.where((t) => t.emotionBefore != null).toList();
  if (withEmotion.isEmpty) return [];

  final groups = <String, List<Trade>>{};
  for (final t in withEmotion) {
    final label = t.emotionBefore!.label;
    groups.putIfAbsent(label, () => []).add(t);
  }

  return groups.entries
      .where((e) => e.value.length >= 2)
      .map((e) {
        final ts = e.value;
        final avgR = ts.fold<double>(0, (s, t) => s + t.rMultiple) / ts.length;
        final winRate = ts.where((t) => t.isWin).length / ts.length;
        return EmotionStat(
          label: e.key,
          count: ts.length,
          avgR: avgR,
          winRate: winRate,
        );
      })
      .toList()
    ..sort((a, b) => b.avgR.compareTo(a.avgR));
});

// ─── Private helpers ──────────────────────────────────────────────────────────

class _S {
  int wins = 0, count = 0;
  double totalR = 0;
  double get avgR => count > 0 ? totalR / count : 0;
  double get winRate => count > 0 ? wins / count : 0;
}

Map<K, _S> _group<K>(List<Trade> trades, K Function(Trade) key) {
  final m = <K, _S>{};
  for (final t in trades) {
    final k = key(t);
    m.putIfAbsent(k, _S.new);
    final s = m[k]!;
    s.count++;
    s.totalR += t.rMultiple;
    if (t.isWin) s.wins++;
  }
  return m;
}

void _dayOfWeekInsight(List<Trade> trades, List<TradeInsight> out) {
  if (trades.length < 10) return;
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final stats = _group(trades, (t) => t.entryAt.weekday);
  final eligible = stats.entries.where((e) => e.value.count >= 3).toList();
  if (eligible.length < 2) return;

  final worst = eligible.reduce((a, b) => a.value.avgR < b.value.avgR ? a : b);
  final best = eligible.reduce((a, b) => a.value.avgR > b.value.avgR ? a : b);

  if (worst.value.avgR < -0.2) {
    out.add(TradeInsight(
      type: InsightType.warning,
      title: '${days[worst.key - 1]} is draining your edge',
      body:
          'Avg ${worst.value.avgR.toStringAsFixed(1)}R on ${days[worst.key - 1]} (${worst.value.count} trades). Consider reducing size or skipping this day.',
      icon: '📅',
      metric: worst.value.avgR,
    ));
  }
  if (best.value.avgR > 0.3) {
    out.add(TradeInsight(
      type: InsightType.positive,
      title: '${days[best.key - 1]} is your best day',
      body:
          'Avg +${best.value.avgR.toStringAsFixed(1)}R on ${days[best.key - 1]} with ${(best.value.winRate * 100).toInt()}% WR. Prioritise this day.',
      icon: '🏆',
      metric: best.value.avgR,
    ));
  }
}

void _sessionInsight(List<Trade> trades, List<TradeInsight> out) {
  final with_ = trades.where((t) => t.session != null).toList();
  if (with_.length < 10) return;
  final stats = _group(with_, (t) => t.session!.label);
  final eligible = stats.entries.where((e) => e.value.count >= 3).toList();
  if (eligible.length < 2) return;

  final worst = eligible.reduce((a, b) => a.value.avgR < b.value.avgR ? a : b);
  final best = eligible.reduce((a, b) => a.value.avgR > b.value.avgR ? a : b);

  if (worst.value.avgR < -0.2) {
    out.add(TradeInsight(
      type: InsightType.warning,
      title: '${worst.key} session hurts you',
      body:
          'Avg ${worst.value.avgR.toStringAsFixed(1)}R vs ${best.key}: +${best.value.avgR.toStringAsFixed(1)}R avg. Stick to your stronger session.',
      icon: '⏰',
      metric: worst.value.avgR,
    ));
  }
}

void _emotionInsight(List<Trade> trades, List<TradeInsight> out) {
  final with_ = trades.where((t) => t.emotionBefore != null).toList();
  if (with_.length < 8) return;
  final stats = _group(with_, (t) => t.emotionBefore!.label);
  final eligible = stats.entries.where((e) => e.value.count >= 3).toList();
  if (eligible.length < 2) return;

  final worst = eligible.reduce((a, b) => a.value.avgR < b.value.avgR ? a : b);
  final best = eligible.reduce((a, b) => a.value.avgR > b.value.avgR ? a : b);

  if (worst.value.avgR < 0 && best.value.avgR > 0) {
    out.add(TradeInsight(
      type: InsightType.tip,
      title: 'Your mindset affects your P&L',
      body:
          '${best.key}: +${best.value.avgR.toStringAsFixed(1)}R avg vs ${worst.key}: ${worst.value.avgR.toStringAsFixed(1)}R. Wait for the right emotional state.',
      icon: '🧠',
      metric: best.value.avgR - worst.value.avgR,
    ));
  }
}

void _impulseInsight(List<Trade> trades, List<TradeInsight> out) {
  if (trades.length < 10) return;
  final impulse = trades.where((t) => t.isImpulse).toList();
  if (impulse.isEmpty) {
    out.add(const TradeInsight(
      type: InsightType.positive,
      title: 'Zero impulse trades 🎉',
      body: 'You have never logged an impulse trade. Elite discipline.',
      icon: '🧘',
    ));
    return;
  }
  final totalR = impulse.fold<double>(0, (s, t) => s + t.rMultiple);
  if (totalR < 0) {
    out.add(TradeInsight(
      type: InsightType.warning,
      title: 'Impulse trades cost you ${totalR.abs().toStringAsFixed(1)}R',
      body:
          '${impulse.length} impulse trade${impulse.length > 1 ? 's' : ''} with avg ${(totalR / impulse.length).toStringAsFixed(1)}R. Eliminating these is free alpha.',
      icon: '⚡',
      metric: totalR,
    ));
  }
}

void _afterLossInsight(List<Trade> trades, List<TradeInsight> out) {
  if (trades.length < 15) return;
  final sorted = [...trades]..sort((a, b) => a.entryAt.compareTo(b.entryAt));
  int afterLossWins = 0, afterLossCount = 0;
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i - 1].isLoss) {
      afterLossCount++;
      if (sorted[i].isWin) afterLossWins++;
    }
  }
  if (afterLossCount < 5) return;
  final afterLossWR = afterLossWins / afterLossCount;
  final overallWR = trades.where((t) => t.isWin).length / trades.length;
  if (afterLossWR < overallWR - 0.1) {
    out.add(TradeInsight(
      type: InsightType.warning,
      title: 'Revenge pattern detected',
      body:
          'WR after a loss: ${(afterLossWR * 100).toInt()}% vs overall ${(overallWR * 100).toInt()}%. Take a break after losing trades.',
      icon: '😤',
      metric: afterLossWR,
    ));
  }
}

void _symbolInsight(List<Trade> trades, List<TradeInsight> out) {
  if (trades.length < 15) return;
  final stats = _group(trades, (t) => t.symbol);
  final overallWR = trades.where((t) => t.isWin).length / trades.length;
  for (final e in stats.entries.where((e) => e.value.count >= 4)) {
    if (e.value.winRate < overallWR - 0.15 && e.value.totalR < -1.0) {
      out.add(TradeInsight(
        type: InsightType.warning,
        title: '${e.key} is your weakest pair',
        body:
            '${(e.value.winRate * 100).toInt()}% WR vs ${(overallWR * 100).toInt()}% overall. Total loss: ${e.value.totalR.toStringAsFixed(1)}R. Consider pausing this symbol.',
        icon: '📉',
        metric: e.value.totalR,
      ));
      break;
    }
  }
}

void _newsDayInsight(List<Trade> trades, List<TradeInsight> out) {
  final news = trades.where((t) => t.newsDay).toList();
  final noNews = trades.where((t) => !t.newsDay).toList();
  if (news.length < 5 || noNews.isEmpty) return;
  final newsAvg = news.fold<double>(0, (s, t) => s + t.rMultiple) / news.length;
  final noNewsAvg = noNews.fold<double>(0, (s, t) => s + t.rMultiple) / noNews.length;
  if (newsAvg < noNewsAvg - 0.3) {
    out.add(TradeInsight(
      type: InsightType.tip,
      title: 'News days hurt your results',
      body:
          'News day avg: ${newsAvg.toStringAsFixed(1)}R vs normal: +${noNewsAvg.toStringAsFixed(1)}R. Sitting out high-impact news may add R.',
      icon: '📰',
      metric: newsAvg,
    ));
  }
}

void _setupQualityInsight(List<Trade> trades, List<TradeInsight> out) {
  final high = trades.where((t) => t.setupQuality >= 4).toList();
  final low = trades.where((t) => t.setupQuality <= 2).toList();
  if (high.length < 5 || low.length < 5) return;
  final highAvg = high.fold<double>(0, (s, t) => s + t.rMultiple) / high.length;
  final lowAvg = low.fold<double>(0, (s, t) => s + t.rMultiple) / low.length;
  if (highAvg > lowAvg + 0.3) {
    out.add(TradeInsight(
      type: InsightType.tip,
      title: 'High-quality setups outperform',
      body:
          '4-5★ setups: +${highAvg.toStringAsFixed(1)}R avg vs 1-2★: ${lowAvg.toStringAsFixed(1)}R. Be selective — wait for A+ setups.',
      icon: '⭐',
      metric: highAvg - lowAvg,
    ));
  }
}
