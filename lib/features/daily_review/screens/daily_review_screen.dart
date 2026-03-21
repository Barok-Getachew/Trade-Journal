import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/daily_review.dart';
import '../../accounts/providers/account_provider.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/daily_review_provider.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  /// If reviewId is provided, load existing review; otherwise create for today.
  final String? reviewId;
  const DailyReviewScreen({super.key, this.reviewId});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  final _emotionCtrl = TextEditingController();
  final _mistakesCtrl = TextEditingController();
  final _wentWellCtrl = TextEditingController();
  int _planAdherence = 7;
  int _disciplineScore = 7;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  Future<void> _tryLoad() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      // No account selected yet — still show the form, just blank
      setState(() => _loaded = true);
      return;
    }
    try {
      final review = await ref
          .read(dailyReviewRepositoryProvider)
          .fetchForDate(account.id, DateTime.now());
      if (review != null && mounted) {
        setState(() {
          _emotionCtrl.text = review.emotionalState ?? '';
          _mistakesCtrl.text = review.mistakesMade ?? '';
          _wentWellCtrl.text = review.wentWell ?? '';
          _planAdherence = review.planAdherence;
          _disciplineScore = review.disciplineScore;
          _loaded = true;
        });
      } else if (mounted) {
        setState(() => _loaded = true);
      }
    } catch (_) {
      // On error, still show the form so the user isn't stuck
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _emotionCtrl.dispose();
    _mistakesCtrl.dispose();
    _wentWellCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final review = DailyReview(
        id: '',
        userId: '',
        accountId: account.id,
        reviewDate: DateTime.now(),
        emotionalState:
            _emotionCtrl.text.trim().isEmpty ? null : _emotionCtrl.text.trim(),
        mistakesMade: _mistakesCtrl.text.trim().isEmpty
            ? null
            : _mistakesCtrl.text.trim(),
        wentWell: _wentWellCtrl.text.trim().isEmpty
            ? null
            : _wentWellCtrl.text.trim(),
        planAdherence: _planAdherence,
        disciplineScore: _disciplineScore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(dailyReviewRepositoryProvider).upsert(review);
      ref.invalidate(todayReviewProvider);
      ref.invalidate(dailyReviewPendingProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily review saved ✓'),
            backgroundColor: AppColors.profit,
          ),
        );
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
    final today = DateTime.now();
    final dateStr =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(children: [
                        const Icon(Icons.today_rounded,
                            color: AppColors.primary, size: 28),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Review',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                            Text(dateStr,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.xl),
                      // Emotional State
                      _sectionLabel('How did you feel today?'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emotionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe your mental and emotional state...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // What went well
                      _sectionLabel('What went well?'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _wentWellCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Good decisions, patience, discipline...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Mistakes
                      _sectionLabel('Mistakes made today'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _mistakesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Overtrading, revenge trades, rule violations...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Plan adherence slider
                      _sliderSection(
                        label: 'Plan Adherence',
                        value: _planAdherence,
                        color: AppColors.primary,
                        onChanged: (v) => setState(() => _planAdherence = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Discipline score slider
                      _sliderSection(
                        label: 'Discipline Score',
                        value: _disciplineScore,
                        color: AppColors.profit,
                        onChanged: (v) => setState(() => _disciplineScore = v),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Save
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
                          label: const Text('Save Daily Review'),
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.profit),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14),
      );

  Widget _sliderSection({
    required String label,
    required int value,
    required Color color,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$value / 10',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: color,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
