enum AccountType {
  demo,
  live,
  funded;

  String get label => switch (this) {
        AccountType.demo => 'Demo',
        AccountType.live => 'Live',
        AccountType.funded => 'Funded',
      };

  String get badgeLabel => switch (this) {
        AccountType.demo => 'DEMO',
        AccountType.live => 'LIVE',
        AccountType.funded => 'FUNDED',
      };

  static AccountType fromString(String s) => switch (s.toLowerCase()) {
        'demo' => AccountType.demo,
        'funded' => AccountType.funded,
        _ => AccountType.live,
      };
}
