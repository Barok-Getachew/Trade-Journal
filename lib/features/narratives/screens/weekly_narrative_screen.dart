import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/weekly_narrative.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/narrative_provider.dart';

class WeeklyNarrativeScreen extends ConsumerStatefulWidget {
  const WeeklyNarrativeScreen({super.key});
  @override
  ConsumerState<WeeklyNarrativeScreen> createState() => _State();
}

class _State extends ConsumerState<WeeklyNarrativeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true, _saving = false;

  final _instrCtrl = TextEditingController();
  final _newsCtrl = TextEditingController();
  final _s1Ctrl = TextEditingController();
  final _s2Ctrl = TextEditingController();
  final _s4Ctrl = TextEditingController();
  final _saCtrl = TextEditingController();
  final _sbCtrl = TextEditingController();
  final _reflScenarioCtrl = TextEditingController();
  final _reflDayCtrl = TextEditingController();
  final _reflCarryCtrl = TextEditingController();

  bool? _reflAmdCorrect;
  int _reflS5Count = 0;
  late DateTime _weekOf;
  List<LiquidityLevel> _liqMap = WeeklyNarrative.defaultLiquidityMap();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      _reflScenarioCtrl.text = existing.reflScenarioPlayed ?? '';
      _reflDayCtrl.text = existing.reflCleanestDay ?? '';
      _reflCarryCtrl.text = existing.reflCarryForward ?? '';
      _reflAmdCorrect = existing.reflAmdCorrect;
      _reflS5Count = existing.reflCompleteS5Count ?? 0;
      if (existing.liquidityMap.isNotEmpty) _liqMap = List.from(existing.liquidityMap);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_instrCtrl, _newsCtrl, _s1Ctrl, _s2Ctrl, _s4Ctrl, _saCtrl, _sbCtrl, _reflScenarioCtrl, _reflDayCtrl, _reflCarryCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
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
        'refl_scenario_played': _reflScenarioCtrl.text.trim(),
        'refl_amd_correct': _reflAmdCorrect,
        'refl_cleanest_day': _reflDayCtrl.text.trim(),
        'refl_complete_s5_count': _reflS5Count,
        'refl_carry_forward': _reflCarryCtrl.text.trim(),
      });
      ref.invalidate(thisWeekNarrativeProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✓'), backgroundColor: AppColors.profit));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.loss));
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Weekly Narrative', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          Text('Week of $weekStr', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
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
          tabs: const [Tab(text: '📅 Pre-Week'), Tab(text: '📊 Reflection')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: AppColors.primary,
        icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _PreWeekTab(instrCtrl: _instrCtrl, newsCtrl: _newsCtrl, s1Ctrl: _s1Ctrl, s2Ctrl: _s2Ctrl, s4Ctrl: _s4Ctrl, saCtrl: _saCtrl, sbCtrl: _sbCtrl, liqMap: _liqMap, onLiqChanged: (i, l) => setState(() => _liqMap[i] = l)),
              _ReflectionTab(scenarioCtrl: _reflScenarioCtrl, dayCtrl: _reflDayCtrl, carryCtrl: _reflCarryCtrl, amdCorrect: _reflAmdCorrect, s5Count: _reflS5Count, onAmdChanged: (v) => setState(() => _reflAmdCorrect = v), onCountChanged: (v) => setState(() => _reflS5Count = v)),
            ]),
    );
  }
}

// ── Pre-Week Tab ──────────────────────────────────────────────────────────────

class _PreWeekTab extends StatelessWidget {
  final TextEditingController instrCtrl, newsCtrl, s1Ctrl, s2Ctrl, s4Ctrl, saCtrl, sbCtrl;
  final List<LiquidityLevel> liqMap;
  final void Function(int, LiquidityLevel) onLiqChanged;

  const _PreWeekTab({required this.instrCtrl, required this.newsCtrl, required this.s1Ctrl, required this.s2Ctrl, required this.s4Ctrl, required this.saCtrl, required this.sbCtrl, required this.liqMap, required this.onLiqChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _field(instrCtrl, 'Primary Instrument', 'EUR/USD, XAU/USD...')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _field(newsCtrl, 'High Impact News This Week', 'NFP, CPI, FOMC...')),
            ]),
            const SizedBox(height: AppSpacing.md),
            _stepCard(1, 'COT & Macro Positioning', 'Where are institutions positioned heading into this week?',
                '"Hedge funds are currently [net long/short] on [instrument] and retail sentiment is [bullish/bearish], creating a [agreement/divergence] that suggests [institutional move]."', s1Ctrl, const Color(0xFF3D7EFF)),
            const SizedBox(height: AppSpacing.md),
            _stepCard(2, 'HTF Structure', 'What does the weekly/daily chart say about where price is going?',
                '"On the [Weekly/Daily], price has [broken structure/respected OB/swept liquidity] at [level] and the next significant draw is [level] because [why]."', s2Ctrl, const Color(0xFF7C3AED)),
            const SizedBox(height: AppSpacing.md),
            _LiquidityMapCard(liqMap: liqMap, onChanged: onLiqChanged),
            const SizedBox(height: AppSpacing.md),
            _stepCard(4, 'AMD Weekly Bias', 'How will institutions use this week\'s structure and news?',
                '"This week institutions are likely in the [Accumulation/Manipulation/Distribution] phase. The [news event] on [day] will be used to [sweep which liquidity] before the move toward [target]."', s4Ctrl, const Color(0xFF059669)),
            const SizedBox(height: AppSpacing.md),
            _ScenarioCard(saCtrl: saCtrl, sbCtrl: sbCtrl),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(labelText: label, hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      filled: true, fillColor: AppColors.surfaceElevated, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );

  Widget _stepCard(int n, String title, String guidance, String template, TextEditingController ctrl, Color color) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)), border: Border(bottom: BorderSide(color: color.withOpacity(0.2)))),
          child: Row(children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(color: color, shape: BoxShape.circle), alignment: Alignment.center, child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(guidance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: color.withOpacity(0.15))),
            child: Text(template, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic))),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: ctrl, maxLines: 4, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(hintText: 'Write your analysis...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12), filled: true, fillColor: AppColors.surfaceElevated, isDense: true, contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: BorderSide(color: color, width: 1.5)))),
        ])),
      ]),
    );
  }
}

// ── Liquidity Map Card ────────────────────────────────────────────────────────

class _LiquidityMapCard extends StatelessWidget {
  final List<LiquidityLevel> liqMap;
  final void Function(int, LiquidityLevel) onChanged;

  const _LiquidityMapCard({required this.liqMap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFD97706).withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)), border: Border(bottom: BorderSide(color: const Color(0xFFD97706).withOpacity(0.2)))),
          child: Row(children: [
            Container(width: 26, height: 26, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle), alignment: Alignment.center, child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
            const SizedBox(width: 10),
            const Text('Weekly Liquidity Map', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(children: [
          const Row(children: [
            Expanded(flex: 3, child: Text('Type', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Level', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            SizedBox(width: 8),
            Expanded(flex: 3, child: Text('Notes', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          ...liqMap.asMap().entries.map((e) => _LiqRow(index: e.key, item: e.value, onChanged: onChanged)),
        ])),
      ]),
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
  void dispose() { _lvl.dispose(); _notes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(flex: 3, child: Text(widget.item.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _mini(_lvl, 'Price', (v) => widget.onChanged(widget.index, widget.item.copyWith(level: v)))),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _mini(_notes, 'Notes', (v) => widget.onChanged(widget.index, widget.item.copyWith(notes: v)))),
      ]),
    );
  }

  Widget _mini(TextEditingController c, String hint, ValueChanged<String> cb) => TextField(
    controller: c, onChanged: cb,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11), filled: true, fillColor: AppColors.surfaceElevated, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))),
  );
}

// ── Scenario Card ─────────────────────────────────────────────────────────────

class _ScenarioCard extends StatelessWidget {
  final TextEditingController saCtrl, sbCtrl;
  const _ScenarioCard({required this.saCtrl, required this.sbCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Step 5 — The Two Scenarios', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Write both before the week starts. Do not add a third.', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
        const SizedBox(height: AppSpacing.md),
        _scenario('Scenario A — Bullish/Bearish', '"If price [does what] at [level], the narrative confirms [direction] and I will look for entries on the [timeframe] targeting [level]."', saCtrl, AppColors.profit),
        const SizedBox(height: AppSpacing.md),
        _scenario('Scenario B — Bullish/Bearish', '"If price [does what] at [level] first, the narrative shifts to [direction] and I will look for entries on the [timeframe] targeting [level]."', sbCtrl, AppColors.loss),
      ]),
    );
  }

  Widget _scenario(String label, String hint, TextEditingController ctrl, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    const SizedBox(height: 6),
    TextField(controller: ctrl, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11), filled: true, fillColor: AppColors.surfaceElevated, isDense: true, contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: BorderSide(color: color, width: 1.5)))),
  ]);
}

// ── Reflection Tab ────────────────────────────────────────────────────────────

class _ReflectionTab extends StatelessWidget {
  final TextEditingController scenarioCtrl, dayCtrl, carryCtrl;
  final bool? amdCorrect;
  final int s5Count;
  final ValueChanged<bool?> onAmdChanged;
  final ValueChanged<int> onCountChanged;

  const _ReflectionTab({required this.scenarioCtrl, required this.dayCtrl, required this.carryCtrl, required this.amdCorrect, required this.s5Count, required this.onAmdChanged, required this.onCountChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _banner(),
            const SizedBox(height: AppSpacing.md),
            _textQ('Which scenario played out?', 'Scenario A or B — describe what happened', scenarioCtrl, 2),
            const SizedBox(height: AppSpacing.md),
            _yesNoQ('Was the AMD phase correctly identified?', amdCorrect, onAmdChanged),
            const SizedBox(height: AppSpacing.md),
            _textQ('Which day had the cleanest setup?', 'Monday / Tuesday / Wednesday...', dayCtrl, 1),
            const SizedBox(height: AppSpacing.md),
            _counterQ('How many trades had complete Sentence 5 before entry?', s5Count, onCountChanged),
            const SizedBox(height: AppSpacing.md),
            _textQ('What is the ONE thing to carry into next week?', 'One lesson, one rule, one focus...', carryCtrl, 3),
          ]),
        ),
      ),
    );
  }

  Widget _banner() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    child: const Row(children: [
      Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 14),
      SizedBox(width: 10),
      Expanded(child: Text('Fill every Friday after close.', style: TextStyle(color: AppColors.primary, fontSize: 12))),
    ]),
  );

  Widget _textQ(String q, String hint, TextEditingController ctrl, int lines) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(q, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
    const SizedBox(height: 6),
    TextField(controller: ctrl, maxLines: lines, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12), filled: true, fillColor: AppColors.surfaceElevated, isDense: true, contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)))),
  ]);

  Widget _yesNoQ(String q, bool? val, ValueChanged<bool?> cb) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Expanded(child: Text(q, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
      const SizedBox(width: 12),
      _tog('Yes', true, AppColors.profit, val, cb),
      const SizedBox(width: 8),
      _tog('No', false, AppColors.loss, val, cb),
    ]),
  );

  Widget _tog(String label, bool target, Color color, bool? val, ValueChanged<bool?> cb) {
    final sel = val == target;
    return GestureDetector(
      onTap: () => cb(sel ? null : target),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: sel ? color.withOpacity(0.15) : AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? color : AppColors.border)),
        child: Text(label, style: TextStyle(color: sel ? color : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13))),
    );
  }

  Widget _counterQ(String q, int val, ValueChanged<int> cb) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Expanded(child: Text(q, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
      IconButton(icon: const Icon(Icons.remove_rounded), color: AppColors.textMuted, iconSize: 20, onPressed: val > 0 ? () => cb(val - 1) : null),
      Text('$val', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
      IconButton(icon: const Icon(Icons.add_rounded), color: AppColors.primary, iconSize: 20, onPressed: () => cb(val + 1)),
    ]),
  );
}
