import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/metric_card.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/charts/chart_widgets.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/charts/radar_chart_widget.dart';
import '../../../shared/widgets/charts/trade_calendar_widget.dart';
import '../providers/dashboard_provider.dart';
import '../providers/premarket_checklist_provider.dart';
import '../widgets/monthly_target_card.dart';
import '../widgets/trade_highlight_card.dart';
import '../../../analytics/trade_analytics.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _kMobileBreak = 700.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final startBalanceAsync = ref.watch(startingBalanceProvider);
    final startBalance = startBalanceAsync.value ?? 10000.0;
    final checklist = ref.watch(premarketChecklistProvider);
    final isMobile = MediaQuery.of(context).size.width < _kMobileBreak;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pre-Market Checklist ────────────────────────────────────────
            _PremarketChecklistCard(state: checklist),
            const SizedBox(height: AppSpacing.md),
            // ── Safety Alert Banners ──────────────────────────────────────────
            alertsAsync.when(
              data: (alerts) => alerts.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        ...alerts.map((a) => _alertBanner(context, ref, a)),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // ── Streak Tracker ────────────────────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => Column(children: [
                _streakBanner(stats),
                const SizedBox(height: AppSpacing.md),
                const MonthlyTargetCard(),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Metric Cards + Stats ──────────────────────────────────────────
            statsAsync.when(
              loading: () => _metricsShimmer(isMobile),
              error: (e, _) => _errorBanner(e.toString()),
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: core metrics + discipline ring
                  if (isMobile)
                    ..._buildMobileMetrics(stats)
                  else
                    ..._buildDesktopMetrics(stats),

                  const SizedBox(height: AppSpacing.md),
                  // Row 2: Professional metrics (Sharpe / Sortino / Calmar)
                  if (isMobile)
                    _buildMobileProfMetrics(stats)
                  else
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'SHARPE RATIO',
                            value: stats.sharpeRatio.toStringAsFixed(2),
                            subtitle: 'Risk-adjusted return',
                            icon: Icons.analytics_outlined,
                            valueColor: stats.sharpeRatio > 1
                                ? AppColors.profit
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MetricCard(
                            label: 'SORTINO RATIO',
                            value: stats.sortinoRatio.toStringAsFixed(2),
                            subtitle: 'Downside risk-adjusted',
                            icon: Icons.trending_up_outlined,
                            valueColor: stats.sortinoRatio > 1
                                ? AppColors.profit
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MetricCard(
                            label: 'CALMAR RATIO',
                            value: stats.calmarRatio.toStringAsFixed(2),
                            subtitle: 'Return vs Max DD',
                            icon: Icons.scale_outlined,
                            valueColor: stats.calmarRatio > 2
                                ? AppColors.profit
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MetricCard(
                            label: 'MAX STREAK',
                            value:
                                '${stats.maxConsecWins}W / ${stats.maxConsecLosses}L',
                            subtitle: 'Consecutive wins/losses',
                            icon: Icons.timeline_rounded,
                            valueColor: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MetricCard(
                            label: 'AVG HOLD TIME',
                            value: _formatHoldTime(stats.avgHoldingMinutes),
                            subtitle: 'Per trade',
                            icon: Icons.timer_outlined,
                            valueColor: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  // Row 3: Radar Profile + Trading Calendar
                  if (isMobile) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Performance Profile',
                            subtitle: '5-Dimensional Analysis',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 220,
                            child: PerformanceRadarChart(stats: stats),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Trading Calendar',
                            subtitle: 'Daily P&L Heatmap',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TradeCalendar(dailyPnl: stats.dailyPnl),
                        ],
                      ),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(
                                  title: 'Performance Profile',
                                  subtitle: '5-Dimensional Analysis',
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 250,
                                  child: PerformanceRadarChart(stats: stats),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 3,
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(
                                  title: 'Trading Calendar',
                                  subtitle: 'Daily Profit & Loss Heatmap',
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TradeCalendar(dailyPnl: stats.dailyPnl),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  // Highs & Lows Row
                  ref.watch(bestWorstTradesProvider).when(
                        data: (data) => Row(
                          children: [
                            if (data.best != null)
                              TradeHighlightCard(
                                  trade: data.best!,
                                  title: 'BEST TRADE',
                                  isBest: true),
                            if (data.best != null && data.worst != null)
                              const SizedBox(width: AppSpacing.md),
                            if (data.worst != null)
                              TradeHighlightCard(
                                  trade: data.worst!,
                                  title: 'WORST TRADE',
                                  isBest: false),
                          ],
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                  const SizedBox(height: AppSpacing.xl),
                  // Row 4: Equity Curve + Drawdown
                  if (isMobile) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Equity Curve',
                            subtitle: '${stats.totalTrades} trades',
                            action: _pillBadge(
                              Fmt.currency(stats.totalNetPnl),
                              stats.totalNetPnl >= 0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 200,
                            child: EquityCurveChart(
                              points: stats.equityCurve,
                              startBalance: startBalance,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Drawdown',
                            action: _pillBadge(
                              '${stats.maxDrawdownPct.toStringAsFixed(1)}%',
                              false,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 180,
                            child: DrawdownChart(
                              points: stats.drawdownCurve,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Equity Curve',
                                  subtitle: '${stats.totalTrades} trades',
                                  action: _pillBadge(
                                    Fmt.currency(stats.totalNetPnl),
                                    stats.totalNetPnl >= 0,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 200,
                                  child: EquityCurveChart(
                                    points: stats.equityCurve,
                                    startBalance: startBalance,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Drawdown',
                                  action: _pillBadge(
                                    '${stats.maxDrawdownPct.toStringAsFixed(1)}%',
                                    false,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 200,
                                  child: DrawdownChart(
                                    points: stats.drawdownCurve,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.md),
                  // Row 5: Discipline progress + Trade Summary
                  if (isMobile) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Discipline'),
                          const SizedBox(height: AppSpacing.md),
                          _disciplineRow(context, 'Rules Followed',
                              stats.rulesFollowedPct, AppColors.profit),
                          const SizedBox(height: AppSpacing.sm),
                          _disciplineRow(context, 'Impulse Trades',
                              stats.impulseTradesPct, AppColors.loss),
                          const SizedBox(height: AppSpacing.sm),
                          _disciplineRow(context, 'Consistency Score',
                              stats.consistencyScore, AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Trade Summary'),
                          const SizedBox(height: AppSpacing.md),
                          _summaryRow(context, 'Largest Win',
                              Fmt.currency(stats.largestWin), AppColors.profit),
                          _summaryRow(context, 'Largest Loss',
                              Fmt.currency(stats.largestLoss), AppColors.loss),
                          _summaryRow(context, 'Avg Win',
                              Fmt.currency(stats.avgWinPnl), AppColors.profit),
                          _summaryRow(context, 'Avg Loss',
                              Fmt.currency(stats.avgLossPnl), AppColors.loss),
                          _summaryRow(
                              context,
                              'Total Trades',
                              stats.totalTrades.toString(),
                              AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(title: 'Discipline'),
                                const SizedBox(height: AppSpacing.md),
                                _disciplineRow(
                                  context,
                                  'Rules Followed',
                                  stats.rulesFollowedPct,
                                  AppColors.profit,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _disciplineRow(
                                  context,
                                  'Impulse Trades',
                                  stats.impulseTradesPct,
                                  AppColors.loss,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _disciplineRow(
                                  context,
                                  'Consistency Score',
                                  stats.consistencyScore,
                                  AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(title: 'Trade Summary'),
                                const SizedBox(height: AppSpacing.md),
                                _summaryRow(
                                  context,
                                  'Largest Win',
                                  Fmt.currency(stats.largestWin),
                                  AppColors.profit,
                                ),
                                _summaryRow(
                                  context,
                                  'Largest Loss',
                                  Fmt.currency(stats.largestLoss),
                                  AppColors.loss,
                                ),
                                _summaryRow(
                                  context,
                                  'Avg Win',
                                  Fmt.currency(stats.avgWinPnl),
                                  AppColors.profit,
                                ),
                                _summaryRow(
                                  context,
                                  'Avg Loss',
                                  Fmt.currency(stats.avgLossPnl),
                                  AppColors.loss,
                                ),
                                _summaryRow(
                                  context,
                                  'Total Trades',
                                  stats.totalTrades.toString(),
                                  AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricsShimmer(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 5,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: List.generate(
        isMobile ? 4 : 5,
        (_) => const LoadingShimmer(width: double.infinity, height: 120),
      ),
    );
  }

  /// Mobile layout helpers
  List<Widget> _buildMobileMetrics(dynamic stats) {
    final metricCards = [
      MetricCard(
        label: 'WIN RATE',
        value: Fmt.percent(stats.winRate * 100),
        subtitle: '${stats.wins}W / ${stats.losses}L',
        icon: Icons.percent_rounded,
        valueColor: stats.winRate >= 0.5 ? AppColors.profit : AppColors.loss,
        iconColor: AppColors.profit,
      ),
      MetricCard(
        label: 'AVG R',
        value: Fmt.rMultiple(
            stats.totalTrades > 0 ? stats.totalR / stats.totalTrades : 0),
        subtitle: 'Per trade',
        icon: Icons.show_chart_rounded,
        valueColor: AppColors.primary,
        iconColor: AppColors.primary,
      ),
      MetricCard(
        label: 'EXPECTANCY',
        value: Fmt.rMultiple(stats.expectancy),
        subtitle: 'Per trade',
        icon: Icons.insights_rounded,
        valueColor: stats.expectancy >= 0 ? AppColors.profit : AppColors.loss,
        iconColor: AppColors.primaryLight,
      ),
      MetricCard(
        label: 'PROFIT FACTOR',
        value: stats.profitFactor == double.infinity
            ? '∞'
            : stats.profitFactor.toStringAsFixed(2),
        subtitle: 'Win/loss ratio',
        icon: Icons.balance_rounded,
        valueColor:
            stats.profitFactor >= 1.5 ? AppColors.profit : AppColors.warning,
        iconColor: AppColors.warning,
      ),
      MetricCard(
        label: 'MAX DD',
        value: Fmt.percent(stats.maxDrawdownPct.abs()),
        subtitle: Fmt.currency(stats.maxDrawdown.abs()),
        icon: Icons.trending_down_rounded,
        valueColor: AppColors.loss,
        iconColor: AppColors.loss,
      ),
      _DisciplineRingCard(score: stats.disciplineScore),
    ];
    return [
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.3,
        children: metricCards,
      ),
    ];
  }

  List<Widget> _buildDesktopMetrics(dynamic stats) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: GridView.count(
              crossAxisCount: 5,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              children: [
                MetricCard(
                  label: 'WIN RATE',
                  value: Fmt.percent(stats.winRate * 100),
                  subtitle: '${stats.wins}W / ${stats.losses}L',
                  icon: Icons.percent_rounded,
                  valueColor:
                      stats.winRate >= 0.5 ? AppColors.profit : AppColors.loss,
                  iconColor: AppColors.profit,
                ),
                MetricCard(
                  label: 'AVG R-MULTIPLE',
                  value: Fmt.rMultiple(stats.totalTrades > 0
                      ? stats.totalR / stats.totalTrades
                      : 0),
                  subtitle: 'Per trade',
                  icon: Icons.show_chart_rounded,
                  valueColor: AppColors.primary,
                  iconColor: AppColors.primary,
                ),
                MetricCard(
                  label: 'EXPECTANCY',
                  value: Fmt.rMultiple(stats.expectancy),
                  subtitle: 'Per trade expected',
                  icon: Icons.insights_rounded,
                  valueColor:
                      stats.expectancy >= 0 ? AppColors.profit : AppColors.loss,
                  iconColor: AppColors.primaryLight,
                ),
                MetricCard(
                  label: 'PROFIT FACTOR',
                  value: stats.profitFactor == double.infinity
                      ? '∞'
                      : stats.profitFactor.toStringAsFixed(2),
                  subtitle: 'Gross win/loss ratio',
                  icon: Icons.balance_rounded,
                  valueColor: stats.profitFactor >= 1.5
                      ? AppColors.profit
                      : AppColors.warning,
                  iconColor: AppColors.warning,
                ),
                MetricCard(
                  label: 'MAX DRAWDOWN',
                  value: Fmt.percent(stats.maxDrawdownPct.abs()),
                  subtitle: Fmt.currency(stats.maxDrawdown.abs()),
                  icon: Icons.trending_down_rounded,
                  valueColor: AppColors.loss,
                  iconColor: AppColors.loss,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _DisciplineRingCard(score: stats.disciplineScore),
        ],
      ),
    ];
  }

  Widget _buildMobileProfMetrics(dynamic stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          label: 'SHARPE',
          value: stats.sharpeRatio.toStringAsFixed(2),
          subtitle: 'Risk-adjusted',
          icon: Icons.analytics_outlined,
          valueColor:
              stats.sharpeRatio > 1 ? AppColors.profit : AppColors.textPrimary,
        ),
        MetricCard(
          label: 'SORTINO',
          value: stats.sortinoRatio.toStringAsFixed(2),
          subtitle: 'Downside risk',
          icon: Icons.trending_up_outlined,
          valueColor:
              stats.sortinoRatio > 1 ? AppColors.profit : AppColors.textPrimary,
        ),
        MetricCard(
          label: 'CALMAR',
          value: stats.calmarRatio.toStringAsFixed(2),
          subtitle: 'Return vs DD',
          icon: Icons.scale_outlined,
          valueColor:
              stats.calmarRatio > 2 ? AppColors.profit : AppColors.textPrimary,
        ),
        MetricCard(
          label: 'AVG HOLD',
          value: _formatHoldTime(stats.avgHoldingMinutes),
          subtitle: 'Per trade',
          icon: Icons.timer_outlined,
          valueColor: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _alertBanner(BuildContext context, WidgetRef ref, String msg) {
    final isReviewAlert = msg.contains('review');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningDim,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (isReviewAlert)
            TextButton.icon(
              onPressed: () => context.go('/daily-review'),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Complete Now', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lossDim,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.loss),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.loss, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(msg, style: const TextStyle(color: AppColors.loss))),
          ],
        ),
      );

  Widget _pillBadge(String text, bool positive) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: positive ? AppColors.profitDim : AppColors.lossDim,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: positive ? AppColors.profit : AppColors.loss,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _disciplineRow(
    BuildContext ctx,
    String label,
    double pct,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
            Text(
              Fmt.percent(pct * 100),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext ctx, String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHoldTime(double minutes) {
    if (minutes < 60) return '${minutes.round()}m';
    if (minutes < 1440) return '${(minutes / 60).toStringAsFixed(1)}h';
    return '${(minutes / 1440).toStringAsFixed(1)}d';
  }
}

// ── Discipline Score Ring ─────────────────────────────────────────────────────

class _DisciplineRingCard extends StatelessWidget {
  final double score;
  const _DisciplineRingCard({required this.score});

  Color get _ringColor {
    if (score >= 80) return AppColors.profit;
    if (score >= 50) return AppColors.warning;
    return AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    final pct = score / 100;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DISCIPLINE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.round().toString(),
                      style: TextStyle(
                        color: _ringColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            score >= 80
                ? '🟢 Excellent'
                : score >= 60
                    ? '🟡 Average'
                    : '🔴 Needs Work',
            style: TextStyle(
              color: _ringColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremarketChecklistCard extends StatefulWidget {
  final PremarketChecklistState state;
  const _PremarketChecklistCard({required this.state});

  @override
  State<_PremarketChecklistCard> createState() =>
      _PremarketChecklistCardState();
}

class _PremarketChecklistCardState extends State<_PremarketChecklistCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pct =
        state.totalCount > 0 ? state.completedCount / state.totalCount : 0.0;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRE-MARKET READINESS',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              state.allDone
                                  ? AppColors.profit
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (state.allDone ? AppColors.profit : AppColors.primary)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.allDone
                          ? 'READY'
                          : '${state.completedCount}/${state.totalCount}',
                      style: TextStyle(
                        color: state.allDone
                            ? AppColors.profit
                            : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Consumer(builder: (context, ref, _) {
              return Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md),
                child: Column(
                  children: state.items.map((item) {
                    final isChecked = state.checks[item] ?? false;
                    return InkWell(
                      onTap: () => ref
                          .read(premarketChecklistProvider.notifier)
                          .toggle(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              isChecked
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isChecked
                                  ? AppColors.profit
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: isChecked
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }
}

Widget _streakBanner(PortfolioStats stats) {
  if (stats.currentWinStreak < 2 && stats.currentLossStreak < 2) {
    return const SizedBox.shrink();
  }

  final isWin = stats.currentWinStreak >= 2;
  final count = isWin ? stats.currentWinStreak : stats.currentLossStreak;
  final color = isWin ? AppColors.profit : AppColors.loss;
  final icon =
      isWin ? Icons.local_fire_department_rounded : Icons.warning_amber_rounded;
  final message = isWin
      ? '🔥 $count-trade winning streak! Stay disciplined and stick to the plan.'
      : '⚠️ $count-trade losing streak. Take a breath, review your rules, and don\'t revenge trade.';

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
