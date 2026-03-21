import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/charts/chart_widgets.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../auth/providers/repository_providers.dart';

// ── Provider for monthly data ─────────────────────────────────────────────────

final _monthTradesProvider = FutureProvider.family<PortfolioStats, (int, int)>((
  ref,
  args,
) async {
  final (year, month) = args;
  final trades = await ref
      .read(tradeRepositoryProvider)
      .fetchForMonth(month, year);
  return TradeAnalytics.compute(trades, 10000.0);
});

final _prevMonthTradesProvider =
    FutureProvider.family<PortfolioStats, (int, int)>((ref, args) async {
      final (year, month) = args;
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevYear = month == 1 ? year - 1 : year;
      final trades = await ref
          .read(tradeRepositoryProvider)
          .fetchForMonth(prevMonth, prevYear);
      return TradeAnalytics.compute(trades, 10000.0);
    });

// ── Screen ────────────────────────────────────────────────────────────────────

class MonthlyAuditScreen extends ConsumerStatefulWidget {
  final int? year;
  final int? month;
  const MonthlyAuditScreen({super.key, this.year, this.month});

  @override
  ConsumerState<MonthlyAuditScreen> createState() => _MonthlyAuditScreenState();
}

class _MonthlyAuditScreenState extends ConsumerState<MonthlyAuditScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year ?? DateTime.now().year;
    _month = widget.month ?? DateTime.now().month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_monthTradesProvider((_year, _month)));
    final prevAsync = ref.watch(_prevMonthTradesProvider((_year, _month)));
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month nav
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prevMonth,
                  color: AppColors.textSecondary,
                ),
                Text(
                  '${monthNames[_month - 1]} $_year',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextMonth,
                  color: AppColors.textSecondary,
                ),
                const Spacer(),
                Text(
                  'Performance Audit',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Metric cards
            statsAsync.when(
              loading: () => GridView.count(
                crossAxisCount: 5,
                crossAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: List.generate(
                  5,
                  (_) =>
                      const LoadingShimmer(width: double.infinity, height: 100),
                ),
              ),
              error: (e, _) => Text(e.toString()),
              data: (stats) => GridView.count(
                crossAxisCount: 5,
                crossAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _metricCard(
                    context,
                    'Trades',
                    stats.totalTrades.toString(),
                    AppColors.primary,
                    Icons.receipt_long_outlined,
                  ),
                  _metricCard(
                    context,
                    'Win Rate',
                    Fmt.percent(stats.winRate * 100),
                    stats.winRate >= 0.5 ? AppColors.profit : AppColors.loss,
                    Icons.percent_rounded,
                  ),
                  _metricCard(
                    context,
                    'Total R',
                    Fmt.rMultiple(stats.totalR),
                    stats.totalR >= 0 ? AppColors.profit : AppColors.loss,
                    Icons.show_chart_rounded,
                  ),
                  _metricCard(
                    context,
                    'Expectancy',
                    Fmt.rMultiple(stats.expectancy),
                    stats.expectancy >= 0 ? AppColors.profit : AppColors.loss,
                    Icons.insights_rounded,
                  ),
                  _metricCard(
                    context,
                    'Max Drawdown',
                    '${stats.maxDrawdownPct.abs().toStringAsFixed(1)}%',
                    AppColors.loss,
                    Icons.trending_down_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Equity curve & comparison
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equity curve
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Monthly Equity Curve'),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 200,
                          child: statsAsync.when(
                            loading: () => const LoadingShimmer(
                              width: double.infinity,
                              height: 200,
                            ),
                            error: (e, _) => Text(e.toString()),
                            data: (stats) => EquityCurveChart(
                              points: stats.equityCurve,
                              startBalance: 10000,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Month comparison
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'vs Previous Month'),
                        const SizedBox(height: AppSpacing.md),
                        statsAsync.when(
                          loading: () => const LoadingShimmer(
                            width: double.infinity,
                            height: 200,
                          ),
                          error: (e, _) => Text(e.toString()),
                          data: (curr) => prevAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const SizedBox(),
                            data: (prev) => Column(
                              children: [
                                _compRow(
                                  context,
                                  'Expectancy',
                                  curr.expectancy,
                                  prev.expectancy,
                                ),
                                _compRow(
                                  context,
                                  'Win Rate',
                                  curr.winRate * 100,
                                  prev.winRate * 100,
                                  suffix: '%',
                                ),
                                _compRow(
                                  context,
                                  'Rules Followed',
                                  curr.rulesFollowedPct * 100,
                                  prev.rulesFollowedPct * 100,
                                  suffix: '%',
                                ),
                                _compRow(
                                  context,
                                  'Profit Factor',
                                  curr.profitFactor == double.infinity
                                      ? 0
                                      : curr.profitFactor,
                                  prev.profitFactor == double.infinity
                                      ? 0
                                      : prev.profitFactor,
                                ),
                                _compRow(
                                  context,
                                  'Max Drawdown',
                                  curr.maxDrawdownPct,
                                  prev.maxDrawdownPct,
                                  lowerIsBetter: true,
                                  suffix: '%',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Diagnostic tools
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Diagnostic Tools',
                    subtitle: 'Deep-dive into performance drivers',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  statsAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 80,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (stats) => Row(
                      children: [
                        _diagCard(
                          context,
                          'Largest Win',
                          Fmt.currency(stats.largestWin),
                          AppColors.profit,
                          Icons.arrow_upward_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _diagCard(
                          context,
                          'Largest Loss (Cost)',
                          Fmt.currency(stats.largestLoss.abs()),
                          AppColors.loss,
                          Icons.arrow_downward_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _diagCard(
                          context,
                          'Profit Factor',
                          stats.profitFactor == double.infinity
                              ? '∞'
                              : stats.profitFactor.toStringAsFixed(2),
                          stats.profitFactor >= 1.5
                              ? AppColors.profit
                              : AppColors.warning,
                          Icons.balance_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _diagCard(
                          context,
                          'Discipline Score',
                          Fmt.percent(stats.rulesFollowedPct * 100),
                          stats.rulesFollowedPct >= 0.8
                              ? AppColors.profit
                              : AppColors.warning,
                          Icons.gavel_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext ctx,
    String label,
    String val,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          Text(label, style: Theme.of(ctx).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _compRow(
    BuildContext ctx,
    String label,
    double curr,
    double prev, {
    bool lowerIsBetter = false,
    String suffix = '',
  }) {
    final diff = curr - prev;
    final improved = lowerIsBetter ? diff < 0 : diff > 0;
    final color = diff == 0
        ? AppColors.textSecondary
        : improved
        ? AppColors.profit
        : AppColors.loss;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
          ),
          Text(
            '${curr.toStringAsFixed(1)}$suffix',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            improved
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          Text(
            '${diff.abs().toStringAsFixed(1)}$suffix',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _diagCard(
    BuildContext ctx,
    String label,
    String val,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(label, style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
