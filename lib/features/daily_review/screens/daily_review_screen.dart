import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/daily_review.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/daily_review_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class DailyReviewScreen extends ConsumerWidget {
  final String? reviewId;
  const DailyReviewScreen({super.key, this.reviewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allDailyReviewsProvider);
    final todayAsync = ref.watch(todayReviewGlobalProvider);

    final bool todayDone =
        todayAsync.valueOrNull != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.today_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Reviews',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text(
                    'Your personal trading journal',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              // Today's review button
              ElevatedButton.icon(
                icon: Icon(
                  todayDone ? Icons.edit_rounded : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(
                  todayDone ? "Edit Today's Review" : "Write Today's Review",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      todayDone ? AppColors.surfaceElevated : AppColors.primary,
                  foregroundColor:
                      todayDone ? AppColors.textPrimary : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openForm(context, ref,
                    existingReview: todayAsync.valueOrNull),
              ),
            ],
          ),
        ),

        // ── Today's review status banner ──────────────────────────────────
        if (todayDone)
          _TodayDoneBanner(review: todayAsync.value!)
        else
          _TodayPendingBanner(
              onTap: () => _openForm(context, ref, existingReview: null)),

        const SizedBox(height: AppSpacing.sm),

        // ── History list ─────────────────────────────────────────────────
        Expanded(
          child: reviewsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.loss))),
            data: (reviews) {
              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          color: AppColors.textMuted, size: 52),
                      const SizedBox(height: 16),
                      const Text('No reviews yet',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text(
                        'Write your first daily review\nto start tracking your progress.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Write Today's Review"),
                        onPressed: () =>
                            _openForm(context, ref, existingReview: null),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                    AppSpacing.lg, AppSpacing.xl),
                itemCount: reviews.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) =>
                    _ReviewCard(review: reviews[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, WidgetRef ref,
      {DailyReview? existingReview}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewFormDialog(
        existing: existingReview,
        onSaved: () {
          ref.invalidate(allDailyReviewsProvider);
          ref.invalidate(todayReviewGlobalProvider);
          ref.invalidate(todayReviewProvider);
          ref.invalidate(dailyReviewPendingProvider);
        },
      ),
    );
  }
}

// ── Today done banner ──────────────────────────────────────────────────────────

class _TodayDoneBanner extends StatelessWidget {
  final DailyReview review;
  const _TodayDoneBanner({required this.review});

  @override
  Widget build(BuildContext context) {
    final avg =
        ((review.planAdherence + review.disciplineScore) / 2).round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.profit.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.profit.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.profit, size: 18),
        const SizedBox(width: 10),
        const Text(
          "Today's review is complete",
          style: TextStyle(
              color: AppColors.profit,
              fontWeight: FontWeight.w600,
              fontSize: 13),
        ),
        const Spacer(),
        Text('Avg score: $avg/10',
            style: const TextStyle(
                color: AppColors.profit, fontSize: 12)),
      ]),
    );
  }
}

// ── Today pending banner ───────────────────────────────────────────────────────

class _TodayPendingBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayPendingBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.pending_outlined,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          const Text(
            "Today's review is pending — tap to write it",
            style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.warning, size: 12),
        ]),
      ),
    );
  }
}

// ── Review Form Dialog ─────────────────────────────────────────────────────────

class _ReviewFormDialog extends ConsumerStatefulWidget {
  final DailyReview? existing;
  final VoidCallback onSaved;
  const _ReviewFormDialog({this.existing, required this.onSaved});

  @override
  ConsumerState<_ReviewFormDialog> createState() =>
      _ReviewFormDialogState();
}

class _ReviewFormDialogState extends ConsumerState<_ReviewFormDialog> {
  final _emotionCtrl = TextEditingController();
  final _wellCtrl = TextEditingController();
  final _mistakesCtrl = TextEditingController();
  int _plan = 7;
  int _discipline = 7;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _emotionCtrl.text = e.emotionalState ?? '';
      _wellCtrl.text = e.wentWell ?? '';
      _mistakesCtrl.text = e.mistakesMade ?? '';
      _plan = e.planAdherence;
      _discipline = e.disciplineScore;
    }
  }

  @override
  void dispose() {
    _emotionCtrl.dispose();
    _wellCtrl.dispose();
    _mistakesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Silently resolve account — get the user's first account as FK
      final accounts =
          await ref.read(accountRepositoryProvider).fetchAll();
      final accountId =
          accounts.isNotEmpty ? accounts.first.id : null;

      if (accountId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Create at least one account before writing a review.'),
            backgroundColor: AppColors.warning,
          ));
        }
        setState(() => _saving = false);
        return;
      }

      final review = DailyReview(
        id: widget.existing?.id ?? '',
        userId: '',
        accountId: accountId,
        reviewDate: DateTime.now(),
        emotionalState: _emotionCtrl.text.trim().isEmpty
            ? null
            : _emotionCtrl.text.trim(),
        wentWell: _wellCtrl.text.trim().isEmpty
            ? null
            : _wellCtrl.text.trim(),
        mistakesMade: _mistakesCtrl.text.trim().isEmpty
            ? null
            : _mistakesCtrl.text.trim(),
        planAdherence: _plan,
        disciplineScore: _discipline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(dailyReviewRepositoryProvider).upsert(review);
      widget.onSaved();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Daily review saved ✓'),
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
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${_dayName(today.weekday)}, ${today.day} ${_monthName(today.month)} ${today.year}';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    widget.existing != null
                        ? "Edit Today's Review"
                        : "Today's Review",
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17),
                  ),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ]),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            const Divider(
                height: 20,
                color: AppColors.border,
                indent: 24,
                endIndent: 24),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                        'How did you feel today?',
                        Icons.sentiment_satisfied_alt_outlined),
                    const SizedBox(height: 8),
                    _area(_emotionCtrl,
                        'Describe your mental and emotional state...'),
                    const SizedBox(height: 16),
                    _label('What went well?', Icons.thumb_up_outlined),
                    const SizedBox(height: 8),
                    _area(_wellCtrl,
                        'Good decisions, patience, discipline...'),
                    const SizedBox(height: 16),
                    _label('Mistakes made today',
                        Icons.warning_amber_outlined),
                    const SizedBox(height: 8),
                    _area(_mistakesCtrl,
                        'Overtrading, revenge trades, rule violations...'),
                    const SizedBox(height: 20),
                    _ScoreSlider(
                      label: 'Plan Adherence',
                      value: _plan,
                      color: AppColors.primary,
                      onChanged: (v) => setState(() => _plan = v),
                    ),
                    const SizedBox(height: 12),
                    _ScoreSlider(
                      label: 'Discipline Score',
                      value: _discipline,
                      color: AppColors.profit,
                      onChanged: (v) =>
                          setState(() => _discipline = v),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Review',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, IconData icon) => Row(children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]);

  Widget _area(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.all(12),
          isDense: true,
        ),
      );

  String _dayName(int wd) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];
  String _monthName(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Score Slider ───────────────────────────────────────────────────────────────

class _ScoreSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final void Function(int) onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$value / 10',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review Card (history list) ─────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final DailyReview review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final d = r.reviewDate;
    final dateStr =
        '${_dayName(d.weekday)}, ${d.day} ${_monthName(d.month)} ${d.year}';
    final isToday = _isToday(d);
    final avg = ((r.planAdherence + r.disciplineScore) / 2).round();
    final scoreColor = _scoreColor(avg);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(children: [
                  // Score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('$avg',
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 20)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(dateStr,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDim,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Today',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 5),
                        Row(children: [
                          _chip('Plan', r.planAdherence, AppColors.primary),
                          const SizedBox(width: 10),
                          _chip('Discipline', r.disciplineScore,
                              AppColors.profit),
                        ]),
                      ],
                    ),
                  ),
                  // Preview snippet
                  if (!_expanded &&
                      (r.wentWell != null || r.emotionalState != null))
                    Flexible(
                      child: Text(
                        (r.wentWell ?? r.emotionalState)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
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
                ]),

                // Expanded notes
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  if (r.emotionalState != null &&
                      r.emotionalState!.isNotEmpty)
                    _note(Icons.sentiment_satisfied_alt_outlined,
                        'How I felt', r.emotionalState!),
                  if (r.wentWell != null && r.wentWell!.isNotEmpty) ...[
                    if (r.emotionalState?.isNotEmpty == true)
                      const SizedBox(height: AppSpacing.sm),
                    _note(Icons.thumb_up_outlined, 'What went well',
                        r.wentWell!),
                  ],
                  if (r.mistakesMade != null &&
                      r.mistakesMade!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _note(Icons.warning_amber_outlined, 'Mistakes made',
                        r.mistakesMade!),
                  ],
                  if (r.emotionalState == null &&
                      r.wentWell == null &&
                      r.mistakesMade == null)
                    const Text('No notes recorded.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, int value, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          Text('$value/10',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _note(IconData icon, String label, String text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5)),
        ],
      );

  Color _scoreColor(int score) {
    if (score >= 8) return AppColors.profit;
    if (score >= 5) return AppColors.warning;
    return AppColors.loss;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _dayName(int wd) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];
  String _monthName(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
