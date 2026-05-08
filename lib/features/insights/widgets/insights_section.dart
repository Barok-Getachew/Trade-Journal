import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../providers/insights_provider.dart';

class InsightsSection extends ConsumerStatefulWidget {
  const InsightsSection({super.key});

  @override
  ConsumerState<InsightsSection> createState() => _InsightsSectionState();
}

class _InsightsSectionState extends ConsumerState<InsightsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B47FF), Color(0xFF9B6DFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Insights',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Patterns detected from your trading history',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B47FF).withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '${insights.length} found',
                          style: const TextStyle(
                            color: Color(0xFF9B6DFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Cards
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.md),
                ...insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _InsightCard(insight: insight),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final TradeInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = switch (insight.type) {
      InsightType.warning => (
          AppColors.warning,
          AppColors.warningDim,
          Icons.warning_amber_rounded,
        ),
      InsightType.positive => (
          AppColors.profit,
          AppColors.profitDim,
          Icons.trending_up_rounded,
        ),
      InsightType.tip => (
          AppColors.primary,
          AppColors.primaryDim,
          Icons.lightbulb_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon
          Text(insight.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Type indicator chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Streaks & Badges Section ─────────────────────────────────────────────────

class StreamsAndBadgesSection extends ConsumerWidget {
  const StreamsAndBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final badgesAsync = ref.watch(badgesProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streaks row
          streakAsync.when(
            loading: () =>
                const LoadingShimmer(width: double.infinity, height: 60),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Active Streaks',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                        child: _StreakTile(
                            label: 'Win Streak',
                            value: s.winStreak,
                            icon: '🔥',
                            color: s.winStreak >= 3
                                ? AppColors.profit
                                : AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _StreakTile(
                            label: 'Discipline',
                            value: s.disciplineStreak,
                            icon: '🧠',
                            color: s.disciplineStreak >= 5
                                ? AppColors.profit
                                : AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _StreakTile(
                            label: 'No Impulse',
                            value: s.impulseFreeDays,
                            icon: '🧘',
                            suffix: 'd',
                            color: s.impulseFreeDays >= 7
                                ? AppColors.profit
                                : AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Badges
          badgesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (badges) {
              final earned = badges.where((b) => b.earned).toList();
              if (earned.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  const Row(children: [
                    Icon(Icons.military_tech_rounded,
                        color: AppColors.warning, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Badges Earned',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: earned
                        .map((b) => Tooltip(
                              message: b.description,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                  border: Border.all(
                                      color:
                                          AppColors.warning.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(b.icon,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      b.title,
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  final String label;
  final int value;
  final String icon;
  final Color color;
  final String suffix;

  const _StreakTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '$value$suffix',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
