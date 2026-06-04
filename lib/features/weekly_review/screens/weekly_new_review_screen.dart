import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/repository_providers.dart';
import '../../narratives/providers/narrative_provider.dart';

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

  // Narrative Reflection fields
  final _reflScenarioCtrl = TextEditingController();
  final _reflDayCtrl = TextEditingController();
  final _reflCarryCtrl = TextEditingController();
  bool? _reflAmdCorrect;
  int _reflS5Count = 0;

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyNarrative();
  }

  Future<void> _loadWeeklyNarrative() async {
    try {
      final existing = await ref.read(narrativeRepositoryProvider).fetchWeeklyByDate(_weekStart);
      if (existing != null && mounted) {
        setState(() {
          _reflScenarioCtrl.text = existing.reflScenarioPlayed ?? '';
          _reflDayCtrl.text = existing.reflCleanestDay ?? '';
          _reflCarryCtrl.text = existing.reflCarryForward ?? '';
          _reflAmdCorrect = existing.reflAmdCorrect;
          _reflS5Count = existing.reflCompleteS5Count ?? 0;
        });
      } else {
        setState(() {
          _reflScenarioCtrl.clear();
          _reflDayCtrl.clear();
          _reflCarryCtrl.clear();
          _reflAmdCorrect = null;
          _reflS5Count = 0;
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

      // Upsert weekly narrative reflection fields
      await ref.read(narrativeRepositoryProvider).upsertWeekly({
        'week_of': _weekStart.toIso8601String().substring(0, 10),
        'refl_scenario_played': _reflScenarioCtrl.text.trim(),
        'refl_amd_correct': _reflAmdCorrect,
        'refl_cleanest_day': _reflDayCtrl.text.trim(),
        'refl_complete_s5_count': _reflS5Count,
        'refl_carry_forward': _reflCarryCtrl.text.trim(),
      });

      // Invalidate weekly narrative providers
      ref.invalidate(thisWeekNarrativeProvider);
      ref.invalidate(allWeeklyNarrativesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(totalTrades > 0
                ? 'Weekly review and narrative reflection saved ✓  ($totalTrades trades, ${(winRate * 100).toStringAsFixed(0)}% win rate)'
                : 'Weekly review and narrative reflection saved ✓  (no trades logged this week)'),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                            _loadWeeklyNarrative();
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
                _label('Which scenario played out?'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reflScenarioCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Did Scenario A or Scenario B play out? Describe the delivery path...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
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
                          'Was the AMD (Accumulation-Manipulation-Distribution) phase correctly identified?',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _toggle('Yes', true, AppColors.profit),
                      const SizedBox(width: 8),
                      _toggle('No', false, AppColors.loss),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Question 3: Cleanest setup day
                _label('Which day had the cleanest setup?'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reflDayCtrl,
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Wednesday London Session / Tuesday New York PM...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
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
                _label('What is the ONE thing to carry into next week?'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reflCarryCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Rules adjustments, emotional control focus, schedule improvements...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 32, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),

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

  Widget _toggle(String label, bool targetVal, Color color) {
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
