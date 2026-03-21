import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../core/theme/app_colors.dart';

class PerformanceRadarChart extends StatelessWidget {
  final PortfolioStats stats;

  const PerformanceRadarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Normalize values to 0-100 scale for radar
    final winRate = (stats.winRate * 100).clamp(0, 100).toDouble();
    final profitFactor =
        (stats.profitFactor * 20).clamp(0, 100).toDouble(); // 5.0 PF = 100
    final adherence = (stats.rulesFollowedPct * 100).clamp(0, 100).toDouble();
    final recovery =
        (stats.recoveryFactor * 33.3).clamp(0, 100).toDouble(); // 3.0 RF = 100
    final consistency = (stats.consistencyScore * 100).clamp(0, 100).toDouble();

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        dataSets: [
          RadarDataSet(
            fillColor: AppColors.profit.withOpacity(0.2),
            borderColor: AppColors.profit,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: winRate),
              RadarEntry(value: profitFactor),
              RadarEntry(value: adherence),
              RadarEntry(value: recovery),
              RadarEntry(value: consistency),
            ],
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: AppColors.border, width: 1),
        tickCount: 4,
        ticksTextStyle:
            const TextStyle(color: Colors.transparent, fontSize: 10),
        getTitle: (index, angle) {
          switch (index) {
            case 0:
              return RadarChartTitle(text: 'Win Rate', angle: angle);
            case 1:
              return RadarChartTitle(text: 'Profit Factor', angle: angle);
            case 2:
              return RadarChartTitle(text: 'Plan Adherence', angle: angle);
            case 3:
              return RadarChartTitle(text: 'Recovery Factor', angle: angle);
            case 4:
              return RadarChartTitle(text: 'Consistency', angle: angle);
            default:
              return const RadarChartTitle(text: '');
          }
        },
        titleTextStyle: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        gridBorderData: const BorderSide(color: AppColors.border, width: 1),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
}
