/// Pre-trade checklist — all 5 items must be confirmed before saving a trade.
class TradeChecklist {
  final String id;
  final String tradeId;
  final String userId;
  final bool planMatch; // Setup is part of the trading plan
  final bool riskOk; // Risk ≤ allowed daily risk
  final bool rrOk; // R:R meets minimum rule
  final bool confirmationOk; // Confirmation signal was respected
  final bool screenshotOk; // Screenshot is attached
  final DateTime createdAt;

  const TradeChecklist({
    required this.id,
    required this.tradeId,
    required this.userId,
    this.planMatch = false,
    this.riskOk = false,
    this.rrOk = false,
    this.confirmationOk = false,
    this.screenshotOk = false,
    required this.createdAt,
  });

  bool get allConfirmed =>
      planMatch && riskOk && rrOk && confirmationOk && screenshotOk;

  factory TradeChecklist.fromMap(Map<String, dynamic> map) => TradeChecklist(
        id: map['id'] as String,
        tradeId: map['trade_id'] as String,
        userId: map['user_id'] as String,
        planMatch: map['plan_match'] as bool? ?? false,
        riskOk: map['risk_ok'] as bool? ?? false,
        rrOk: map['rr_ok'] as bool? ?? false,
        confirmationOk: map['confirmation_ok'] as bool? ?? false,
        screenshotOk: map['screenshot_ok'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'trade_id': tradeId,
        'user_id': userId,
        'plan_match': planMatch,
        'risk_ok': riskOk,
        'rr_ok': rrOk,
        'confirmation_ok': confirmationOk,
        'screenshot_ok': screenshotOk,
      };

  TradeChecklist copyWith({
    String? id,
    String? tradeId,
    String? userId,
    bool? planMatch,
    bool? riskOk,
    bool? rrOk,
    bool? confirmationOk,
    bool? screenshotOk,
    DateTime? createdAt,
  }) =>
      TradeChecklist(
        id: id ?? this.id,
        tradeId: tradeId ?? this.tradeId,
        userId: userId ?? this.userId,
        planMatch: planMatch ?? this.planMatch,
        riskOk: riskOk ?? this.riskOk,
        rrOk: rrOk ?? this.rrOk,
        confirmationOk: confirmationOk ?? this.confirmationOk,
        screenshotOk: screenshotOk ?? this.screenshotOk,
        createdAt: createdAt ?? this.createdAt,
      );
}
