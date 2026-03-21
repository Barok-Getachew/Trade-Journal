enum TradingSession {
  asian('Asian'),
  london('London'),
  newYork('New York'),
  overlap('London/NY Overlap'),
  preMarket('Pre-Market');

  const TradingSession(this.label);
  final String label;

  static TradingSession fromString(String value) {
    return TradingSession.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TradingSession.london,
    );
  }
}
