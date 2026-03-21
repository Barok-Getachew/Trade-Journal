import 'package:csv/csv.dart';

enum CsvFormat { mt4, mt5, ctrader }

class CsvImportService {
  /// Parse CSV content into a list of Trade objects (partial, missing IDs and account info).
  static List<Map<String, dynamic>> parse(String content, CsvFormat format) {
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) return [];

    final headers =
        rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1);

    switch (format) {
      case CsvFormat.mt4:
        return _parseMT4(headers, dataRows);
      case CsvFormat.mt5:
        return _parseMT5(headers, dataRows);
      case CsvFormat.ctrader:
        return _parseCTrader(headers, dataRows);
    }
  }

  static List<Map<String, dynamic>> _parseMT4(
      List<String> headers, Iterable<List<dynamic>> rows) {
    final trades = <Map<String, dynamic>>[];

    // MT4 typically: Order, Time, Type, Size, Symbol, Price, S/L, T/P, Time, Price, Commission, Taxes, Swap, Profit
    for (final row in rows) {
      try {
        final type = row[2].toString().toLowerCase();
        if (type != 'buy' && type != 'sell')
          continue; // Skip deposits/withdrawals

        final symbol = row[4].toString();
        final size = double.tryParse(row[3].toString()) ?? 0.0;
        final entryTime =
            DateTime.parse(row[1].toString().replaceAll('.', '-'));
        final exitTime = DateTime.parse(row[8].toString().replaceAll('.', '-'));
        final entryPrice = double.tryParse(row[5].toString()) ?? 0.0;
        final exitPrice = double.tryParse(row[9].toString()) ?? 0.0;
        final profit = double.tryParse(row[13].toString()) ?? 0.0;
        final commission = double.tryParse(row[10].toString()) ?? 0.0;
        final swap = double.tryParse(row[12].toString()) ?? 0.0;
        final netProfit = profit + commission + swap;

        trades.add({
          'symbol': symbol,
          'asset_class': _guessAssetClass(symbol),
          'direction': type == 'buy' ? 'long' : 'short',
          'entry_price': entryPrice,
          'exit_price': exitPrice,
          'position_size': size,
          'entry_at': entryTime.toIso8601String(),
          'exit_at': exitTime.toIso8601String(),
          'commission': (commission + swap).abs(),
          'gross_pnl': profit,
          'net_pnl': netProfit,
        });
      } catch (_) {
        continue;
      }
    }
    return trades;
  }

  static List<Map<String, dynamic>> _parseMT5(
      List<String> headers, Iterable<List<dynamic>> rows) {
    // MT5 is very similar to MT4 but often has different column order
    return _parseMT4(headers, rows); // Placeholder for now
  }

  static List<Map<String, dynamic>> _parseCTrader(
      List<String> headers, Iterable<List<dynamic>> rows) {
    final trades = <Map<String, dynamic>>[];
    // cTrader typically: ID, Symbol, Direction, Volume, Entry Price, Close Price, Entry Time, Close Time, Gross Pips, Commission, Swap, Net Profit
    for (final row in rows) {
      try {
        final symbol = row[1].toString();
        final type = row[2].toString().toLowerCase(); // Buy/Sell
        final size = double.tryParse(row[3].toString()) ?? 0.0;
        final entryTime = DateTime.parse(row[6].toString());
        final exitTime = DateTime.parse(row[7].toString());
        final entryPrice = double.tryParse(row[4].toString()) ?? 0.0;
        final exitPrice = double.tryParse(row[5].toString()) ?? 0.0;
        final netProfit = double.tryParse(row[11].toString()) ?? 0.0;
        final commission = double.tryParse(row[9].toString()) ?? 0.0;

        trades.add({
          'symbol': symbol,
          'asset_class': _guessAssetClass(symbol),
          'direction': type == 'buy' ? 'long' : 'short',
          'entry_price': entryPrice,
          'exit_price': exitPrice,
          'position_size': size,
          'entry_at': entryTime.toIso8601String(),
          'exit_at': exitTime.toIso8601String(),
          'commission': commission.abs(),
          'gross_pnl': netProfit - commission,
          'net_pnl': netProfit,
        });
      } catch (_) {
        continue;
      }
    }
    return trades;
  }

  static String _guessAssetClass(String symbol) {
    final s = symbol.toUpperCase();
    if (s.contains('USD') ||
        s.contains('EUR') ||
        s.contains('GBP') ||
        s.contains('JPY') ||
        s.contains('AUD') ||
        s.contains('CAD') ||
        s.contains('CHF') ||
        s.contains('NZD')) {
      return 'forex';
    }
    if (s.contains('BTC') ||
        s.contains('ETH') ||
        s.contains('XRP') ||
        s.contains('SOL')) {
      return 'crypto';
    }
    if (s.contains('XAU') ||
        s.contains('GOLD') ||
        s.contains('OIL') ||
        s.contains('WTI') ||
        s.contains('XAG')) {
      return 'commodities';
    }
    if (s.contains('US30') ||
        s.contains('NAS100') ||
        s.contains('GER40') ||
        s.contains('SPX500')) {
      return 'indices';
    }
    return 'stocks';
  }
}
