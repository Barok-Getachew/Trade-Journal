import '../enums/asset_class.dart';
import '../enums/direction.dart';
import '../enums/emotion_type.dart';
import '../enums/execution_type.dart';
import '../enums/market_condition.dart';
import '../enums/session.dart';

class Trade {
  final String id;
  final String userId;
  final String accountId;
  final String? strategyId;

  // Basic
  final String symbol;
  final AssetClass assetClass;
  final TradeDirection direction;
  final double entryPrice;
  final double exitPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double positionSize;
  final double riskAmount;
  final double riskPct;
  final double commission;
  final DateTime entryAt;
  final DateTime exitAt;
  final double balanceAtEntry;

  // Computed / stored
  final double grossPnl;
  final double netPnl;
  final double rMultiple;
  final String? screenshotUrl;

  // Advanced entry fields
  final ExecutionType executionType;
  final double? plannedRR;
  final double? actualRR;
  final double? slippage;
  final String? setupType;

  // Context
  final MarketCondition? marketCondition;
  final TradingSession? session;
  final bool newsDay;
  final int setupQuality; // 1–5

  // Psychology
  final EmotionType? emotionBefore;
  final EmotionType? emotionAfter;
  final int confidence; // 1–5
  final bool rulesFollowed;
  final bool isImpulse;
  final String? mistakeType;
  final String? reflection;

  // Excursion
  final double? mfe;
  final double? mae;

  // Checklist (Step 0)
  final bool planMatch;
  final bool riskOk;
  final bool rrOk;
  final bool confirmation;
  final bool screenshotReady;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Trade({
    required this.id,
    required this.userId,
    required this.accountId,
    this.strategyId,
    required this.symbol,
    required this.assetClass,
    required this.direction,
    required this.entryPrice,
    required this.exitPrice,
    this.stopLoss,
    this.takeProfit,
    required this.positionSize,
    required this.riskAmount,
    required this.riskPct,
    this.commission = 0.0,
    required this.entryAt,
    required this.exitAt,
    required this.balanceAtEntry,
    required this.grossPnl,
    required this.netPnl,
    required this.rMultiple,
    this.screenshotUrl,
    this.executionType = ExecutionType.market,
    this.plannedRR,
    this.actualRR,
    this.slippage,
    this.setupType,
    this.marketCondition,
    this.session,
    this.newsDay = false,
    this.setupQuality = 3,
    this.emotionBefore,
    this.emotionAfter,
    this.confidence = 3,
    this.rulesFollowed = true,
    this.isImpulse = false,
    this.mistakeType,
    this.reflection,
    this.mfe,
    this.mae,
    this.planMatch = false,
    this.riskOk = false,
    this.rrOk = false,
    this.confirmation = false,
    this.screenshotReady = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isWin => netPnl > 0;
  bool get isLoss => netPnl < 0;
  bool get isBreakeven => netPnl == 0;

  Duration get holdingDuration => exitAt.difference(entryAt);

  double get returnPct =>
      balanceAtEntry > 0 ? (netPnl / balanceAtEntry) * 100 : 0.0;

  double get riskReward {
    if (stopLoss == null || takeProfit == null) return 0.0;
    final risk = (entryPrice - stopLoss!).abs();
    final reward = (takeProfit! - entryPrice).abs();
    return risk > 0 ? reward / risk : 0.0;
  }

  Trade copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? strategyId,
    String? symbol,
    AssetClass? assetClass,
    TradeDirection? direction,
    double? entryPrice,
    double? exitPrice,
    double? stopLoss,
    double? takeProfit,
    double? positionSize,
    double? riskAmount,
    double? riskPct,
    double? commission,
    DateTime? entryAt,
    DateTime? exitAt,
    double? balanceAtEntry,
    double? grossPnl,
    double? netPnl,
    double? rMultiple,
    String? screenshotUrl,
    MarketCondition? marketCondition,
    TradingSession? session,
    bool? newsDay,
    int? setupQuality,
    EmotionType? emotionBefore,
    EmotionType? emotionAfter,
    int? confidence,
    bool? rulesFollowed,
    bool? isImpulse,
    String? mistakeType,
    String? reflection,
    ExecutionType? executionType,
    double? plannedRR,
    double? actualRR,
    double? slippage,
    String? setupType,
    double? mfe,
    double? mae,
    bool? planMatch,
    bool? riskOk,
    bool? rrOk,
    bool? confirmation,
    bool? screenshotReady,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      strategyId: strategyId ?? this.strategyId,
      symbol: symbol ?? this.symbol,
      assetClass: assetClass ?? this.assetClass,
      direction: direction ?? this.direction,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      positionSize: positionSize ?? this.positionSize,
      riskAmount: riskAmount ?? this.riskAmount,
      riskPct: riskPct ?? this.riskPct,
      commission: commission ?? this.commission,
      entryAt: entryAt ?? this.entryAt,
      exitAt: exitAt ?? this.exitAt,
      balanceAtEntry: balanceAtEntry ?? this.balanceAtEntry,
      grossPnl: grossPnl ?? this.grossPnl,
      netPnl: netPnl ?? this.netPnl,
      rMultiple: rMultiple ?? this.rMultiple,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      marketCondition: marketCondition ?? this.marketCondition,
      session: session ?? this.session,
      newsDay: newsDay ?? this.newsDay,
      setupQuality: setupQuality ?? this.setupQuality,
      emotionBefore: emotionBefore ?? this.emotionBefore,
      emotionAfter: emotionAfter ?? this.emotionAfter,
      confidence: confidence ?? this.confidence,
      rulesFollowed: rulesFollowed ?? this.rulesFollowed,
      isImpulse: isImpulse ?? this.isImpulse,
      mistakeType: mistakeType ?? this.mistakeType,
      reflection: reflection ?? this.reflection,
      mfe: mfe ?? this.mfe,
      mae: mae ?? this.mae,
      executionType: executionType ?? this.executionType,
      plannedRR: plannedRR ?? this.plannedRR,
      actualRR: actualRR ?? this.actualRR,
      slippage: slippage ?? this.slippage,
      setupType: setupType ?? this.setupType,
      planMatch: planMatch ?? this.planMatch,
      riskOk: riskOk ?? this.riskOk,
      rrOk: rrOk ?? this.rrOk,
      confirmation: confirmation ?? this.confirmation,
      screenshotReady: screenshotReady ?? this.screenshotReady,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String,
      strategyId: map['strategy_id'] as String?,
      symbol: map['symbol'] as String,
      assetClass: AssetClass.fromString(map['asset_class'] as String),
      direction: TradeDirection.fromString(map['direction'] as String),
      entryPrice: (map['entry_price'] as num).toDouble(),
      exitPrice: (map['exit_price'] as num).toDouble(),
      stopLoss: map['stop_loss'] != null
          ? (map['stop_loss'] as num).toDouble()
          : null,
      takeProfit: map['take_profit'] != null
          ? (map['take_profit'] as num).toDouble()
          : null,
      positionSize: (map['position_size'] as num).toDouble(),
      riskAmount: (map['risk_amount'] as num).toDouble(),
      riskPct: (map['risk_pct'] as num).toDouble(),
      commission: (map['commission'] as num? ?? 0).toDouble(),
      entryAt: DateTime.parse(map['entry_at'] as String),
      exitAt: DateTime.parse(map['exit_at'] as String),
      balanceAtEntry: (map['balance_at_entry'] as num).toDouble(),
      grossPnl: (map['gross_pnl'] as num).toDouble(),
      netPnl: (map['net_pnl'] as num).toDouble(),
      rMultiple: (map['r_multiple'] as num).toDouble(),
      screenshotUrl: map['screenshot_url'] as String?,
      executionType: ExecutionType.fromString(
          map['execution_type'] as String? ?? 'market'),
      plannedRR: map['planned_rr'] != null
          ? (map['planned_rr'] as num).toDouble()
          : null,
      actualRR: map['actual_rr'] != null
          ? (map['actual_rr'] as num).toDouble()
          : null,
      slippage:
          map['slippage'] != null ? (map['slippage'] as num).toDouble() : null,
      setupType: map['setup_type'] as String?,
      marketCondition: map['market_condition'] != null
          ? MarketCondition.fromString(map['market_condition'] as String)
          : null,
      session: map['session'] != null
          ? TradingSession.fromString(map['session'] as String)
          : null,
      newsDay: map['news_day'] as bool? ?? false,
      setupQuality: map['setup_quality'] as int? ?? 3,
      emotionBefore: map['emotion_before'] != null
          ? EmotionType.fromString(map['emotion_before'] as String)
          : null,
      emotionAfter: map['emotion_after'] != null
          ? EmotionType.fromString(map['emotion_after'] as String)
          : null,
      confidence: map['confidence'] as int? ?? 3,
      rulesFollowed: map['rules_followed'] as bool? ?? true,
      isImpulse: map['is_impulse'] as bool? ?? false,
      mistakeType: map['mistake_type'] as String?,
      reflection: map['reflection'] as String?,
      mfe: map['mfe'] != null ? (map['mfe'] as num).toDouble() : null,
      mae: map['mae'] != null ? (map['mae'] as num).toDouble() : null,
      planMatch: map['plan_match'] as bool? ?? false,
      riskOk: map['risk_ok'] as bool? ?? false,
      rrOk: map['rr_ok'] as bool? ?? false,
      confirmation: map['confirmation'] as bool? ?? false,
      screenshotReady: map['screenshot_ready'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'strategy_id': strategyId,
      'symbol': symbol,
      'asset_class': assetClass.name,
      'direction': direction.name,
      'entry_price': entryPrice,
      'exit_price': exitPrice,
      'stop_loss': stopLoss,
      'take_profit': takeProfit,
      'position_size': positionSize,
      'risk_amount': riskAmount,
      'risk_pct': riskPct,
      'commission': commission,
      'entry_at': entryAt.toIso8601String(),
      'exit_at': exitAt.toIso8601String(),
      'balance_at_entry': balanceAtEntry,
      'gross_pnl': grossPnl,
      'net_pnl': netPnl,
      'r_multiple': rMultiple,
      'market_condition': marketCondition?.name,
      'session': session?.name,
      'news_day': newsDay,
      'setup_quality': setupQuality,
      'emotion_before': emotionBefore?.name,
      'emotion_after': emotionAfter?.name,
      'confidence': confidence,
      'rules_followed': rulesFollowed,
      'is_impulse': isImpulse,
      'mistake_type': mistakeType,
      'reflection': reflection,
      'mfe': mfe,
      'mae': mae,
      'execution_type': executionType.name,
      'planned_rr': plannedRR,
      'actual_rr': actualRR,
      'slippage': slippage,
      'setup_type': setupType,
      'plan_match': planMatch,
      'risk_ok': riskOk,
      'rr_ok': rrOk,
      'confirmation': confirmation,
      'screenshot_ready': screenshotReady,
    };
  }
}
