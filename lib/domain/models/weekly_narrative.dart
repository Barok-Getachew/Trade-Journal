class LiquidityLevel {
  final String type;
  final String level;
  final String notes;

  const LiquidityLevel({
    required this.type,
    this.level = '',
    this.notes = '',
  });

  factory LiquidityLevel.fromMap(Map<String, dynamic> map) => LiquidityLevel(
        type: map['type'] as String,
        level: map['level'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'level': level,
        'notes': notes,
      };

  LiquidityLevel copyWith({String? type, String? level, String? notes}) =>
      LiquidityLevel(
        type: type ?? this.type,
        level: level ?? this.level,
        notes: notes ?? this.notes,
      );
}

class WeeklyNarrative {
  final String id;
  final String userId;
  final DateTime weekOf;
  final String? primaryInstrument;
  final String? highImpactNews;
  // 5 steps
  final String? step1Cot;
  final String? step2HtfStructure;
  final List<LiquidityLevel> liquidityMap;
  final String? step4Amd;
  final String? scenarioA;
  final String? scenarioB;
  // Weekly reflection
  final String? reflScenarioPlayed;
  final bool? reflAmdCorrect;
  final String? reflCleanestDay;
  final int? reflCompleteS5Count;
  final String? reflCarryForward;

  final DateTime createdAt;
  final DateTime updatedAt;

  const WeeklyNarrative({
    required this.id,
    required this.userId,
    required this.weekOf,
    this.primaryInstrument,
    this.highImpactNews,
    this.step1Cot,
    this.step2HtfStructure,
    this.liquidityMap = const [],
    this.step4Amd,
    this.scenarioA,
    this.scenarioB,
    this.reflScenarioPlayed,
    this.reflAmdCorrect,
    this.reflCleanestDay,
    this.reflCompleteS5Count,
    this.reflCarryForward,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get preWeekComplete =>
      step1Cot != null && step1Cot!.isNotEmpty &&
      scenarioA != null && scenarioA!.isNotEmpty &&
      scenarioB != null && scenarioB!.isNotEmpty;

  bool get reflectionComplete =>
      reflScenarioPlayed != null && reflScenarioPlayed!.isNotEmpty;

  static List<LiquidityLevel> defaultLiquidityMap() => const [
        LiquidityLevel(type: 'Buyside Liquidity', level: '', notes: 'Highs / stops above'),
        LiquidityLevel(type: 'Sellside Liquidity', level: '', notes: 'Lows / stops below'),
        LiquidityLevel(type: 'Unmitigated FVG Above', level: '', notes: ''),
        LiquidityLevel(type: 'Unmitigated FVG Below', level: '', notes: ''),
        LiquidityLevel(type: 'Key OB Above', level: '', notes: ''),
        LiquidityLevel(type: 'Key OB Below', level: '', notes: ''),
      ];

  factory WeeklyNarrative.fromMap(Map<String, dynamic> map) {
    final rawMap = map['liquidity_map'];
    List<LiquidityLevel> liqMap = [];
    if (rawMap is List) {
      liqMap = rawMap
          .map((e) => LiquidityLevel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    if (liqMap.isEmpty) liqMap = defaultLiquidityMap();

    return WeeklyNarrative(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      weekOf: DateTime.parse(map['week_of'] as String),
      primaryInstrument: map['primary_instrument'] as String?,
      highImpactNews: map['high_impact_news'] as String?,
      step1Cot: map['step1_cot'] as String?,
      step2HtfStructure: map['step2_htf_structure'] as String?,
      liquidityMap: liqMap,
      step4Amd: map['step4_amd'] as String?,
      scenarioA: map['scenario_a'] as String?,
      scenarioB: map['scenario_b'] as String?,
      reflScenarioPlayed: map['refl_scenario_played'] as String?,
      reflAmdCorrect: map['refl_amd_correct'] as bool?,
      reflCleanestDay: map['refl_cleanest_day'] as String?,
      reflCompleteS5Count: map['refl_complete_s5_count'] as int?,
      reflCarryForward: map['refl_carry_forward'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'week_of': weekOf.toIso8601String().substring(0, 10),
        'primary_instrument': primaryInstrument,
        'high_impact_news': highImpactNews,
        'step1_cot': step1Cot,
        'step2_htf_structure': step2HtfStructure,
        'liquidity_map': liquidityMap.map((e) => e.toMap()).toList(),
        'step4_amd': step4Amd,
        'scenario_a': scenarioA,
        'scenario_b': scenarioB,
        'refl_scenario_played': reflScenarioPlayed,
        'refl_amd_correct': reflAmdCorrect,
        'refl_cleanest_day': reflCleanestDay,
        'refl_complete_s5_count': reflCompleteS5Count,
        'refl_carry_forward': reflCarryForward,
      };

  WeeklyNarrative copyWith({
    String? id,
    String? userId,
    DateTime? weekOf,
    String? primaryInstrument,
    String? highImpactNews,
    String? step1Cot,
    String? step2HtfStructure,
    List<LiquidityLevel>? liquidityMap,
    String? step4Amd,
    String? scenarioA,
    String? scenarioB,
    String? reflScenarioPlayed,
    bool? reflAmdCorrect,
    String? reflCleanestDay,
    int? reflCompleteS5Count,
    String? reflCarryForward,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WeeklyNarrative(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        weekOf: weekOf ?? this.weekOf,
        primaryInstrument: primaryInstrument ?? this.primaryInstrument,
        highImpactNews: highImpactNews ?? this.highImpactNews,
        step1Cot: step1Cot ?? this.step1Cot,
        step2HtfStructure: step2HtfStructure ?? this.step2HtfStructure,
        liquidityMap: liquidityMap ?? this.liquidityMap,
        step4Amd: step4Amd ?? this.step4Amd,
        scenarioA: scenarioA ?? this.scenarioA,
        scenarioB: scenarioB ?? this.scenarioB,
        reflScenarioPlayed: reflScenarioPlayed ?? this.reflScenarioPlayed,
        reflAmdCorrect: reflAmdCorrect ?? this.reflAmdCorrect,
        reflCleanestDay: reflCleanestDay ?? this.reflCleanestDay,
        reflCompleteS5Count: reflCompleteS5Count ?? this.reflCompleteS5Count,
        reflCarryForward: reflCarryForward ?? this.reflCarryForward,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
