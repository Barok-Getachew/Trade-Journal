import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../auth/providers/repository_providers.dart';

final _weeklyListProvider = FutureProvider((ref) async {
  return ref.read(reviewRepositoryProvider).fetchWeeklyAll();
});

class WeeklyReviewListScreen extends ConsumerWidget {
  const WeeklyReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_weeklyListProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Reviews',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Review'),
                onPressed: () => context.push('/weekly-review/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (reviews) => reviews.isEmpty
                  ? const EmptyState(
                      title: 'No weekly reviews yet',
                      message: 'Create your first weekly review',
                      icon: Icons.calendar_view_week_outlined,
                    )
                  : ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) {
                        final r = reviews[i];
                        return GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            onTap: () => context.push('/weekly-review/${r.id}'),
                            child: Row(
                              children: [
                                // Week label
                                SizedBox(
                                  width: 150,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Week of ${Fmt.date(r.weekStart)}',
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.titleSmall,
                                      ),
                                      Text(
                                        '${r.totalTrades} trades',
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                _statChip(
                                  ctx,
                                  'Win Rate',
                                  Fmt.percent(r.winRate * 100),
                                  r.winRate >= 0.5
                                      ? AppColors.profit
                                      : AppColors.loss,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _statChip(
                                  ctx,
                                  'Total R',
                                  Fmt.rMultiple(r.totalR),
                                  r.totalR >= 0
                                      ? AppColors.profit
                                      : AppColors.loss,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _statChip(
                                  ctx,
                                  'Rules',
                                  Fmt.percent(r.rulesFollowedPct * 100),
                                  r.rulesFollowedPct >= 0.8
                                      ? AppColors.profit
                                      : AppColors.warning,
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ],
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

  Widget _statChip(BuildContext ctx, String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(ctx).textTheme.bodySmall),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ── Weekly Review Detail ───────────────────────────────────────────────────────

final _weeklyDetailProvider =
    FutureProvider.family<dynamic, String>((ref, id) async {
  final list = await ref.read(reviewRepositoryProvider).fetchWeeklyAll();
  try {
    return list.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
});

class WeeklyReviewDetailScreen extends ConsumerStatefulWidget {
  final String reviewId;
  const WeeklyReviewDetailScreen({super.key, required this.reviewId});

  @override
  ConsumerState<WeeklyReviewDetailScreen> createState() =>
      _WeeklyReviewDetailScreenState();
}

class _WeeklyReviewDetailScreenState
    extends ConsumerState<WeeklyReviewDetailScreen> {
  final _reflCtrl = TextEditingController();
  final _goalsCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(_weeklyDetailProvider(widget.reviewId));

    return reviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (review) {
        if (review == null) {
          return const EmptyState(title: 'Review not found');
        }
        if (_reflCtrl.text.isEmpty && review.reflection != null) {
          _reflCtrl.text = review.reflection!;
        }
        if (_goalsCtrl.text.isEmpty && review.goalsNextWeek != null) {
          _goalsCtrl.text = review.goalsNextWeek!;
        }

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week of ${Fmt.date(review.weekStart)}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Stats row
                Row(
                  children: [
                    _statCard(
                      context,
                      'Total Trades',
                      review.totalTrades.toString(),
                      AppColors.primary,
                      Icons.receipt_long_outlined,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _statCard(
                      context,
                      'Win Rate',
                      Fmt.percent(review.winRate * 100),
                      review.winRate >= 0.5 ? AppColors.profit : AppColors.loss,
                      Icons.percent_rounded,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _statCard(
                      context,
                      'Total R',
                      Fmt.rMultiple(review.totalR),
                      review.totalR >= 0 ? AppColors.profit : AppColors.loss,
                      Icons.show_chart_rounded,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _statCard(
                      context,
                      'Rules Followed',
                      Fmt.percent(review.rulesFollowedPct * 100),
                      review.rulesFollowedPct >= 0.8
                          ? AppColors.profit
                          : AppColors.warning,
                      Icons.gavel_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Reflection form
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reflection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _reflCtrl,
                        maxLines: 5,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText:
                              'What went well? What would you do differently?',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Goals for Next Week',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _goalsCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Set 1-3 concrete goals for next week',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                await ref
                                    .read(reviewRepositoryProvider)
                                    .upsertWeekly({
                                  'id': review.id,
                                  'reflection': _reflCtrl.text,
                                  'goals_next_week': _goalsCtrl.text,
                                });
                                if (mounted) setState(() => _saving = false);
                              },
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Reflection'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
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
                fontSize: 20,
              ),
            ),
            Text(label, style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
