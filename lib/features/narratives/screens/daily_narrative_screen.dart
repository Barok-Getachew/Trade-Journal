import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/narrative_repository.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/narrative_provider.dart';

class DailyNarrativeScreen extends ConsumerStatefulWidget {
  final DateTime? date;
  const DailyNarrativeScreen({super.key, this.date});

  @override
  ConsumerState<DailyNarrativeScreen> createState() =>
      _DailyNarrativeScreenState();
}

class _DailyNarrativeScreenState
    extends ConsumerState<DailyNarrativeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  bool _saving = false;

  final _pairCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final _s1Ctrl = TextEditingController();
  final _s2Ctrl = TextEditingController();
  final _s3Ctrl = TextEditingController();
  final _s4Ctrl = TextEditingController();
  final _s5Ctrl = TextEditingController();

  // Post-trade
  bool? _postS5Complete;
  bool? _postDelivered;
  final _postBreakdownCtrl = TextEditingController();
  final _postEmotionalCtrl = TextEditingController();
  final _postPreparedCtrl = TextEditingController();

  late DateTime _date;
  String? _existingId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _date = widget.date ?? DateTime.now();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(narrativeRepositoryProvider);
    final existing = await repo.fetchDailyByDate(_date);
    if (existing != null && mounted) {
      _existingId = existing.id;
      _pairCtrl.text = existing.pair ?? '';
      _sessionCtrl.text = existing.session ?? '';
      _s1Ctrl.text = existing.s1HtfBias ?? '';
      _s2Ctrl.text = existing.s2PriceAction ?? '';
      _s3Ctrl.text = existing.s3LiquidityDraw ?? '';
      _s4Ctrl.text = existing.s4Path ?? '';
      _s5Ctrl.text = existing.s5Execution ?? '';
      _postS5Complete = existing.postS5Complete;
      _postDelivered = existing.postDelivered;
      _postBreakdownCtrl.text = existing.postBreakdown ?? '';
      _postEmotionalCtrl.text = existing.postEmotionalState ?? '';
      _postPreparedCtrl.text = existing.postPreparedVersion ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pairCtrl.dispose();
    _sessionCtrl.dispose();
    _s1Ctrl.dispose();
    _s2Ctrl.dispose();
    _s3Ctrl.dispose();
    _s4Ctrl.dispose();
    _s5Ctrl.dispose();
    _postBreakdownCtrl.dispose();
    _postEmotionalCtrl.dispose();
    _postPreparedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(narrativeRepositoryProvider);
      await repo.upsertDaily({
        'narrative_date': _date.toIso8601String().substring(0, 10),
        'pair': _pairCtrl.text.trim(),
        'session': _sessionCtrl.text.trim(),
        's1_htf_bias': _s1Ctrl.text.trim(),
        's2_price_action': _s2Ctrl.text.trim(),
        's3_liquidity_draw': _s3Ctrl.text.trim(),
        's4_path': _s4Ctrl.text.trim(),
        's5_execution': _s5Ctrl.text.trim(),
        'post_s5_complete': _postS5Complete,
        'post_delivered': _postDelivered,
        'post_breakdown': _postBreakdownCtrl.text.trim(),
        'post_emotional_state': _postEmotionalCtrl.text.trim(),
        'post_prepared_version': _postPreparedCtrl.text.trim(),
      });
      ref.invalidate(todayDailyNarrativeProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Narrative saved ✓'),
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
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Narrative',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text(dateStr,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
              label: const Text('Save',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '📋 Pre-Session'),
            Tab(text: '📌 Post-Trade'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: AppColors.primary,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text('Save',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _PreSessionTab(
                  pairCtrl: _pairCtrl,
                  sessionCtrl: _sessionCtrl,
                  s1Ctrl: _s1Ctrl,
                  s2Ctrl: _s2Ctrl,
                  s3Ctrl: _s3Ctrl,
                  s4Ctrl: _s4Ctrl,
                  s5Ctrl: _s5Ctrl,
                ),
                _PostTradeTab(
                  s5Complete: _postS5Complete,
                  delivered: _postDelivered,
                  breakdownCtrl: _postBreakdownCtrl,
                  emotionalCtrl: _postEmotionalCtrl,
                  preparedCtrl: _postPreparedCtrl,
                  onS5Changed: (v) => setState(() => _postS5Complete = v),
                  onDeliveredChanged: (v) =>
                      setState(() => _postDelivered = v),
                ),
              ],
            ),
    );
  }
}

// ── Pre-Session Tab ────────────────────────────────────────────────────────────

class _PreSessionTab extends StatelessWidget {
  final TextEditingController pairCtrl, sessionCtrl;
  final TextEditingController s1Ctrl, s2Ctrl, s3Ctrl, s4Ctrl, s5Ctrl;

  const _PreSessionTab({
    required this.pairCtrl,
    required this.sessionCtrl,
    required this.s1Ctrl,
    required this.s2Ctrl,
    required this.s3Ctrl,
    required this.s4Ctrl,
    required this.s5Ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleCard(),
              const SizedBox(height: AppSpacing.md),
              // Pair + Session row
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: pairCtrl,
                      label: 'Pair / Instrument',
                      hint: 'e.g. EUR/USD, XAU/USD',
                      icon: Icons.candlestick_chart_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _inputField(
                      controller: sessionCtrl,
                      label: 'Session',
                      hint: 'London / New York / Asia',
                      icon: Icons.access_time_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SentenceCard(
                number: 1,
                title: 'HTF Bias & Delivery',
                guidance:
                    'What has already been delivered and what is the institutional positioning?',
                template:
                    '"The [timeframe] trend is [direction] and institutions have already delivered price [from/to] [level], using [event/structure] to [institutional purpose]."',
                controller: s1Ctrl,
                color: const Color(0xFF3D7EFF),
              ),
              const SizedBox(height: AppSpacing.md),
              _SentenceCard(
                number: 2,
                title: 'Current Price Action & Evidence',
                guidance:
                    'What is price doing RIGHT NOW and what is the institutional fingerprint proving it?',
                template:
                    '"Price is currently [doing what] at [level], and the [candle/structure] on the [timeframe] confirms that institutions have [finished/started] [what activity]."',
                controller: s2Ctrl,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: AppSpacing.md),
              _SentenceCard(
                number: 3,
                title: 'Liquidity Draw',
                guidance:
                    'What has not been taken yet and why do institutions need it?',
                template:
                    '"The next unmitigated liquidity is [internal level] as the immediate draw and [external level] as the longer term target, where institutional [long/short] positions will be closed against resting [buy/sell] orders."',
                controller: s3Ctrl,
                color: const Color(0xFF059669),
              ),
              const SizedBox(height: AppSpacing.md),
              _SentenceCard(
                number: 4,
                title: 'The Path',
                guidance:
                    'How will price get there? What manipulation happens before delivery?',
                template:
                    '"Before reaching [target], price is likely to [sweep/retrace/consolidate] at [level] on the [timeframe], using [OB/FVG/liquidity] as the vehicle before committing to [direction]."',
                controller: s4Ctrl,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: AppSpacing.md),
              _SentenceCard(
                number: 5,
                title: 'Execution Plan ⚡',
                guidance:
                    'This must be complete BEFORE price reaches your zone. No exceptions.',
                template:
                    '"I will enter [long/short] at [exact price] when the [timeframe] shows [ChoCH/engulfing/displacement] at the [exact zone], with stop at [exact level] and target at [exact level], giving me [X:Y] risk reward."',
                controller: s5Ctrl,
                color: AppColors.loss,
                isRule: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ruleCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fill this every morning before the session opens. If Sentence 5 is not complete — the trade does not exist.',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) =>
      TextField(
        controller: controller,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          labelStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}

// ── Sentence Card ─────────────────────────────────────────────────────────────

class _SentenceCard extends StatelessWidget {
  final int number;
  final String title;
  final String guidance;
  final String template;
  final TextEditingController controller;
  final Color color;
  final bool isRule;

  const _SentenceCard({
    required this.number,
    required this.title,
    required this.guidance,
    required this.template,
    required this.controller,
    required this.color,
    this.isRule = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd)),
              border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('$number',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                if (isRule)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.loss.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('MANDATORY',
                        style: TextStyle(
                            color: AppColors.loss,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guidance
                Text(guidance,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                // Template
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: color.withOpacity(0.15)),
                  ),
                  child: Text(template,
                      style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Text input
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Write your sentence here...',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post-Trade Tab ─────────────────────────────────────────────────────────────

class _PostTradeTab extends StatelessWidget {
  final bool? s5Complete;
  final bool? delivered;
  final TextEditingController breakdownCtrl, emotionalCtrl, preparedCtrl;
  final ValueChanged<bool?> onS5Changed;
  final ValueChanged<bool?> onDeliveredChanged;

  const _PostTradeTab({
    required this.s5Complete,
    required this.delivered,
    required this.breakdownCtrl,
    required this.emotionalCtrl,
    required this.preparedCtrl,
    required this.onS5Changed,
    required this.onDeliveredChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(),
              const SizedBox(height: AppSpacing.md),
              _YesNoRow(
                question:
                    'Was Sentence 5 written BEFORE price reached the zone?',
                value: s5Complete,
                onChanged: onS5Changed,
              ),
              const SizedBox(height: AppSpacing.sm),
              _YesNoRow(
                question: 'Did price deliver as narrated?',
                value: delivered,
                onChanged: onDeliveredChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _postField(
                controller: breakdownCtrl,
                label: 'Where did the narrative break down (if at all)?',
                hint:
                    'Describe the exact point where your analysis diverged from price action...',
                lines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              _postField(
                controller: emotionalCtrl,
                label: 'Emotional state during trade',
                hint: 'Calm / Anxious / Impatient / Confident / FOMO...',
                lines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              _postField(
                controller: preparedCtrl,
                label:
                    'What would the PREPARED version of this trade look like?',
                hint:
                    'If you could replay this trade with perfect preparation, what would you have done differently?',
                lines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningDim,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fill this immediately after closing your trade. Honest reflection is the edge.',
                style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _postField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int lines = 3,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: lines,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      );
}

class _YesNoRow extends StatelessWidget {
  final String question;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _YesNoRow({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(question,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: AppSpacing.md),
          _toggle('Yes', true, AppColors.profit),
          const SizedBox(width: 8),
          _toggle('No', false, AppColors.loss),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool targetVal, Color color) {
    final isSelected = value == targetVal;
    return GestureDetector(
      onTap: () => onChanged(isSelected ? null : targetVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceElevated,
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
