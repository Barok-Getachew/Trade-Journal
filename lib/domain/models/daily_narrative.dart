class DailyNarrative {
  final String id;
  final String userId;
  final DateTime narrativeDate;
  final String? pair;
  final String? session;
  // 5 ICT sentences
  final String? s1HtfBias;
  final String? s2PriceAction;
  final String? s3LiquidityDraw;
  final String? s4Path;
  final String? s5Execution;
  // Post-trade attachment
  final bool? postS5Complete;
  final bool? postDelivered;
  final String? postBreakdown;
  final String? postEmotionalState;
  final String? postPreparedVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyNarrative({
    required this.id,
    required this.userId,
    required this.narrativeDate,
    this.pair,
    this.session,
    this.s1HtfBias,
    this.s2PriceAction,
    this.s3LiquidityDraw,
    this.s4Path,
    this.s5Execution,
    this.postS5Complete,
    this.postDelivered,
    this.postBreakdown,
    this.postEmotionalState,
    this.postPreparedVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get preSessionComplete =>
      s1HtfBias != null &&
      s1HtfBias!.isNotEmpty &&
      s5Execution != null &&
      s5Execution!.isNotEmpty;

  bool get postAttachmentComplete =>
      postS5Complete != null &&
      postDelivered != null;

  factory DailyNarrative.fromMap(Map<String, dynamic> map) => DailyNarrative(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        narrativeDate: DateTime.parse(map['narrative_date'] as String),
        pair: map['pair'] as String?,
        session: map['session'] as String?,
        s1HtfBias: map['s1_htf_bias'] as String?,
        s2PriceAction: map['s2_price_action'] as String?,
        s3LiquidityDraw: map['s3_liquidity_draw'] as String?,
        s4Path: map['s4_path'] as String?,
        s5Execution: map['s5_execution'] as String?,
        postS5Complete: map['post_s5_complete'] as bool?,
        postDelivered: map['post_delivered'] as bool?,
        postBreakdown: map['post_breakdown'] as String?,
        postEmotionalState: map['post_emotional_state'] as String?,
        postPreparedVersion: map['post_prepared_version'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'narrative_date':
            narrativeDate.toIso8601String().substring(0, 10),
        'pair': pair,
        'session': session,
        's1_htf_bias': s1HtfBias,
        's2_price_action': s2PriceAction,
        's3_liquidity_draw': s3LiquidityDraw,
        's4_path': s4Path,
        's5_execution': s5Execution,
        'post_s5_complete': postS5Complete,
        'post_delivered': postDelivered,
        'post_breakdown': postBreakdown,
        'post_emotional_state': postEmotionalState,
        'post_prepared_version': postPreparedVersion,
      };

  DailyNarrative copyWith({
    String? id,
    String? userId,
    DateTime? narrativeDate,
    String? pair,
    String? session,
    String? s1HtfBias,
    String? s2PriceAction,
    String? s3LiquidityDraw,
    String? s4Path,
    String? s5Execution,
    bool? postS5Complete,
    bool? postDelivered,
    String? postBreakdown,
    String? postEmotionalState,
    String? postPreparedVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyNarrative(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        narrativeDate: narrativeDate ?? this.narrativeDate,
        pair: pair ?? this.pair,
        session: session ?? this.session,
        s1HtfBias: s1HtfBias ?? this.s1HtfBias,
        s2PriceAction: s2PriceAction ?? this.s2PriceAction,
        s3LiquidityDraw: s3LiquidityDraw ?? this.s3LiquidityDraw,
        s4Path: s4Path ?? this.s4Path,
        s5Execution: s5Execution ?? this.s5Execution,
        postS5Complete: postS5Complete ?? this.postS5Complete,
        postDelivered: postDelivered ?? this.postDelivered,
        postBreakdown: postBreakdown ?? this.postBreakdown,
        postEmotionalState: postEmotionalState ?? this.postEmotionalState,
        postPreparedVersion: postPreparedVersion ?? this.postPreparedVersion,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
