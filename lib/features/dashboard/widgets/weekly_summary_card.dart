import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../accounts/providers/account_provider.dart';
import '../providers/dashboard_provider.dart';

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Performance Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 4),
                    Text('Review your week and share your progress',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              // Compact icon button on narrow screens
              if (isNarrow)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: AppColors.primary, size: 20),
                  tooltip: 'View Report',
                  onPressed: () => _showSummaryModal(context, ref),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _showSummaryModal(context, ref),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View Report'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSummaryModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _WeeklySummaryModal(),
        ),
      ),
    );
  }
}

class _WeeklySummaryModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final account = ref.watch(selectedAccountProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekLabel = '${Fmt.date(weekStart)} – ${Fmt.date(now)}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.4)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly Performance Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17)),
                    Text(weekLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (stats) {
                    final totalR = stats.totalR;
                    final isPositiveWeek = totalR >= 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (account != null)
                          Text(account.name,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        // Big stat
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '${isPositiveWeek ? '+' : ''}${totalR.toStringAsFixed(2)}R',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: isPositiveWeek
                                      ? AppColors.profit
                                      : AppColors.loss,
                                ),
                              ),
                              Text('Total R-Multiple this week',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: AppSpacing.md),
                        // Grid metrics
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 2.2,
                          children: [
                            _statTile('Trades', '${stats.totalTrades}'),
                            _statTile(
                                'Win Rate', Fmt.percent(stats.winRate * 100)),
                            _statTile(
                                'Net P&L', Fmt.currency(stats.totalNetPnl),
                                color: isPositiveWeek
                                    ? AppColors.profit
                                    : AppColors.loss),
                            _statTile(
                                'Profit Factor',
                                stats.profitFactor == double.infinity
                                    ? '∞'
                                    : stats.profitFactor.toStringAsFixed(2)),
                            _statTile(
                                'Best Day', Fmt.currency(stats.largestWin),
                                color: AppColors.profit),
                            _statTile(
                                'Worst Day', Fmt.currency(stats.largestLoss),
                                color: AppColors.loss),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Motivational footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isPositiveWeek
                                ? AppColors.profitDim
                                : AppColors.warningDim,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Text(isPositiveWeek ? '🚀' : '💡',
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isPositiveWeek
                                      ? 'Great week! Stay disciplined and keep executing your plan.'
                                      : 'Tough week. Review your trades, identify patterns, and come back stronger.',
                                  style: TextStyle(
                                    color: isPositiveWeek
                                        ? AppColors.profit
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppColors.textPrimary)),
          ],
        ),
      );
}
