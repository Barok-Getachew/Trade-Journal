import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../auth/providers/repository_providers.dart';
import '../../narratives/providers/narrative_provider.dart';

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

  // Narrative reflection controllers
  final _reflScenarioCtrl = TextEditingController();
  final _reflDayCtrl = TextEditingController();
  final _reflCarryCtrl = TextEditingController();
  bool? _reflAmdCorrect;
  int _reflS5Count = 0;
  bool _narrativeLoaded = false;

  Future<void> _loadWeeklyNarrative(DateTime weekStart) async {
    try {
      final existing = await ref.read(narrativeRepositoryProvider).fetchWeeklyByDate(weekStart);
      if (existing != null && mounted) {
        setState(() {
          _reflScenarioCtrl.text = existing.reflScenarioPlayed ?? '';
          _reflDayCtrl.text = existing.reflCleanestDay ?? '';
          _reflCarryCtrl.text = existing.reflCarryForward ?? '';
          _reflAmdCorrect = existing.reflAmdCorrect;
          _reflS5Count = existing.reflCompleteS5Count ?? 0;
          _narrativeLoaded = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reflCtrl.dispose();
    _goalsCtrl.dispose();
    _reflScenarioCtrl.dispose();
    _reflDayCtrl.dispose();
    _reflCarryCtrl.dispose();
    super.dispose();
  }

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
        if (!_narrativeLoaded) {
          _narrativeLoaded = true;
          Future.microtask(() => _loadWeeklyNarrative(review.weekStart));
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
                      const SizedBox(height: AppSpacing.lg),
                      
                      const Divider(height: 32, color: AppColors.border),
                      const Text(
                        'Weekly Narrative Reflection',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review how this week\'s market played out compared to your pre-week narrative expectations.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question 1: Which scenario played out?
                      const Text(
                        'Which scenario played out?',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _reflScenarioCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Did Scenario A or Scenario B play out? Describe the delivery path...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Question 2: Was AMD phase correctly identified?
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Was the AMD phase correctly identified?',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _toggleHelper('Yes', true, AppColors.profit),
                            const SizedBox(width: 8),
                            _toggleHelper('No', false, AppColors.loss),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Question 3: Cleanest setup day
                      const Text(
                        'Which day had the cleanest setup?',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _reflDayCtrl,
                        maxLines: 1,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Wednesday London Session / Tuesday New York PM...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Question 4: Count of Sentence 5 complete before entry
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Number of trades with complete Sentence 5 before entry:',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, color: AppColors.textSecondary),
                              onPressed: _reflS5Count > 0
                                  ? () => setState(() => _reflS5Count--)
                                  : null,
                            ),
                            Text(
                              '$_reflS5Count',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _reflS5Count++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Question 5: Carry forward
                      const Text(
                        'What is the ONE thing to carry into next week?',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _reflCarryCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Rules adjustments, emotional focus, schedule improvements...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      const Divider(height: 32, color: AppColors.border),

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
                      const SizedBox(height: AppSpacing.lg),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saving
                              ? null
                              : () async {
                                  setState(() => _saving = true);
                                  try {
                                    await ref
                                        .read(reviewRepositoryProvider)
                                        .upsertWeekly({
                                      'id': review.id,
                                      'week_start': review.weekStart.toIso8601String(),
                                      'week_end': review.weekEnd.toIso8601String(),
                                      'reflection': _reflCtrl.text.trim(),
                                      'goals_next_week': _goalsCtrl.text.trim(),
                                    });

                                    // Also upsert weekly narrative reflection
                                    await ref.read(narrativeRepositoryProvider).upsertWeekly({
                                      'week_of': review.weekStart.toIso8601String().substring(0, 10),
                                      'refl_scenario_played': _reflScenarioCtrl.text.trim(),
                                      'refl_amd_correct': _reflAmdCorrect,
                                      'refl_cleanest_day': _reflDayCtrl.text.trim(),
                                      'refl_complete_s5_count': _reflS5Count,
                                      'refl_carry_forward': _reflCarryCtrl.text.trim(),
                                    });

                                    ref.invalidate(thisWeekNarrativeProvider);
                                    ref.invalidate(allWeeklyNarrativesProvider);
                                    ref.invalidate(_weeklyListProvider);
                                    ref.invalidate(_weeklyDetailProvider(widget.reviewId));

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Weekly review and narrative reflection updated ✓'),
                                        backgroundColor: AppColors.profit,
                                      ));
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppColors.loss,
                                      ));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _saving = false);
                                  }
                                },
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text('Save Reflection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.profit,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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
          color: Theme.of(context).colorScheme.surface,
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

  Widget _toggleHelper(String label, bool targetVal, Color color) {
    final isSelected = _reflAmdCorrect == targetVal;
    return GestureDetector(
      onTap: () => setState(() => _reflAmdCorrect = isSelected ? null : targetVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? color : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}
