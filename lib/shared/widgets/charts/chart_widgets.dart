import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Animated equity curve line chart using fl_chart.
class EquityCurveChart extends StatelessWidget {
  final List<EquityPoint> points;
  final double startBalance;

  const EquityCurveChart({
    super.key,
    required this.points,
    required this.startBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.equity))
        .toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final rangeY = (maxY - minY).abs().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: rangeY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.chartGrid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (v, _) => Text(
                Fmt.compact(v),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (spots.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                return Text(
                  Fmt.date(points[idx].date),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.chartTooltipBg,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.spotIndex;
              return LineTooltipItem(
                '${Fmt.currency(s.y)}\n${Fmt.date(points[idx].date)}',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.chartLine,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.chartLine.withOpacity(0.2),
                  AppColors.chartLine.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: minY - rangeY * 0.1,
        maxY: maxY + rangeY * 0.1,
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
}

/// Drawdown area chart.
class DrawdownChart extends StatelessWidget {
  final List<DrawdownPoint> points;

  const DrawdownChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.drawdownPct))
        .toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                Fmt.percent(v),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.loss,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.loss.withOpacity(0.3),
                  AppColors.loss.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: minY * 1.1,
        maxY: 0.5,
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
}

/// Horizontal bar chart for segment breakdowns (strategy, symbol, etc.)
class SegmentBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data; // label → totalR
  final Color? barColor;

  const SegmentBarChart({super.key, required this.data, this.barColor});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxVal =
        data.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.map((entry) {
        final isPositive = entry.value >= 0;
        final color =
            barColor ?? (isPositive ? AppColors.profit : AppColors.loss);
        final fraction = maxVal > 0 ? (entry.value.abs() / maxVal) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          width: constraints.maxWidth * fraction,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  Fmt.rMultiple(entry.value),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPositive ? AppColors.profit : AppColors.loss,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
