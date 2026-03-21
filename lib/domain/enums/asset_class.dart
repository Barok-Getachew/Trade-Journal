enum AssetClass {
  forex('Forex'),
  equity('Equity'),
  crypto('Crypto'),
  futures('Futures'),
  options('Options'),
  cfd('CFD');

  const AssetClass(this.label);
  final String label;

  static AssetClass fromString(String value) {
    return AssetClass.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetClass.forex,
    );
  }
}
