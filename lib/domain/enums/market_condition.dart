enum MarketCondition {
  trending('Trending'),
  ranging('Ranging'),
  choppy('Choppy'),
  volatile('Volatile'),
  breakout('Breakout');

  const MarketCondition(this.label);
  final String label;

  static MarketCondition fromString(String value) {
    return MarketCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MarketCondition.trending,
    );
  }
}
