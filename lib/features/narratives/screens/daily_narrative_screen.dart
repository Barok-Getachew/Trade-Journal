import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/print_service.dart';
import '../../../data/repositories/narrative_repository.dart';
import '../../../domain/models/daily_narrative.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/narrative_provider.dart';

class DailyNarrativeScreen extends ConsumerStatefulWidget {
  final DateTime? date;
  const DailyNarrativeScreen({super.key, this.date});

  @override
  ConsumerState<DailyNarrativeScreen> createState() =>
      _DailyNarrativeScreenState();
}

class _DailyNarrativeScreenState extends ConsumerState<DailyNarrativeScreen> {
  bool _loading = true;
  bool _saving = false;

  final _pairCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final _s1Ctrl = TextEditingController();
  final _s2Ctrl = TextEditingController();
  final _s3Ctrl = TextEditingController();
  final _s4Ctrl = TextEditingController();
  final _s5Ctrl = TextEditingController();

  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? DateTime.now();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(narrativeRepositoryProvider);
    final existing = await repo.fetchDailyByDate(_date);
    if (existing != null && mounted) {
      _pairCtrl.text = existing.pair ?? '';
      _sessionCtrl.text = existing.session ?? '';
      _s1Ctrl.text = existing.s1HtfBias ?? '';
      _s2Ctrl.text = existing.s2PriceAction ?? '';
      _s3Ctrl.text = existing.s3LiquidityDraw ?? '';
      _s4Ctrl.text = existing.s4Path ?? '';
      _s5Ctrl.text = existing.s5Execution ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pairCtrl.dispose();
    _sessionCtrl.dispose();
    _s1Ctrl.dispose();
    _s2Ctrl.dispose();
    _s3Ctrl.dispose();
    _s4Ctrl.dispose();
    _s5Ctrl.dispose();
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
      });
      ref.invalidate(todayDailyNarrativeProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pre-Session Narrative saved ✓'),
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

  /// Build a snapshot of the current form state as a DailyNarrative for printing
  DailyNarrative _buildSnapshot() => DailyNarrative(
        id: 'preview',
        userId: '',
        narrativeDate: _date,
        pair: _pairCtrl.text.trim(),
        session: _sessionCtrl.text.trim(),
        s1HtfBias: _s1Ctrl.text.trim(),
        s2PriceAction: _s2Ctrl.text.trim(),
        s3LiquidityDraw: _s3Ctrl.text.trim(),
        s4Path: _s4Ctrl.text.trim(),
        s5Execution: _s5Ctrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Narrative Builder',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Pre-Session Narrative for $dateStr',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Narrative History',
            onPressed: () => context.push('/narrative-history'),
          ),
          // ── Print / PDF button ─────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print / Save as PDF',
            color: AppColors.textSecondary,
            onPressed: () => PrintService.printDailyNarrative(
              context: context,
              narrative: _buildSnapshot(),
            ),
          ),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                              controller: _pairCtrl,
                              label: 'Pair / Instrument',
                              hint: 'e.g. EUR/USD, XAU/USD',
                              icon: Icons.candlestick_chart_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _inputField(
                              controller: _sessionCtrl,
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
                        controller: _s1Ctrl,
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
                        controller: _s2Ctrl,
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
                        controller: _s3Ctrl,
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
                        controller: _s4Ctrl,
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
                        controller: _s5Ctrl,
                        color: AppColors.loss,
                        isRule: true,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text('Save Pre-Session Narrative',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Text(guidance,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
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
