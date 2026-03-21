/// Per-account risk rules defined by the user.
class RiskRule {
  final String id;
  final String userId;
  final String accountId;
  final double maxDailyLossPct; // e.g. 2.0 means 2%
  final double maxWeeklyLossPct;
  final int maxTradesPerDay;
  final double maxRiskPerTrade; // % of account balance
  final double minRrRatio; // minimum planned R:R
  final DateTime createdAt;
  final DateTime updatedAt;

  const RiskRule({
    required this.id,
    required this.userId,
    required this.accountId,
    this.maxDailyLossPct = 2.0,
    this.maxWeeklyLossPct = 5.0,
    this.maxTradesPerDay = 3,
    this.maxRiskPerTrade = 1.0,
    this.minRrRatio = 1.5,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Default rule set (used before user has saved any rules)
  factory RiskRule.defaults({
    required String userId,
    required String accountId,
  }) =>
      RiskRule(
        id: '',
        userId: userId,
        accountId: accountId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory RiskRule.fromMap(Map<String, dynamic> map) => RiskRule(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        accountId: map['account_id'] as String,
        maxDailyLossPct: (map['max_daily_loss_pct'] as num? ?? 2.0).toDouble(),
        maxWeeklyLossPct:
            (map['max_weekly_loss_pct'] as num? ?? 5.0).toDouble(),
        maxTradesPerDay: map['max_trades_per_day'] as int? ?? 3,
        maxRiskPerTrade: (map['max_risk_per_trade'] as num? ?? 1.0).toDouble(),
        minRrRatio: (map['min_rr_ratio'] as num? ?? 1.5).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'max_daily_loss_pct': maxDailyLossPct,
        'max_weekly_loss_pct': maxWeeklyLossPct,
        'max_trades_per_day': maxTradesPerDay,
        'max_risk_per_trade': maxRiskPerTrade,
        'min_rr_ratio': minRrRatio,
      };

  RiskRule copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? maxDailyLossPct,
    double? maxWeeklyLossPct,
    int? maxTradesPerDay,
    double? maxRiskPerTrade,
    double? minRrRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      RiskRule(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId ?? this.accountId,
        maxDailyLossPct: maxDailyLossPct ?? this.maxDailyLossPct,
        maxWeeklyLossPct: maxWeeklyLossPct ?? this.maxWeeklyLossPct,
        maxTradesPerDay: maxTradesPerDay ?? this.maxTradesPerDay,
        maxRiskPerTrade: maxRiskPerTrade ?? this.maxRiskPerTrade,
        minRrRatio: minRrRatio ?? this.minRrRatio,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
