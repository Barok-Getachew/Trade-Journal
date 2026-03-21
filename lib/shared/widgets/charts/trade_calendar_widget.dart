import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';

class TradeCalendar extends StatefulWidget {
  final Map<DateTime, double> dailyPnl;
  final Map<DateTime, int>? tradeCounts;

  const TradeCalendar({
    super.key,
    required this.dailyPnl,
    this.tradeCounts,
  });

  @override
  State<TradeCalendar> createState() => _TradeCalendarState();
}

class _TradeCalendarState extends State<TradeCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _prevMonth() => setState(() =>
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1));
  void _nextMonth() => setState(() =>
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);

    // Calendar logic
    final firstDay = _currentMonth;
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final weekdayOfFirst = firstDay.weekday; // 1 (Mon) - 7 (Sun)

    // We want Mon-Sun. If firstDay is Sun (7), we need 6 padding days.
    // If firstDay is Mon (1), 0 padding.
    final paddingDays = weekdayOfFirst - 1;

    return Column(
      children: [
        // Header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: _prevMonth,
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: _nextMonth,
            ),
            const SizedBox(width: AppSpacing.md),
            // P/L Summary for current month view
            _monthTotalBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Grid
        _buildGrid(paddingDays, daysInMonth),
      ],
    );
  }

  Widget _monthTotalBadge() {
    double total = 0;
    widget.dailyPnl.forEach((date, pnl) {
      if (date.year == _currentMonth.year &&
          date.month == _currentMonth.month) {
        total += pnl;
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: total >= 0 ? AppColors.profitDim : AppColors.lossDim,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'PnL: ${Fmt.currency(total)}',
        style: TextStyle(
          color: total >= 0 ? AppColors.profit : AppColors.loss,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGrid(int padding, int days) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
      'Summary'
    ];

    return Table(
      children: [
        // Header row
        TableRow(
          children: weekdays
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
        ),
        // Days
        ..._generateRows(padding, days),
      ],
    );
  }

  List<TableRow> _generateRows(int padding, int days) {
    final rows = <TableRow>[];
    int dayCount = 1;
    bool monthStarted = false;

    for (int r = 0; r < 6; r++) {
      // Max 6 rows
      final rowCells = <Widget>[];
      double weekTotal = 0;
      bool anyDataInWeek = false;

      for (int c = 0; c < 7; c++) {
        if (!monthStarted && c == padding) monthStarted = true;

        if (monthStarted && dayCount <= days) {
          final date =
              DateTime(_currentMonth.year, _currentMonth.month, dayCount);
          final pnl = widget.dailyPnl[date] ?? 0;
          final count = widget.tradeCounts?[date];
          weekTotal += pnl;
          if (widget.dailyPnl.containsKey(date)) anyDataInWeek = true;

          rowCells.add(_CalendarDayCell(
              day: dayCount,
              pnl: pnl,
              tradeCount: count,
              hasData: widget.dailyPnl.containsKey(date)));
          dayCount++;
        } else {
          rowCells.add(const SizedBox(height: 50));
        }
      }

      // Add summary cell
      rowCells.add(_SummaryCell(total: weekTotal, active: anyDataInWeek));

      rows.add(TableRow(children: rowCells));
      if (dayCount > days) break;
    }
    return rows;
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final double pnl;
  final bool hasData;
  final int? tradeCount;

  const _CalendarDayCell({
    required this.day,
    required this.pnl,
    required this.hasData,
    this.tradeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = pnl > 0;
    final isLoss = pnl < 0;

    return Container(
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: hasData
            ? (isProfit
                ? AppColors.profit.withOpacity(0.15)
                : (isLoss
                    ? AppColors.loss.withOpacity(0.15)
                    : AppColors.surfaceElevated))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasData
              ? (isProfit
                  ? AppColors.profit.withOpacity(0.3)
                  : (isLoss
                      ? AppColors.loss.withOpacity(0.3)
                      : AppColors.border))
              : AppColors.border.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  color: hasData ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (tradeCount != null && tradeCount! > 0) ...[
                const SizedBox(width: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '$tradeCount',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasData && pnl != 0) ...[
            const SizedBox(height: 4),
            Text(
              Fmt.compact(pnl),
              style: TextStyle(
                color: isProfit ? AppColors.profit : AppColors.loss,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final double total;
  final bool active;

  const _SummaryCell({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox(height: 60);

    return Container(
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('W-PnL',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            Fmt.compact(total),
            style: TextStyle(
              color: total >= 0 ? AppColors.profit : AppColors.loss,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
