import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/trade_analytics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/account.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/account_provider.dart';

class AccountComparisonScreen extends ConsumerStatefulWidget {
  const AccountComparisonScreen({super.key});

  @override
  ConsumerState<AccountComparisonScreen> createState() =>
      _AccountComparisonScreenState();
}

class _AccountComparisonScreenState
    extends ConsumerState<AccountComparisonScreen> {
  Set<String> _selectedIds = {};
  Map<String, PortfolioStats> _statsCache = {};
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Compare Accounts'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'Select 2 or more accounts to compare their performance side by side.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Select Accounts:',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                accountsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (accounts) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((a) {
                      final selected = _selectedIds.contains(a.id);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _colorForAccount(accounts.indexOf(a)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(a.name),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedIds.remove(a.id);
                            _statsCache.remove(a.id);
                          } else {
                            _selectedIds.add(a.id);
                          }
                        }),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),
                if (_selectedIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadComparison(
                              ref.read(accountListProvider).value ?? []),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Compare ${_selectedIds.length} Accounts'),
                    ),
                  ),
                ],
                if (_statsCache.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Performance Comparison',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  _buildComparisonTable(
                      ref.read(accountListProvider).value ?? []),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadComparison(List<Account> allAccounts) async {
    setState(() => _loading = true);
    final tradeRepo = ref.read(tradeRepositoryProvider);
    final selectedAccounts =
        allAccounts.where((a) => _selectedIds.contains(a.id)).toList();
    final newCache = <String, PortfolioStats>{};
    for (final account in selectedAccounts) {
      final trades = (await tradeRepo.fetchAll())
          .where((t) => t.accountId == account.id)
          .toList();
      newCache[account.id] =
          TradeAnalytics.compute(trades, account.initialBalance);
    }
    if (mounted)
      setState(() {
        _statsCache = newCache;
        _loading = false;
      });
  }

  Widget _buildComparisonTable(List<Account> allAccounts) {
    final selected =
        allAccounts.where((a) => _statsCache.containsKey(a.id)).toList();
    final cols = <_MetricRow>[
      _MetricRow('Total R', (s) => Fmt.rMultiple(s.totalR),
          higherIsBetter: true),
      _MetricRow('Win Rate', (s) => Fmt.percent(s.winRate * 100),
          higherIsBetter: true),
      _MetricRow('Expectancy', (s) => Fmt.rMultiple(s.expectancy),
          higherIsBetter: true),
      _MetricRow(
          'Profit Factor',
          (s) => s.profitFactor == double.infinity
              ? '∞'
              : s.profitFactor.toStringAsFixed(2),
          higherIsBetter: true),
      _MetricRow('Sharpe Ratio', (s) => s.sharpeRatio.toStringAsFixed(2),
          higherIsBetter: true),
      _MetricRow('Max Drawdown', (s) => Fmt.percent(s.maxDrawdownPct.abs()),
          higherIsBetter: false),
      _MetricRow('Total Trades', (s) => s.totalTrades.toString(),
          higherIsBetter: true),
      _MetricRow('Avg Hold Time', (s) => _fmt(s.avgHoldingMinutes),
          higherIsBetter: false),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd)),
            ),
            child: Row(children: [
              const SizedBox(
                  width: 140,
                  child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Metric',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 1.0)))),
              ...selected.asMap().entries.map((e) => Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _colorForAccount(e.key))),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(e.value.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  ))),
            ]),
          ),
          ...cols.asMap().entries.map((entry) {
            final isEven = entry.key.isEven;
            final row = entry.value;
            final values = selected
                .map((a) => _statsCache[a.id]!)
                .map(row.getValue)
                .toList();
            return Container(
              decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : AppColors.surfaceElevated.withValues(alpha: 0.3)),
              child: Row(children: [
                SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Text(row.label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    )),
                ...selected.asMap().entries.map((e) {
                  final val = values[e.key];
                  final isBest = _isBest(values, e.key, row.higherIsBetter);
                  return Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      if (isBest)
                        const Icon(Icons.star_rounded,
                            color: AppColors.profit, size: 14),
                      if (isBest) const SizedBox(width: 4),
                      Text(val,
                          style: TextStyle(
                            fontWeight:
                                isBest ? FontWeight.w800 : FontWeight.w500,
                            color: isBest
                                ? AppColors.profit
                                : AppColors.textPrimary,
                            fontSize: 13,
                          )),
                    ]),
                  ));
                }),
              ]),
            );
          }),
        ],
      ),
    );
  }

  bool _isBest(List<String> vals, int idx, bool higherIsBetter) {
    try {
      final nums = vals
          .map((v) =>
              double.tryParse(v
                  .replaceAll('%', '')
                  .replaceAll('R', '')
                  .replaceAll(',', '')
                  .trim()) ??
              0.0)
          .toList();
      final best = higherIsBetter
          ? nums.reduce((a, b) => a > b ? a : b)
          : nums.reduce((a, b) => a < b ? a : b);
      return nums[idx] == best;
    } catch (_) {
      return false;
    }
  }

  Color _colorForAccount(int index) {
    const colors = [
      AppColors.primary,
      AppColors.profit,
      AppColors.warning,
      Color(0xFFAB47BC),
      Color(0xFF26C6DA)
    ];
    return colors[index % colors.length];
  }

  String _fmt(double minutes) {
    if (minutes < 60) return '${minutes.round()}m';
    if (minutes < 1440) return '${(minutes / 60).toStringAsFixed(1)}h';
    return '${(minutes / 1440).toStringAsFixed(1)}d';
  }
}

class _MetricRow {
  final String label;
  final String Function(PortfolioStats) getValue;
  final bool higherIsBetter;
  const _MetricRow(this.label, this.getValue, {required this.higherIsBetter});
}
