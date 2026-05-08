import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/repository_providers.dart';

// ── Create new weekly review ──────────────────────────────────────────────────

class WeeklyNewReviewScreen extends ConsumerStatefulWidget {
  const WeeklyNewReviewScreen({super.key});

  @override
  ConsumerState<WeeklyNewReviewScreen> createState() =>
      _WeeklyNewReviewScreenState();
}

class _WeeklyNewReviewScreenState
    extends ConsumerState<WeeklyNewReviewScreen> {
  final _reflCtrl = TextEditingController();
  final _goalsCtrl = TextEditingController();
  DateTime _weekStart = _lastMonday();
  bool _saving = false;

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _reflCtrl.dispose();
    _goalsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final weekEnd = _weekStart.add(const Duration(days: 6));

      // ── Fetch trades for the selected week and compute stats ──────────
      final trades = await ref.read(tradeRepositoryProvider).fetchAll(
            from: _weekStart,
            to: weekEnd.add(const Duration(hours: 23, minutes: 59)),
          );

      final totalTrades = trades.length;
      final wins = trades.where((t) => t.netPnl > 0).length;
      final losses = trades.where((t) => t.netPnl <= 0).length;
      final totalR = trades.fold<double>(0, (s, t) => s + t.rMultiple);
      final winRate =
          totalTrades > 0 ? wins / totalTrades : 0.0;
      final rulesFollowedPct = totalTrades > 0
          ? trades.where((t) => t.rulesFollowed).length / totalTrades
          : 1.0;

      await ref.read(reviewRepositoryProvider).upsertWeekly({
        'week_start': _weekStart.toIso8601String(),
        'week_end': weekEnd.toIso8601String(),
        'total_trades': totalTrades,
        'wins': wins,
        'losses': losses,
        'total_r': totalR,
        'win_rate': winRate,
        'rules_followed_pct': rulesFollowedPct,
        'reflection': _reflCtrl.text.trim(),
        'goals_next_week': _goalsCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(totalTrades > 0
                ? 'Weekly review saved ✓  ($totalTrades trades, ${(winRate * 100).toStringAsFixed(0)}% win rate)'
                : 'Weekly review saved ✓  (no trades logged this week)'),
            backgroundColor: AppColors.profit,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.loss,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final weekStr =
        '${_fmt(_weekStart)} – ${_fmt(weekEnd)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('New Weekly Review',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme:
            const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week picker
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Week',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          Text(weekStr,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _weekStart,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF3D7EFF)),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null && mounted) {
                            final monday = d.subtract(
                                Duration(days: d.weekday - 1));
                            setState(() => _weekStart =
                                DateTime(monday.year, monday.month,
                                    monday.day));
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Info chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: const [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Trade stats (win rate, R, etc.) are auto-calculated from your logged trades for the selected week.',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: AppSpacing.xl),

                _label('Weekly Reflection'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reflCtrl,
                  maxLines: 6,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText:
                        'What went well this week? What would you do differently?\nWhat patterns did you notice in your trading?',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                _label('Goals for Next Week'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _goalsCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText:
                        'Set 1–3 concrete, measurable goals...',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Weekly Review',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.profit,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14));

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
