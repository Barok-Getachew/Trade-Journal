import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/weekly_narrative.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/narrative_provider.dart';

class WeeklyNarrativeScreen extends ConsumerStatefulWidget {
  const WeeklyNarrativeScreen({super.key});

  @override
  ConsumerState<WeeklyNarrativeScreen> createState() => _WeeklyNarrativeScreenState();
}

class _WeeklyNarrativeScreenState extends ConsumerState<WeeklyNarrativeScreen> {
  bool _loading = true;
  bool _saving = false;

  final _instrCtrl = TextEditingController();
  final _newsCtrl = TextEditingController();
  final _s1Ctrl = TextEditingController();
  final _s2Ctrl = TextEditingController();
  final _s4Ctrl = TextEditingController();
  final _saCtrl = TextEditingController();
  final _sbCtrl = TextEditingController();

  late DateTime _weekOf;
  List<LiquidityLevel> _liqMap = WeeklyNarrative.defaultLiquidityMap();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekOf = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    final existing = await ref.read(narrativeRepositoryProvider).fetchWeeklyByDate(_weekOf);
    if (existing != null && mounted) {
      _instrCtrl.text = existing.primaryInstrument ?? '';
      _newsCtrl.text = existing.highImpactNews ?? '';
      _s1Ctrl.text = existing.step1Cot ?? '';
      _s2Ctrl.text = existing.step2HtfStructure ?? '';
      _s4Ctrl.text = existing.step4Amd ?? '';
      _saCtrl.text = existing.scenarioA ?? '';
      _sbCtrl.text = existing.scenarioB ?? '';
      if (existing.liquidityMap.isNotEmpty) _liqMap = List.from(existing.liquidityMap);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _instrCtrl.dispose();
    _newsCtrl.dispose();
    _s1Ctrl.dispose();
    _s2Ctrl.dispose();
    _s4Ctrl.dispose();
    _saCtrl.dispose();
    _sbCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Fetch existing so we don't overwrite reflection fields when saving pre-week
      final existing = await ref.read(narrativeRepositoryProvider).fetchWeeklyByDate(_weekOf);

      await ref.read(narrativeRepositoryProvider).upsertWeekly({
        'week_of': _weekOf.toIso8601String().substring(0, 10),
        'primary_instrument': _instrCtrl.text.trim(),
        'high_impact_news': _newsCtrl.text.trim(),
        'step1_cot': _s1Ctrl.text.trim(),
        'step2_htf_structure': _s2Ctrl.text.trim(),
        'liquidity_map': _liqMap.map((e) => e.toMap()).toList(),
        'step4_amd': _s4Ctrl.text.trim(),
        'scenario_a': _saCtrl.text.trim(),
        'scenario_b': _sbCtrl.text.trim(),
        // Keep existing reflection fields if present
        if (existing != null) ...{
          'refl_scenario_played': existing.reflScenarioPlayed,
          'refl_amd_correct': existing.reflAmdCorrect,
          'refl_cleanest_day': existing.reflCleanestDay,
          'refl_complete_s5_count': existing.reflCompleteS5Count,
          'refl_carry_forward': existing.reflCarryForward,
        }
      });
      ref.invalidate(thisWeekNarrativeProvider);
      ref.invalidate(allWeeklyNarrativesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pre-Week Narrative saved ✓'),
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
    final weekStr = '${_weekOf.day}/${_weekOf.month}/${_weekOf.year}';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Narrative Builder',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Pre-Week Plan for Week of $weekStr',
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
                      Row(
                        children: [
                          Expanded(
                            child: _field(_instrCtrl, 'Primary Instrument', 'EUR/USD, XAU/USD...'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _field(_newsCtrl, 'High Impact News This Week', 'NFP, CPI, FOMC...'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _stepCard(
                          1,
                          'COT & Macro Positioning',
                          'Where are institutions positioned heading into this week?',
                          '"Hedge funds are currently [net long/short] on [instrument] and retail sentiment is [bullish/bearish], creating a [agreement/divergence] that suggests [institutional move]."',
                          _s1Ctrl,
                          const Color(0xFF3D7EFF)),
                      const SizedBox(height: AppSpacing.md),
                      _stepCard(
                          2,
                          'HTF Structure',
                          'What does the weekly/daily chart say about where price is going?',
                          '"On the [Weekly/Daily], price has [broken structure/respected OB/swept liquidity] at [level] and the next significant draw is [level] because [why]."',
                          _s2Ctrl,
                          const Color(0xFF7C3AED)),
                      const SizedBox(height: AppSpacing.md),
                      _LiquidityMapCard(
                          liqMap: _liqMap,
                          onChanged: (i, l) => setState(() => _liqMap[i] = l)),
                      const SizedBox(height: AppSpacing.md),
                      _stepCard(
                          4,
                          'AMD Weekly Bias',
                          'How will institutions use this week\'s structure and news?',
                          '"This week institutions are likely in the [Accumulation/Manipulation/Distribution] phase. The [news event] on [day] will be used to [sweep which liquidity] before the move toward [target]."',
                          _s4Ctrl,
                          const Color(0xFF059669)),
                      const SizedBox(height: AppSpacing.md),
                      _ScenarioCard(saCtrl: _saCtrl, sbCtrl: _sbCtrl),
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
                          label: const Text('Save Pre-Week Narrative',
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

  Widget _field(TextEditingController ctrl, String label, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );

  Widget _stepCard(int n, String title, String guidance, String template, TextEditingController ctrl, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                border: Border(bottom: BorderSide(color: color.withOpacity(0.2)))),
            child: Row(
              children: [
                Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$n',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guidance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: color.withOpacity(0.15))),
                    child: Text(template, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic))),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Write your analysis...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(color: color, width: 1.5)),
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

class _LiquidityMapCard extends StatelessWidget {
  final List<LiquidityLevel> liqMap;
  final void Function(int, LiquidityLevel) onChanged;

  const _LiquidityMapCard({required this.liqMap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                border: Border(bottom: BorderSide(color: const Color(0xFFD97706).withOpacity(0.2)))),
            child: Row(
              children: [
                Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                const SizedBox(width: 10),
                const Text('Weekly Liquidity Map',
                    style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Type',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 2,
                        child: Text('Level',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: Text('Notes',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 8),
                ...liqMap.asMap().entries.map((e) => _LiqRow(index: e.key, item: e.value, onChanged: onChanged)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiqRow extends StatefulWidget {
  final int index;
  final LiquidityLevel item;
  final void Function(int, LiquidityLevel) onChanged;
  const _LiqRow({required this.index, required this.item, required this.onChanged});
  @override
  State<_LiqRow> createState() => _LiqRowState();
}

class _LiqRowState extends State<_LiqRow> {
  late TextEditingController _lvl, _notes;
  @override
  void initState() {
    super.initState();
    _lvl = TextEditingController(text: widget.item.level);
    _notes = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _lvl.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(widget.item.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _mini(_lvl, 'Price', (v) => widget.onChanged(widget.index, widget.item.copyWith(level: v)))),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: _mini(_notes, 'Notes', (v) => widget.onChanged(widget.index, widget.item.copyWith(notes: v)))),
        ],
      ),
    );
  }

  Widget _mini(TextEditingController c, String hint, ValueChanged<String> cb) => TextField(
        controller: c,
        onChanged: cb,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );
}

class _ScenarioCard extends StatelessWidget {
  final TextEditingController saCtrl, sbCtrl;
  const _ScenarioCard({required this.saCtrl, required this.sbCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 5 — The Two Scenarios',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Write both before the week starts. Do not add a third.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSpacing.md),
          _scenario(
              'Scenario A — Bullish/Bearish',
              '"If price [does what] at [level], the narrative confirms [direction] and I will look for entries on the [timeframe] targeting [level]."',
              saCtrl,
              AppColors.profit),
          const SizedBox(height: AppSpacing.md),
          _scenario(
              'Scenario B — Bullish/Bearish',
              '"If price [does what] at [level] first, the narrative shifts to [direction] and I will look for entries on the [timeframe] targeting [level]."',
              sbCtrl,
              AppColors.loss),
        ],
      ),
    );
  }

  Widget _scenario(String label, String hint, TextEditingController ctrl, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
      ]);
}
