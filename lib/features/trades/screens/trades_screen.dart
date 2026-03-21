import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/direction.dart';
import '../../../domain/models/trade.dart';
import '../../../shared/widgets/tables/trade_data_table.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../providers/trades_provider.dart';
import '../../auth/providers/repository_providers.dart';

class TradesScreen extends ConsumerWidget {
  const TradesScreen({super.key});

  static const _kMobileBreak = 700.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(filteredTradesProvider);
    final filter = ref.watch(tradeFilterProvider);
    final isMobile = MediaQuery.of(context).size.width < _kMobileBreak;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Row
          Row(
            children: [
              // Filter chips
              if (!filter.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters active',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            ref.read(tradeFilterProvider.notifier).reset(),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Date filter
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 14),
                label: Text(
                  filter.from != null
                      ? '${Fmt.date(filter.from)} – ${Fmt.date(filter.to)}'
                      : 'Date Range',
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) =>
                        Theme(data: Theme.of(ctx), child: child!),
                  );
                  if (range != null) {
                    ref
                        .read(tradeFilterProvider.notifier)
                        .setDateRange(range.start, range.end);
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Trade'),
                onPressed: () => context.push('/trades/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats bar
          tradesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (trades) {
              final wins = trades.where((t) => t.isWin).length;
              final totalR = trades.fold<double>(0, (s, t) => s + t.rMultiple);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _stat(context, trades.length.toString(), 'Trades'),
                    _divider(),
                    _stat(
                      context,
                      wins.toString(),
                      'Wins',
                      color: AppColors.profit,
                    ),
                    _divider(),
                    _stat(
                      context,
                      (trades.isEmpty ? 0 : (wins / trades.length * 100))
                          .toStringAsFixed(1),
                      'Win %',
                      suffix: '%',
                      color: wins / (trades.isEmpty ? 1 : trades.length) >= 0.5
                          ? AppColors.profit
                          : AppColors.loss,
                    ),
                    _divider(),
                    _stat(
                      context,
                      Fmt.rMultiple(totalR),
                      'Total R',
                      color: totalR >= 0 ? AppColors.profit : AppColors.loss,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Table / Card list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isMobile ? Colors.transparent : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: isMobile ? null : Border.all(color: AppColors.border),
              ),
              child: tradesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.loss),
                  ),
                ),
                data: (trades) {
                  if (trades.isEmpty) {
                    return const EmptyState(
                      title: 'No trades found',
                      message: 'Log your first trade to get started',
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  if (isMobile) {
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: trades.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _MobileTradeCard(
                        trade: trades[i],
                        onTap: () => context.push('/trades/${trades[i].id}'),
                        onDelete: () async {
                          final confirm = await _confirmDelete(context);
                          if (confirm != true) return;
                          try {
                            await ref
                                .read(tradeRepositoryProvider)
                                .delete(trades[i].id);
                            ref.invalidate(filteredTradesProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trade deleted'),
                                  backgroundColor: AppColors.profit,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.loss,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: SingleChildScrollView(
                      child: TradeDataTable(
                        trades: trades,
                        onTap: (t) => context.push('/trades/${t.id}'),
                        onDelete: (t) async {
                          final confirm = await _confirmDelete(context);
                          if (confirm != true) return;
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deleting trade...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          try {
                            await ref
                                .read(tradeRepositoryProvider)
                                .delete(t.id);
                            ref.invalidate(filteredTradesProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trade deleted successfully'),
                                  backgroundColor: AppColors.profit,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting trade: $e'),
                                  backgroundColor: AppColors.loss,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext ctx,
    String val,
    String label, {
    Color? color,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$val$suffix',
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(label, style: Theme.of(ctx).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );

  Future<bool?> _confirmDelete(BuildContext ctx) => showDialog<bool>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Trade'),
          content: const Text(
            'Are you sure you want to delete this trade? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.loss,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
}

// ── Mobile Trade Card ─────────────────────────────────────────────────────────

class _MobileTradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MobileTradeCard({
    required this.trade,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.netPnl >= 0;
    final isLong = trade.direction == TradeDirection.long;
    final pnlColor = isProfit ? AppColors.profit : AppColors.loss;
    final directionColor = isLong ? AppColors.profit : AppColors.loss;

    return Dismissible(
      key: Key(trade.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.loss.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.loss.withOpacity(0.5)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.loss, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.loss,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // let the callback handle deletion to keep state clean
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // ── Top row: symbol + direction + date ────────────────────────
              Row(
                children: [
                  // Symbol badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trade.symbol,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Direction badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: directionColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: directionColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      isLong ? '▲ LONG' : '▼ SHORT',
                      style: TextStyle(
                        color: directionColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Date
                  Text(
                    Fmt.date(trade.entryAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              // ── Bottom row: P&L + R-Multiple + Outcome ────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET P&L',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Fmt.currency(trade.netPnl),
                          style: TextStyle(
                            color: pnlColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trade.rMultiple != 0) ...[
                    Container(width: 1, height: 32, color: AppColors.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'R-MULTIPLE',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Fmt.rMultiple(trade.rMultiple),
                              style: TextStyle(
                                color: trade.rMultiple >= 0
                                    ? AppColors.profit
                                    : AppColors.loss,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Win/Loss badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isProfit ? AppColors.profitDim : AppColors.lossDim,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      isProfit ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
