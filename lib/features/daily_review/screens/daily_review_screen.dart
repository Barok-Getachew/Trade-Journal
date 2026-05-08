import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/daily_review.dart';
import '../../accounts/providers/account_provider.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/daily_review_provider.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  final String? reviewId;
  const DailyReviewScreen({super.key, this.reviewId});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen>
    with SingleTickerProviderStateMixin {
  final _emotionCtrl = TextEditingController();
  final _mistakesCtrl = TextEditingController();
  final _wentWellCtrl = TextEditingController();
  int _planAdherence = 7;
  int _disciplineScore = 7;
  bool _saving = false;
  bool _loaded = false;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  Future<void> _tryLoad() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
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
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
      // Refresh history
      ref.invalidate(recentDailyReviewsProvider(account.id));
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
        '${_dayName(today.weekday)}, ${today.day} ${_monthName(today.month)} ${today.year}';
    final account = ref.watch(selectedAccountProvider);

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
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
                    const Text('Daily Review',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              // Tabs
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: "Today's Review"),
                  Tab(text: 'History'),
                ],
              ),
            ],
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Tab 0: Today's form
              !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : _TodayForm(
                      emotionCtrl: _emotionCtrl,
                      mistakesCtrl: _mistakesCtrl,
                      wentWellCtrl: _wentWellCtrl,
                      planAdherence: _planAdherence,
                      disciplineScore: _disciplineScore,
                      saving: _saving,
                      onPlanChanged: (v) => setState(() => _planAdherence = v),
                      onDisciplineChanged: (v) =>
                          setState(() => _disciplineScore = v),
                      onSave: _save,
                    ),

              // Tab 1: History
              _HistoryTab(accountId: account?.id),
            ],
          ),
        ),
      ],
    );
  }

  String _dayName(int wd) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];

  String _monthName(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

// ── Today's Review Form ────────────────────────────────────────────────────────

class _TodayForm extends StatelessWidget {
  final TextEditingController emotionCtrl;
  final TextEditingController mistakesCtrl;
  final TextEditingController wentWellCtrl;
  final int planAdherence;
  final int disciplineScore;
  final bool saving;
  final void Function(int) onPlanChanged;
  final void Function(int) onDisciplineChanged;
  final VoidCallback onSave;

  const _TodayForm({
    required this.emotionCtrl,
    required this.mistakesCtrl,
    required this.wentWellCtrl,
    required this.planAdherence,
    required this.disciplineScore,
    required this.saving,
    required this.onPlanChanged,
    required this.onDisciplineChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('How did you feel today?',
                  Icons.sentiment_satisfied_alt_outlined),
              const SizedBox(height: AppSpacing.sm),
              _textArea(emotionCtrl,
                  'Describe your mental and emotional state...'),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('What went well?', Icons.thumb_up_outlined),
              const SizedBox(height: AppSpacing.sm),
              _textArea(wentWellCtrl,
                  'Good decisions, patience, discipline...'),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel(
                  'Mistakes made today', Icons.warning_amber_outlined),
              const SizedBox(height: AppSpacing.sm),
              _textArea(mistakesCtrl,
                  'Overtrading, revenge trades, rule violations...'),
              const SizedBox(height: AppSpacing.xl),
              _SliderField(
                label: 'Plan Adherence',
                value: planAdherence,
                color: AppColors.primary,
                onChanged: onPlanChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SliderField(
                label: 'Discipline Score',
                value: disciplineScore,
                color: AppColors.profit,
                onChanged: onDisciplineChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Daily Review',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.profit,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, IconData icon) => Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ]);

  Widget _textArea(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      );
}

// ── Slider Field ────────────────────────────────────────────────────────────────

class _SliderField extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final void Function(int) onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 14)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$value / 10',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
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

// ── History Tab ────────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  final String? accountId;
  const _HistoryTab({this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accountId == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                color: AppColors.textMuted, size: 40),
            SizedBox(height: 12),
            Text('Select an account to view your review history.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final reviewsAsync = ref.watch(recentDailyReviewsProvider(accountId!));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.loss))),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    color: AppColors.textMuted, size: 48),
                SizedBox(height: 16),
                Text('No reviews yet',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'Complete today\'s review and it will appear here.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: reviews.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
        );
      },
    );
  }
}

// ── Review history card ────────────────────────────────────────────────────────

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
        '${_dayName(d.weekday)} ${d.day} ${_monthName(d.month)} ${d.year}';
    final isToday = _isToday(d);
    final avgScore = ((r.planAdherence + r.disciplineScore) / 2).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isToday ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ───────────────────────────────────────────
                Row(
                  children: [
                    // Score circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _scoreColor(avgScore).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$avgScore',
                        style: TextStyle(
                          color: _scoreColor(avgScore),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
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
                            ]
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            _scoreChip(
                                'Plan', r.planAdherence, AppColors.primary),
                            const SizedBox(width: 8),
                            _scoreChip('Discipline', r.disciplineScore,
                                AppColors.profit),
                          ]),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),

                // ── Expanded notes ──────────────────────────────────────
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  if (r.emotionalState != null && r.emotionalState!.isNotEmpty)
                    _noteSection(
                        Icons.sentiment_satisfied_alt_outlined,
                        'Emotional State',
                        r.emotionalState!),
                  if (r.wentWell != null && r.wentWell!.isNotEmpty) ...[
                    if (r.emotionalState != null)
                      const SizedBox(height: AppSpacing.sm),
                    _noteSection(
                        Icons.thumb_up_outlined, 'What Went Well', r.wentWell!),
                  ],
                  if (r.mistakesMade != null && r.mistakesMade!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _noteSection(Icons.warning_amber_outlined, 'Mistakes Made',
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

  Widget _scoreChip(String label, int value, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text('$value/10',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _noteSection(IconData icon, String label, String text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
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
