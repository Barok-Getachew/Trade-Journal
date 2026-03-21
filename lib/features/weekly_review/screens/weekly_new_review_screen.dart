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

class _WeeklyNewReviewScreenState extends ConsumerState<WeeklyNewReviewScreen> {
  final _reflCtrl = TextEditingController();
  final _goalsCtrl = TextEditingController();
  DateTime _weekStart = _lastMonday();
  bool _saving = false;

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
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
      await ref.read(reviewRepositoryProvider).upsertWeekly({
        'week_start': _weekStart.toIso8601String(),
        'reflection': _reflCtrl.text.trim(),
        'goals_next_week': _goalsCtrl.text.trim(),
        // auto-populated from trades later if review_repository pulls stats
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weekly review saved ✓'),
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
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStr =
        'Week of ${_weekStart.day.toString().padLeft(2, '0')}/${_weekStart.month.toString().padLeft(2, '0')}/${_weekStart.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('New Weekly Review',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week start picker
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(weekStr,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
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
                          // snap to Monday
                          final monday =
                              d.subtract(Duration(days: d.weekday - 1));
                          setState(() => _weekStart = monday);
                        }
                      },
                      child: const Text('Change Week'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _label('Reflection'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reflCtrl,
                  maxLines: 6,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText:
                        'What went well this week? What would you do differently?\nWhat patterns did you notice in your trading?',
                    hintStyle: TextStyle(color: AppColors.textMuted),
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
                    hintText: 'Set 1-3 concrete, measurable goals...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Save Weekly Review'),
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.profit,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
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
}
