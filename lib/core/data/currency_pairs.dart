/// Comprehensive list of currency pairs and instruments grouped by asset class.
/// Used in the trade entry form symbol selector.

class CurrencyPairs {
  CurrencyPairs._();

  static const Map<String, List<String>> byCategory = {
    'Forex — Majors': [
      'EURUSD',
      'GBPUSD',
      'USDJPY',
      'USDCHF',
      'AUDUSD',
      'USDCAD',
      'NZDUSD',
    ],
    'Forex — Minors': [
      'EURGBP',
      'EURJPY',
      'EURCHF',
      'EURAUD',
      'EURCAD',
      'EURNZD',
      'GBPJPY',
      'GBPCHF',
      'GBPAUD',
      'GBPCAD',
      'GBPNZD',
      'AUDJPY',
      'AUDCHF',
      'AUDCAD',
      'AUDNZD',
      'CADJPY',
      'CADCHF',
      'CHFJPY',
      'NZDJPY',
      'NZDCHF',
      'NZDCAD',
    ],
    'Forex — Exotics': [
      'USDTRY',
      'USDZAR',
      'USDMXN',
      'USDSGD',
      'USDNOK',
      'USDSEK',
      'USDDKK',
      'USDPLN',
      'USDHKD',
      'USDCNH',
      'EURTRY',
      'GBPTRY',
      'EURZAR',
      'GBPZAR',
    ],
    'Metals': [
      'XAUUSD',
      'XAGUSD',
      'XPTUSD',
      'XPDUSD',
      'XAUEUR',
      'XAUGBP',
    ],
    'Indices': [
      'US30', // Dow Jones
      'US500', // S&P 500
      'NAS100', // Nasdaq
      'US2000', // Russell 2000
      'UK100', // FTSE 100
      'GER40', // DAX
      'FRA40', // CAC 40
      'ESP35', // IBEX 35
      'JPN225', // Nikkei 225
      'AUS200', // ASX 200
      'HK50', // Hang Seng
      'CHN50', // China A50
    ],
    'Commodities': [
      'USOIL',
      'UKOIL',
      'NGAS',
      'CORN',
      'WHEAT',
      'SOYBEAN',
      'SUGAR',
      'COFFEE',
      'COTTON',
      'COPPER',
    ],
    'Crypto': [
      'BTCUSD',
      'ETHUSD',
      'LTCUSD',
      'XRPUSD',
      'BNBUSD',
      'ADAUSD',
      'SOLUSD',
      'DOTUSD',
      'AVAXUSD',
      'LINKUSD',
      'MATICUSD',
      'DOGEUSD',
    ],
  };

  /// Flat sorted list for autocomplete search.
  static final List<String> all = [
    for (final list in byCategory.values) ...list,
  ];

  /// Find the asset class category for a given symbol.
  static String categoryFor(String symbol) {
    for (final entry in byCategory.entries) {
      if (entry.value.contains(symbol.toUpperCase())) {
        return entry.key.split(' — ').first;
      }
    }
    return 'forex';
  }
}
