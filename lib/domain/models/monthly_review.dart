class MonthlyReview {
  final String id;
  final String userId;
  final int month;
  final int year;
  final int totalTrades;
  final double totalR;
  final double winRate;
  final double monthlyReturnPct;
  final double maxDrawdown;
  final double expectancy;
  final double profitFactor;
  final double rulesFollowedPct;
  final String? reflection;
  final String? goalsNextMonth;
  final DateTime createdAt;

  const MonthlyReview({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.totalTrades,
    required this.totalR,
    required this.winRate,
    required this.monthlyReturnPct,
    required this.maxDrawdown,
    required this.expectancy,
    required this.profitFactor,
    required this.rulesFollowedPct,
    this.reflection,
    this.goalsNextMonth,
    required this.createdAt,
  });

  String get monthLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month - 1]} $year';
  }

  factory MonthlyReview.fromMap(Map<String, dynamic> map) => MonthlyReview(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    month: map['month'] as int,
    year: map['year'] as int,
    totalTrades: map['total_trades'] as int,
    totalR: (map['total_r'] as num).toDouble(),
    winRate: (map['win_rate'] as num).toDouble(),
    monthlyReturnPct: (map['monthly_return_pct'] as num).toDouble(),
    maxDrawdown: (map['max_drawdown'] as num).toDouble(),
    expectancy: (map['expectancy'] as num).toDouble(),
    profitFactor: (map['profit_factor'] as num).toDouble(),
    rulesFollowedPct: (map['rules_followed_pct'] as num).toDouble(),
    reflection: map['reflection'] as String?,
    goalsNextMonth: map['goals_next_month'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'month': month,
    'year': year,
    'total_trades': totalTrades,
    'total_r': totalR,
    'win_rate': winRate,
    'monthly_return_pct': monthlyReturnPct,
    'max_drawdown': maxDrawdown,
    'expectancy': expectancy,
    'profit_factor': profitFactor,
    'rules_followed_pct': rulesFollowedPct,
    'reflection': reflection,
    'goals_next_month': goalsNextMonth,
  };
}
