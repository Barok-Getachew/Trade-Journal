import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/charts/chart_widgets.dart';
import '../../../shared/widgets/charts/trade_calendar_widget.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../providers/analytics_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../insights/providers/insights_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stratAsync = ref.watch(strategySegmentProvider);
    final symAsync = ref.watch(symbolSegmentProvider);
    final sessAsync = ref.watch(sessionSegmentProvider);
    final emotAsync = ref.watch(emotionSegmentProvider);
    final dowAsync = ref.watch(dayOfWeekSegmentProvider);
    final discAsync = ref.watch(disciplineComparisonProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final checkAsync = ref.watch(checklistComparisonProvider);
    final histAsync = ref.watch(rMultipleHistogramProvider);
    final calPnlAsync = ref.watch(analyticsDailyPnlProvider);
    final calCountAsync = ref.watch(analyticsTradeCountProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mental State ↔ Performance (P2) ──────────────────────────
            const _MentalStateSection(),
            const SizedBox(height: AppSpacing.md),
            // ── Professional Metrics ──────────────────────────────────────
            statsAsync.when(
              loading: () =>
                  const LoadingShimmer(width: double.infinity, height: 100),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _ProfessionalMetricsRow(stats: stats),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Payoff Distribution ───────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Payoff Distribution',
                    subtitle:
                        'How your trades distribute across R-multiple buckets',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  histAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 200,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (buckets) => RMultipleHistogram(buckets: buckets),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Discipline Comparison',
                    subtitle: 'Rules-followed vs broken trades',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  discAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 80,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (disc) {
                      final f = disc['followed']!;
                      final b = disc['broken']!;
                      if (isMobile) {
                        return Column(
                          children: [
                            Row(children: [
                              _discCard(
                                  context,
                                  'Rules Followed',
                                  f.totalTrades,
                                  f.winRate,
                                  f.expectancy,
                                  AppColors.profit),
                            ]),
                            const SizedBox(height: AppSpacing.sm),
                            Row(children: [
                              _discCard(context, 'Rules Broken', b.totalTrades,
                                  b.winRate, b.expectancy, AppColors.loss),
                            ]),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          _discCard(context, 'Rules Followed', f.totalTrades,
                              f.winRate, f.expectancy, AppColors.profit),
                          const SizedBox(width: AppSpacing.md),
                          _discCard(context, 'Rules Broken', b.totalTrades,
                              b.winRate, b.expectancy, AppColors.loss),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Checklist Compliance Comparison ───────────────────────────
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Checklist Compliance',
                    subtitle: 'Trades passing all 5 checks vs missing some',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  checkAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 80,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (check) {
                      final p = check['passed_all']!;
                      final s = check['skipped_some']!;
                      if (isMobile) {
                        return Column(
                          children: [
                            Row(children: [
                              _discCard(
                                  context,
                                  'Passed All Checks',
                                  p.totalTrades,
                                  p.winRate,
                                  p.expectancy,
                                  AppColors.profit),
                            ]),
                            const SizedBox(height: AppSpacing.sm),
                            Row(children: [
                              _discCard(
                                  context,
                                  'Skipped Checks',
                                  s.totalTrades,
                                  s.winRate,
                                  s.expectancy,
                                  AppColors.warning),
                            ]),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          _discCard(context, 'Passed All Checks', p.totalTrades,
                              p.winRate, p.expectancy, AppColors.profit),
                          const SizedBox(width: AppSpacing.md),
                          _discCard(context, 'Skipped Checks', s.totalTrades,
                              s.winRate, s.expectancy, AppColors.warning),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Strategy & Symbol breakdown ──────────────────────────────
            if (isMobile) ...[
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'By Strategy'),
                    const SizedBox(height: AppSpacing.md),
                    stratAsync.when(
                      loading: () => const LoadingShimmer(
                          width: double.infinity, height: 120),
                      error: (e, _) => Text(e.toString()),
                      data: (segs) => segs.isEmpty
                          ? const EmptyState(
                              title: 'No data', icon: Icons.bar_chart_outlined)
                          : SegmentBarChart(
                              data: segs
                                  .map((s) => MapEntry(s.label, s.totalR))
                                  .toList()),
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
                    const SectionHeader(title: 'By Symbol'),
                    const SizedBox(height: AppSpacing.md),
                    symAsync.when(
                      loading: () => const LoadingShimmer(
                          width: double.infinity, height: 120),
                      error: (e, _) => Text(e.toString()),
                      data: (segs) => segs.isEmpty
                          ? const EmptyState(
                              title: 'No data', icon: Icons.bar_chart_outlined)
                          : SegmentBarChart(
                              data: segs
                                  .map((s) => MapEntry(s.label, s.totalR))
                                  .toList()),
                    ),
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
                          const SectionHeader(title: 'By Strategy'),
                          const SizedBox(height: AppSpacing.md),
                          stratAsync.when(
                            loading: () => const LoadingShimmer(
                                width: double.infinity, height: 120),
                            error: (e, _) => Text(e.toString()),
                            data: (segs) => segs.isEmpty
                                ? const EmptyState(
                                    title: 'No data',
                                    icon: Icons.bar_chart_outlined)
                                : SegmentBarChart(
                                    data: segs
                                        .map((s) => MapEntry(s.label, s.totalR))
                                        .toList()),
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
                          const SectionHeader(title: 'By Symbol'),
                          const SizedBox(height: AppSpacing.md),
                          symAsync.when(
                            loading: () => const LoadingShimmer(
                                width: double.infinity, height: 120),
                            error: (e, _) => Text(e.toString()),
                            data: (segs) => segs.isEmpty
                                ? const EmptyState(
                                    title: 'No data',
                                    icon: Icons.bar_chart_outlined)
                                : SegmentBarChart(
                                    data: segs
                                        .map((s) => MapEntry(s.label, s.totalR))
                                        .toList()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.md),
            // ── Session & Day of Week ─────────────────────────────────
            if (isMobile) ...[
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'By Session'),
                    const SizedBox(height: AppSpacing.md),
                    sessAsync.when(
                      loading: () => const LoadingShimmer(
                          width: double.infinity, height: 100),
                      error: (e, _) => Text(e.toString()),
                      data: (segs) => SegmentBarChart(
                          data: segs
                              .map((s) => MapEntry(s.label, s.totalR))
                              .toList()),
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
                    const SectionHeader(title: 'By Day of Week'),
                    const SizedBox(height: AppSpacing.md),
                    dowAsync.when(
                      loading: () => const LoadingShimmer(
                          width: double.infinity, height: 100),
                      error: (e, _) => Text(e.toString()),
                      data: (segs) => SegmentBarChart(
                          data: segs
                              .map((s) => MapEntry(s.label, s.totalR))
                              .toList()),
                    ),
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
                          const SectionHeader(title: 'By Session'),
                          const SizedBox(height: AppSpacing.md),
                          sessAsync.when(
                            loading: () => const LoadingShimmer(
                                width: double.infinity, height: 100),
                            error: (e, _) => Text(e.toString()),
                            data: (segs) => SegmentBarChart(
                                data: segs
                                    .map((s) => MapEntry(s.label, s.totalR))
                                    .toList()),
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
                          const SectionHeader(title: 'By Day of Week'),
                          const SizedBox(height: AppSpacing.md),
                          dowAsync.when(
                            loading: () => const LoadingShimmer(
                                width: double.infinity, height: 100),
                            error: (e, _) => Text(e.toString()),
                            data: (segs) => SegmentBarChart(
                                data: segs
                                    .map((s) => MapEntry(s.label, s.totalR))
                                    .toList()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.md),
            // ── Emotion Impact ─────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Emotional Impact on Performance',
                    subtitle: 'Total R grouped by emotion before trade',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  emotAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 100,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (segs) => SegmentBarChart(
                      data:
                          segs.map((s) => MapEntry(s.label, s.totalR)).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Monthly P&L Calendar ──────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Monthly P\u0026L Calendar',
                    subtitle: 'Daily profit & loss with trade count per day',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  calPnlAsync.when(
                    loading: () => const LoadingShimmer(
                      width: double.infinity,
                      height: 200,
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (pnl) => TradeCalendar(
                      dailyPnl: pnl,
                      tradeCounts: calCountAsync.value,
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

  Widget _discCard(
    BuildContext ctx,
    String title,
    int trades,
    double winRate,
    double expectancy,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  color == AppColors.profit
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('$trades trades', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Win Rate: ${Fmt.percent(winRate * 100)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Expectancy: ${Fmt.rMultiple(expectancy)}',
              style: TextStyle(
                color: expectancy >= 0 ? AppColors.profit : AppColors.loss,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mental State ↔ Performance Section (P2) ──────────────────────────────────

class _MentalStateSection extends ConsumerWidget {
  const _MentalStateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionAsync = ref.watch(emotionPerformanceProvider);

    return emotionAsync.when(
      loading: () =>
          const LoadingShimmer(width: double.infinity, height: 120),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Mental State vs Performance',
                subtitle:
                    'How your emotional state before a trade affects your edge',
              ),
              const SizedBox(height: AppSpacing.md),
              // Best/worst call-out
              Row(
                children: [
                  _emotionChip(stats.first, isBest: true),
                  const SizedBox(width: AppSpacing.sm),
                  if (stats.length > 1)
                    _emotionChip(stats.last, isBest: false),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Full table
              ...stats.map((s) {
                final maxAbsR = stats
                    .map((e) => e.avgR.abs())
                    .fold(0.0, (a, b) => a > b ? a : b);
                final barFrac =
                    maxAbsR > 0 ? (s.avgR / maxAbsR).clamp(-1.0, 1.0) : 0.0;
                final isPos = s.avgR >= 0;
                final color = isPos ? AppColors.profit : AppColors.loss;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 14,
                                color: AppColors.surfaceElevated,
                              ),
                              FractionallySizedBox(
                                widthFactor: barFrac.abs(),
                                alignment: isPos
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.7),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Avg R
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${isPos ? '+' : ''}${s.avgR.toStringAsFixed(2)}R',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Win rate
                      SizedBox(
                        width: 40,
                        child: Text(
                          Fmt.percent(s.winRate * 100),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Count
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${s.count}t',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _emotionChip(EmotionStat s, {required bool isBest}) {
    final color = isBest ? AppColors.profit : AppColors.loss;
    final bgColor = isBest ? AppColors.profitDim : AppColors.lossDim;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBest ? '🏆 Best State' : '⚠ Worst State',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              s.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              '${s.avgR >= 0 ? '+' : ''}${s.avgR.toStringAsFixed(2)}R avg · ${Fmt.percent(s.winRate * 100)} WR',
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Professional Metrics Row ───────────────────────────────────────────────────

class _ProfessionalMetricsRow extends StatelessWidget {
  final PortfolioStats stats;
  const _ProfessionalMetricsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Professional Risk Metrics',
            subtitle:
                'Advanced performance attribution for institutional-grade analysis',
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                      ? 3
                      : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.5,
                children: [
                  _metricTile(
                    'SHARPE RATIO',
                    stats.sharpeRatio.toStringAsFixed(2),
                    'Risk-adjusted return',
                    Icons.analytics_outlined,
                    _ratioColor(stats.sharpeRatio, good: 1.0),
                  ),
                  _metricTile(
                    'SORTINO RATIO',
                    stats.sortinoRatio.toStringAsFixed(2),
                    'Downside risk adjusted',
                    Icons.trending_up_outlined,
                    _ratioColor(stats.sortinoRatio, good: 1.0),
                  ),
                  _metricTile(
                    'CALMAR RATIO',
                    stats.calmarRatio.toStringAsFixed(2),
                    'Return vs max drawdown',
                    Icons.scale_outlined,
                    _ratioColor(stats.calmarRatio, good: 2.0),
                  ),
                  _metricTile(
                    'RISK OF RUIN',
                    '${stats.riskOfRuin.toStringAsFixed(1)}%',
                    'Probability of loss',
                    Icons.warning_amber_outlined,
                    stats.riskOfRuin < 5
                        ? AppColors.profit
                        : stats.riskOfRuin < 20
                            ? AppColors.warning
                            : AppColors.loss,
                  ),
                  _metricTile(
                    'MAX CONSEC WINS',
                    stats.maxConsecWins.toString(),
                    'Best run of winners',
                    Icons.local_fire_department_outlined,
                    AppColors.profit,
                  ),
                  _metricTile(
                    'MAX CONSEC LOSSES',
                    stats.maxConsecLosses.toString(),
                    'Worst losing run',
                    Icons.storm_outlined,
                    AppColors.loss,
                  ),
                  _metricTile(
                    'CHECKLIST SCORE',
                    '${stats.checklistScore.toStringAsFixed(1)}%',
                    'Process consistency',
                    Icons.fact_check_outlined,
                    stats.checklistScore > 80
                        ? AppColors.profit
                        : stats.checklistScore > 50
                            ? AppColors.warning
                            : AppColors.loss,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _ratioColor(double v, {required double good}) {
    if (v >= good) return AppColors.profit;
    if (v >= 0) return AppColors.warning;
    return AppColors.loss;
  }

  Widget _metricTile(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
