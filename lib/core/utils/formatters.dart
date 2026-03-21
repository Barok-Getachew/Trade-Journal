import 'package:intl/intl.dart';

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _pctFmt = NumberFormat('#,##0.00');
final _rFmt = NumberFormat('+#,##0.00;-#,##0.00', 'en_US');
final _dateFmt = DateFormat('MMM d, yyyy');
final _timeFmt = DateFormat('HH:mm');
final _dateTimeFmt = DateFormat('MMM d, yyyy HH:mm');

class Fmt {
  Fmt._();

  /// Format as currency: $1,234.56
  static String currency(double? value) {
    if (value == null) return '—';
    return _currencyFmt.format(value);
  }

  /// Format as percentage: 68.50%
  static String percent(double? value) {
    if (value == null) return '—';
    return '${_pctFmt.format(value)}%';
  }

  /// Format R-multiple with sign: +2.35R / -1.20R
  static String rMultiple(double? value) {
    if (value == null) return '—';
    return '${_rFmt.format(value)}R';
  }

  /// Format as compact number: 12.5K
  static String compact(double value) {
    if (value.abs() >= 1000000)
      return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }

  /// Format price
  static String price(double? value, {int decimals = 5}) {
    if (value == null) return '—';
    return value.toStringAsFixed(decimals);
  }

  static String date(DateTime? dt) =>
      dt == null ? '—' : _dateFmt.format(dt.toLocal());
  static String time(DateTime? dt) =>
      dt == null ? '—' : _timeFmt.format(dt.toLocal());
  static String dateTime(DateTime? dt) =>
      dt == null ? '—' : _dateTimeFmt.format(dt.toLocal());

  /// Duration: 2h 35m
  static String duration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${d.inMinutes}m';
  }

  /// Signed value with + or -
  static String signed(double? value, {String suffix = ''}) {
    if (value == null) return '—';
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}$suffix';
  }
}
