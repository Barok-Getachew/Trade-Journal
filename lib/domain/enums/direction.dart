enum TradeDirection {
  long('Long'),
  short('Short');

  const TradeDirection(this.label);
  final String label;

  static TradeDirection fromString(String value) {
    return TradeDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TradeDirection.long,
    );
  }
}
