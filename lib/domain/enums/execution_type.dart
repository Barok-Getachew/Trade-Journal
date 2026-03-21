enum ExecutionType {
  market,
  limit,
  stop;

  String get label => switch (this) {
        ExecutionType.market => 'Market',
        ExecutionType.limit => 'Limit',
        ExecutionType.stop => 'Stop',
      };

  static ExecutionType fromString(String s) => switch (s.toLowerCase()) {
        'limit' => ExecutionType.limit,
        'stop' => ExecutionType.stop,
        _ => ExecutionType.market,
      };
}
