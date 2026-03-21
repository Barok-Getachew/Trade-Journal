import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../providers/dashboard_provider.dart';
import '../../accounts/providers/account_provider.dart';
import '../../auth/providers/repository_providers.dart';

class MonthlyTargetCard extends ConsumerWidget {
  const MonthlyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetAsync = ref.watch(monthlyRTargetProvider);

    return targetAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(),
      data: (data) {
        final current = data.current;
        final target = data.target;
        final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        final isReached = target > 0 && current >= target;

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly R-Target',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (target > 0)
                    Text(
                      '${current.toStringAsFixed(1)}R / ${target.toStringAsFixed(1)}R',
                      style: TextStyle(
                        color: isReached
                            ? AppColors.profit
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (target <= 0)
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'No monthly R-target set',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showSetTargetDialog(context, ref),
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Set Monthly Goal'),
                      ),
                    ],
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isReached ? AppColors.profit : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isReached
                          ? 'Goal Reached! 🚀'
                          : '${(progress * 100).toInt()}% of goal',
                      style: TextStyle(
                        color:
                            isReached ? AppColors.profit : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showSetTargetDialog(context, ref),
                      child: const Text(
                        'Edit Goal',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showSetTargetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Set Monthly R-Target'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Target R-Multiple',
            hintText: 'e.g. 10.0',
            suffixText: 'R',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = double.tryParse(controller.text);
              if (target != null) {
                final account = ref.read(selectedAccountProvider);
                if (account != null) {
                  final repo = ref.read(accountRepositoryProvider);
                  await repo.update(account.id, {'monthly_r_target': target});
                  ref.invalidate(selectedAccountProvider);
                  ref.invalidate(monthlyRTargetProvider);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
