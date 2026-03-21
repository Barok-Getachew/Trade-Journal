class WeeklyReview {
  final String id;
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalTrades;
  final int wins;
  final int losses;
  final double totalR;
  final double winRate;
  final double rulesFollowedPct;
  final String? bestTradeId;
  final String? worstTradeId;
  final String? commonMistake;
  final double? mentalStateAvg;
  final String? reflection;
  final String? goalsNextWeek;
  final DateTime createdAt;

  const WeeklyReview({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalTrades,
    required this.wins,
    required this.losses,
    required this.totalR,
    required this.winRate,
    required this.rulesFollowedPct,
    this.bestTradeId,
    this.worstTradeId,
    this.commonMistake,
    this.mentalStateAvg,
    this.reflection,
    this.goalsNextWeek,
    required this.createdAt,
  });

  factory WeeklyReview.fromMap(Map<String, dynamic> map) => WeeklyReview(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    weekStart: DateTime.parse(map['week_start'] as String),
    weekEnd: DateTime.parse(map['week_end'] as String),
    totalTrades: map['total_trades'] as int,
    wins: map['wins'] as int,
    losses: map['losses'] as int,
    totalR: (map['total_r'] as num).toDouble(),
    winRate: (map['win_rate'] as num).toDouble(),
    rulesFollowedPct: (map['rules_followed_pct'] as num).toDouble(),
    bestTradeId: map['best_trade_id'] as String?,
    worstTradeId: map['worst_trade_id'] as String?,
    commonMistake: map['common_mistake'] as String?,
    mentalStateAvg: map['mental_state_avg'] != null
        ? (map['mental_state_avg'] as num).toDouble()
        : null,
    reflection: map['reflection'] as String?,
    goalsNextWeek: map['goals_next_week'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'week_start': weekStart.toIso8601String(),
    'week_end': weekEnd.toIso8601String(),
    'total_trades': totalTrades,
    'wins': wins,
    'losses': losses,
    'total_r': totalR,
    'win_rate': winRate,
    'rules_followed_pct': rulesFollowedPct,
    'best_trade_id': bestTradeId,
    'worst_trade_id': worstTradeId,
    'common_mistake': commonMistake,
    'mental_state_avg': mentalStateAvg,
    'reflection': reflection,
    'goals_next_week': goalsNextWeek,
  };
}
