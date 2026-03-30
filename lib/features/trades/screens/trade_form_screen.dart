import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../analytics/trade_analytics.dart';
import '../../../core/data/currency_pairs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/asset_class.dart';
import '../../../domain/enums/direction.dart';
import '../../../domain/enums/emotion_type.dart';
import '../../../domain/enums/market_condition.dart';
import '../../../domain/enums/session.dart';
import '../../../domain/models/trade.dart';
import '../../accounts/providers/account_provider.dart';
import '../../auth/providers/repository_providers.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/trades_provider.dart';

// ─── Form state ──────────────────────────────────────────────────────────────

class TradeFormState {
  final int step;
  // Pre-trade checklist (Step 0)
  final bool checkPlanMatch;
  final bool checkRiskOk;
  final bool checkRrOk;
  final bool checkConfirmation;
  final bool checkScreenshot;
  // Trade fields
  final String? accountId;
  final String symbol;
  final AssetClass assetClass;
  final TradeDirection direction;
  final String entryPrice;
  final String exitPrice;
  final String stopLoss;
  final String takeProfit;
  final String positionSize;
  final String commission;
  final DateTime entryAt;
  final DateTime exitAt;
  final String riskAmount;
  final String riskPct;
  final String? strategyId;
  final MarketCondition? marketCondition;
  final TradingSession? session;
  final bool newsDay;
  final int setupQuality;
  final EmotionType? emotionBefore;
  final EmotionType? emotionAfter;
  final int confidence;
  final bool rulesFollowed;
  final bool isImpulse;
  final String? mistakeType;
  final String reflection;
  final String? screenshotPath; // local file path (desktop)
  final Uint8List? screenshotBytes; // picked bytes (web/preview)
  final String? screenshotUrl; // remote URL (persisted)

  TradeFormState({
    this.step = 0,
    this.checkPlanMatch = false,
    this.checkRiskOk = false,
    this.checkRrOk = false,
    this.checkConfirmation = false,
    this.checkScreenshot = false,
    this.accountId,
    this.symbol = '',
    this.assetClass = AssetClass.forex,
    this.direction = TradeDirection.long,
    this.entryPrice = '',
    this.exitPrice = '',
    this.stopLoss = '',
    this.takeProfit = '',
    this.positionSize = '',
    this.commission = '0',
    DateTime? entryAt,
    DateTime? exitAt,
    this.riskAmount = '',
    this.riskPct = '',
    this.strategyId,
    this.marketCondition,
    this.session,
    this.newsDay = false,
    this.setupQuality = 3,
    this.emotionBefore,
    this.emotionAfter,
    this.confidence = 3,
    this.rulesFollowed = true,
    this.isImpulse = false,
    this.mistakeType,
    this.reflection = '',
    this.screenshotPath,
    this.screenshotBytes,
    this.screenshotUrl,
  })  : entryAt = entryAt ?? DateTime.now(),
        exitAt = exitAt ?? DateTime.now();

  TradeFormState copyWith({
    int? step,
    bool? checkPlanMatch,
    bool? checkRiskOk,
    bool? checkRrOk,
    bool? checkConfirmation,
    bool? checkScreenshot,
    String? symbol,
    AssetClass? assetClass,
    TradeDirection? direction,
    String? entryPrice,
    String? exitPrice,
    String? stopLoss,
    String? takeProfit,
    String? positionSize,
    String? commission,
    DateTime? entryAt,
    DateTime? exitAt,
    String? riskAmount,
    String? riskPct,
    String? accountId,
    String? strategyId,
    MarketCondition? marketCondition,
    TradingSession? session,
    bool? newsDay,
    int? setupQuality,
    EmotionType? emotionBefore,
    EmotionType? emotionAfter,
    int? confidence,
    bool? rulesFollowed,
    bool? isImpulse,
    String? mistakeType,
    String? reflection,
    Object? screenshotPath = _sentinel,
    Object? screenshotBytes = _sentinel,
    String? screenshotUrl,
  }) {
    return TradeFormState(
        step: step ?? this.step,
        checkPlanMatch: checkPlanMatch ?? this.checkPlanMatch,
        checkRiskOk: checkRiskOk ?? this.checkRiskOk,
        checkRrOk: checkRrOk ?? this.checkRrOk,
        checkConfirmation: checkConfirmation ?? this.checkConfirmation,
        checkScreenshot: checkScreenshot ?? this.checkScreenshot,
        symbol: symbol ?? this.symbol,
        assetClass: assetClass ?? this.assetClass,
        direction: direction ?? this.direction,
        entryPrice: entryPrice ?? this.entryPrice,
        exitPrice: exitPrice ?? this.exitPrice,
        stopLoss: stopLoss ?? this.stopLoss,
        takeProfit: takeProfit ?? this.takeProfit,
        positionSize: positionSize ?? this.positionSize,
        commission: commission ?? this.commission,
        entryAt: entryAt ?? this.entryAt,
        exitAt: exitAt ?? this.exitAt,
        riskAmount: riskAmount ?? this.riskAmount,
        riskPct: riskPct ?? this.riskPct,
        accountId: accountId ?? this.accountId,
        strategyId: strategyId ?? this.strategyId,
        marketCondition: marketCondition ?? this.marketCondition,
        session: session ?? this.session,
        newsDay: newsDay ?? this.newsDay,
        setupQuality: setupQuality ?? this.setupQuality,
        emotionBefore: emotionBefore ?? this.emotionBefore,
        emotionAfter: emotionAfter ?? this.emotionAfter,
        confidence: confidence ?? this.confidence,
        rulesFollowed: rulesFollowed ?? this.rulesFollowed,
        isImpulse: isImpulse ?? this.isImpulse,
        mistakeType: mistakeType ?? this.mistakeType,
        reflection: reflection ?? this.reflection,
        screenshotPath: identical(screenshotPath, _sentinel)
            ? this.screenshotPath
            : screenshotPath as String?,
        screenshotBytes: identical(screenshotBytes, _sentinel)
            ? this.screenshotBytes
            : screenshotBytes as Uint8List?,
        screenshotUrl: screenshotUrl ?? this.screenshotUrl);
  }
}

const _sentinel = Object();

class TradeFormNotifier extends StateNotifier<TradeFormState> {
  TradeFormNotifier() : super(TradeFormState());
  void update(TradeFormState s) => state = s;
  void next() => state = state.copyWith(step: state.step + 1);
  void prev() => state = state.copyWith(step: state.step - 1);

  void initFromTrade(Trade t, {required int step}) {
    state = TradeFormState(
      step: step,
      checkPlanMatch: t.planMatch,
      checkRiskOk: t.riskOk,
      checkRrOk: t.rrOk,
      checkConfirmation: t.confirmation,
      checkScreenshot: t.screenshotReady,
      accountId: t.accountId,
      symbol: t.symbol,
      assetClass: t.assetClass,
      direction: t.direction,
      entryPrice: t.entryPrice.toString(),
      exitPrice: t.exitPrice.toString(),
      stopLoss: t.stopLoss?.toString() ?? '',
      takeProfit: t.takeProfit?.toString() ?? '',
      positionSize: t.positionSize.toString(),
      commission: t.commission.toString(),
      entryAt: t.entryAt,
      exitAt: t.exitAt,
      riskAmount: t.riskAmount.toString(),
      riskPct: t.riskPct.toString(),
      strategyId: t.strategyId,
      marketCondition: t.marketCondition,
      session: t.session,
      newsDay: t.newsDay,
      setupQuality: t.setupQuality,
      emotionBefore: t.emotionBefore,
      emotionAfter: t.emotionAfter,
      confidence: t.confidence,
      rulesFollowed: t.rulesFollowed,
      isImpulse: t.isImpulse,
      mistakeType: t.mistakeType,
      reflection: t.reflection ?? '',
      screenshotPath: null, // We have the URL, not the local path
      screenshotBytes: null,
      screenshotUrl: t.screenshotUrl,
    );
  }
}

final tradeFormProvider =
    StateNotifierProvider.autoDispose<TradeFormNotifier, TradeFormState>(
        (_) => TradeFormNotifier());

// accountListProvider lives in features/accounts/providers/account_provider.dart

// ─── Validation ──────────────────────────────────────────────────────────────

String? _reqNum(String? v, String label) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  final n = double.tryParse(v.trim());
  if (n == null) return 'Enter a valid number';
  if (n <= 0) return '$label must be > 0';
  return null;
}

String? _optNum(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
  return null;
}

// ─── Shared UI helpers ───────────────────────────────────────────────────────

Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    );

Widget _numField({
  required String label,
  required String? hint,
  required String? Function(String?) validator,
  required void Function(String) onChanged,
  String? initialValue,
  String? prefixText,
}) =>
    TextFormField(
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      onChanged: onChanged,
      validator: validator,
    );

Widget _row2(Widget a, Widget b) => Row(children: [
      Expanded(child: a),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: b),
    ]);

SizedBox _gap([double h = 20]) => SizedBox(height: h);

// ─── Screen ──────────────────────────────────────────────────────────────────

class TradeFormScreen extends ConsumerStatefulWidget {
  final String? tradeId;
  const TradeFormScreen({super.key, this.tradeId});

  @override
  ConsumerState<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends ConsumerState<TradeFormScreen> {
  static const _steps = [
    'Pre-Trade Checklist',
    'Symbol & Direction',
    'Prices & Times',
    'Risk',
    'Context',
    'Psychology',
    'Reflection',
  ];
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.tradeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrade());
    }
  }

  Future<void> _loadTrade() async {
    try {
      final trade =
          await ref.read(tradeRepositoryProvider).fetchById(widget.tradeId!);
      if (trade != null && mounted) {
        ref.read(tradeFormProvider.notifier).initFromTrade(trade, step: 0);
      }
    } catch (e) {
      debugPrint('Error loading trade: $e');
    }
  }

  bool _validateStep(int step) =>
      _formKeys[step].currentState?.validate() ?? false;

  void _next() {
    final form = ref.read(tradeFormProvider);
    if (form.step == 0) {
      ref.read(tradeFormProvider.notifier).next();
      return;
    }
    if (_validateStep(form.step)) {
      ref.read(tradeFormProvider.notifier).next();
    }
  }

  Future<void> _submit() async {
    if (!_validateStep(6)) return;
    setState(() => _submitting = true);
    try {
      final f = ref.read(tradeFormProvider);
      final ep = double.parse(f.entryPrice);
      final xp = double.parse(f.exitPrice);
      final size = double.parse(f.positionSize);
      final comm = double.tryParse(f.commission) ?? 0;
      final risk = double.tryParse(f.riskAmount) ?? 0;
      final riskP = double.tryParse(f.riskPct) ?? 0;
      final sl = double.tryParse(f.stopLoss);
      final tp = double.tryParse(f.takeProfit);
      final gross = TradeAnalytics.grossPnl(
        entryPrice: ep,
        exitPrice: xp,
        positionSize: size,
        isLong: f.direction == TradeDirection.long,
      );
      final net = TradeAnalytics.netPnl(gross, comm);
      final rm = risk > 0 ? TradeAnalytics.rMultiple(net, risk) : 0.0;

      final accounts = await ref.read(accountRepositoryProvider).fetchAll();
      final accountId =
          f.accountId ?? (accounts.isNotEmpty ? accounts.first.id : '');

      // ── Risk Rules Validation ──────────────────────────────────────────────
      final rules =
          await ref.read(riskRuleRepositoryProvider).fetchForAccount(accountId);
      if (rules != null) {
        // 1. Check Risk Per Trade
        if (riskP > rules.maxRiskPerTrade) {
          final proceed = await _showRiskWarning(
            'Risk Rule Violation',
            'This trade blocks ${riskP.toStringAsFixed(2)}% of capital, which exceeds your ${rules.maxRiskPerTrade}% max risk per trade rule.',
          );
          if (!proceed) {
            setState(() => _submitting = false);
            return;
          }
        }

        // 2. Check Daily Trades
        final tradesToday = await ref.read(tradeRepositoryProvider).fetchAll(
              from: DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day),
            );
        final accountTradesToday =
            tradesToday.where((t) => t.accountId == accountId).length;
        if (accountTradesToday >= rules.maxTradesPerDay) {
          final proceed = await _showRiskWarning(
            'Overtrading Warning',
            'You have already logged $accountTradesToday trades today. Your daily limit is ${rules.maxTradesPerDay}.',
          );
          if (!proceed) {
            setState(() => _submitting = false);
            return;
          }
        }
      }

      // ── Screenshot Upload to Supabase Storage ─────────────────────────────
      String? screenshotUrl;
      if (f.screenshotBytes != null) {
        // Detect MIME type from magic bytes so it works even when the
        // filename extension is missing or wrong (common on web pickers).
        final bytes = f.screenshotBytes!;
        String mimeType = 'image/png';
        String ext = 'png';
        if (bytes.length >= 4) {
          if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
            mimeType = 'image/jpeg';
            ext = 'jpg';
          } else if (bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47) {
            mimeType = 'image/png';
            ext = 'png';
          } else if (bytes.length >= 12 &&
              bytes[8] == 0x57 &&
              bytes[9] == 0x45 &&
              bytes[10] == 0x42 &&
              bytes[11] == 0x50) {
            mimeType = 'image/webp';
            ext = 'webp';
          } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
            mimeType = 'image/gif';
            ext = 'gif';
          }
        }
        final fileName =
            'trades/${accountId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage
            .from('trade-screenshots')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                contentType: mimeType,
                upsert: true,
              ),
            );
        screenshotUrl = Supabase.instance.client.storage
            .from('trade-screenshots')
            .getPublicUrl(fileName);
      }

      final data = {
        'account_id': accountId,
        'strategy_id': f.strategyId,
        'symbol': f.symbol.toUpperCase(),
        'asset_class': f.assetClass.name,
        'direction': f.direction.name,
        'entry_price': ep,
        'exit_price': xp,
        'stop_loss': sl,
        'take_profit': tp,
        'position_size': size,
        'risk_amount': risk,
        'risk_pct': double.parse(riskP.toStringAsFixed(2)),
        'commission': comm,
        'entry_at': f.entryAt.toIso8601String(),
        'exit_at': f.exitAt.toIso8601String(),
        'balance_at_entry':
            accounts.isNotEmpty ? accounts.first.initialBalance : 10000.0,
        'gross_pnl': gross,
        'net_pnl': net,
        'r_multiple': rm,
        'market_condition': f.marketCondition?.name,
        'session': f.session?.name,
        'news_day': f.newsDay,
        'setup_quality': f.setupQuality,
        'emotion_before': f.emotionBefore?.name,
        'emotion_after': f.emotionAfter?.name,
        'confidence': f.confidence,
        'rules_followed': f.rulesFollowed,
        'is_impulse': f.isImpulse,
        'mistake_type': f.mistakeType,
        'reflection': f.reflection,
        'plan_match': f.checkPlanMatch,
        'risk_ok': f.checkRiskOk,
        'rr_ok': f.checkRrOk,
        'confirmation': f.checkConfirmation,
        'screenshot_ready': f.checkScreenshot,
        'screenshot_url': () {
          final url = screenshotUrl ?? f.screenshotUrl;
          return (url == null || url.isEmpty) ? null : url;
        }(),
      };

      if (widget.tradeId != null) {
        await ref.read(tradeRepositoryProvider).update(widget.tradeId!, data);
      } else {
        await ref.read(tradeRepositoryProvider).insert(data);
      }
      // Invalidate both providers so the list and dashboard refresh immediately
      ref.invalidate(filteredTradesProvider);
      ref.invalidate(allTradesProvider);
      if (mounted) context.go('/trades');
    } catch (e) {
      debugPrint('Save Error: $e');
      String message = e.toString();
      if (e is PostgrestException) {
        message = '${e.message}\n${e.details ?? ""}\n${e.hint ?? ""}'.trim();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $message'),
            backgroundColor: AppColors.loss,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Save Error Details'),
                    content: SingleChildScrollView(child: Text(e.toString())),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _showRiskWarning(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: AppColors.textPrimary)),
            ]),
            content: Text(msg,
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel Trade',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(tradeFormProvider);
    final notifier = ref.read(tradeFormProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(
              step: form.step,
              steps: _steps,
              isEdit: widget.tradeId != null,
              onClose: () => context.go('/trades')),
          LinearProgressIndicator(
            value: (form.step + 1) / _steps.length,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
          Expanded(
            child: Row(
              children: [
                _StepSidebar(currentStep: form.step, steps: _steps),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0.03, 0), end: Offset.zero)
                            .animate(anim),
                        child: child,
                      ),
                    ),
                    child: Form(
                      key: _formKeys[form.step],
                      child: _StepBody(
                        key: ValueKey(form.step),
                        child: _buildStep(form, notifier, form.step),
                      ),
                    ),
                  ),
                ),
                _PreviewPanel(form: form),
              ],
            ),
          ),
          _BottomNav(
            step: form.step,
            totalSteps: _steps.length,
            submitting: _submitting,
            isEdit: widget.tradeId != null,
            onBack: notifier.prev,
            onNext: _next,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(TradeFormState f, TradeFormNotifier n, int step) {
    return switch (step) {
      0 => _Step0Checklist(form: f, notifier: n),
      1 => _Step1Symbol(form: f, notifier: n),
      2 => _Step2Prices(form: f, notifier: n),
      3 => _Step3Risk(form: f, notifier: n),
      4 => _Step4Context(form: f, notifier: n),
      5 => _Step5Psychology(form: f, notifier: n),
      _ => _Step6Reflection(form: f, notifier: n),
    };
  }
}

// ─── Step 0: Pre-Trade Checklist ─────────────────────────────────────────────

class _Step0Checklist extends StatelessWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step0Checklist({required this.form, required this.notifier});

  static const _items = [
    (
      label: 'This setup is in my trading plan',
      field: 'planMatch',
    ),
    (
      label: 'Risk is within my daily limit',
      field: 'riskOk',
    ),
    (
      label: 'R:R meets my minimum ratio',
      field: 'rrOk',
    ),
    (
      label: 'I have a confirmation signal',
      field: 'confirmation',
    ),
    (
      label: 'Screenshot / chart is ready',
      field: 'screenshot',
    ),
  ];

  bool _getValue(String field) => switch (field) {
        'planMatch' => form.checkPlanMatch,
        'riskOk' => form.checkRiskOk,
        'rrOk' => form.checkRrOk,
        'confirmation' => form.checkConfirmation,
        _ => form.checkScreenshot,
      };

  void _toggle(String field, bool value) {
    switch (field) {
      case 'planMatch':
        notifier.update(form.copyWith(checkPlanMatch: value));
      case 'riskOk':
        notifier.update(form.copyWith(checkRiskOk: value));
      case 'rrOk':
        notifier.update(form.copyWith(checkRrOk: value));
      case 'confirmation':
        notifier.update(form.copyWith(checkConfirmation: value));
      default:
        notifier.update(form.copyWith(checkScreenshot: value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = form.checkPlanMatch &&
        form.checkRiskOk &&
        form.checkRrOk &&
        form.checkConfirmation &&
        form.checkScreenshot;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist_rounded,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pre-Trade Checklist',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text('All items must be confirmed before logging.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            // Checklist items
            ..._items.map((item) {
              final checked = _getValue(item.field);
              return GestureDetector(
                onTap: () => _toggle(item.field, !checked),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: checked
                        ? AppColors.profitDim
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: checked
                          ? AppColors.profit.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: checked ? AppColors.profit : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              checked ? AppColors.profit : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: checked
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: checked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight:
                              checked ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),
            // Status badge
            AnimatedOpacity(
              opacity: allChecked ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.profitDim,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.profit.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.profit, size: 18),
                  SizedBox(width: 8),
                  Text('All checks passed — ready to log the trade',
                      style: TextStyle(
                          color: AppColors.profit,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int step;
  final List<String> steps;
  final bool isEdit;
  final VoidCallback onClose;
  const _TopBar(
      {required this.step,
      required this.steps,
      required this.isEdit,
      required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              onPressed: onClose,
              tooltip: 'Cancel'),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Trade' : 'New Trade',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const Spacer(),
          Text('Step ${step + 1} of ${steps.length} — ${steps[step]}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: AppSpacing.lg),
        ]),
      );
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _StepSidebar extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepSidebar({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.border))),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: steps.asMap().entries.map((e) {
            final done = e.key < currentStep;
            final active = e.key == currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryDim : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.profit
                        : active
                            ? AppColors.primary
                            : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 13, color: Colors.white)
                        : Text('${e.key + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textMuted)),
                  ),
                ),
                title: Text(e.value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? AppColors.primary
                            : done
                                ? AppColors.textPrimary
                                : AppColors.textMuted)),
              ),
            );
          }).toList(),
        ),
      );
}

class _StepBody extends StatelessWidget {
  final Widget child;
  const _StepBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: child)),
        ),
      );
}

// ─── Preview panel ────────────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final TradeFormState form;
  const _PreviewPanel({required this.form});

  @override
  Widget build(BuildContext context) {
    final ep = double.tryParse(form.entryPrice) ?? 0;
    final xp = double.tryParse(form.exitPrice) ?? 0;
    final size = double.tryParse(form.positionSize) ?? 0;
    final comm = double.tryParse(form.commission) ?? 0;
    final risk = double.tryParse(form.riskAmount) ?? 0;
    final sl = double.tryParse(form.stopLoss) ?? 0;
    final tp = double.tryParse(form.takeProfit) ?? 0;
    final gross = ep > 0 && xp > 0 && size > 0
        ? TradeAnalytics.grossPnl(
            entryPrice: ep,
            exitPrice: xp,
            positionSize: size,
            isLong: form.direction == TradeDirection.long)
        : 0.0;
    final net = TradeAnalytics.netPnl(gross, comm);
    final rm = risk > 0 ? TradeAnalytics.rMultiple(net, risk) : 0.0;
    final rr = ep > 0 && sl > 0 && tp > 0
        ? TradeAnalytics.riskReward(entry: ep, sl: sl, tp: tp)
        : 0.0;

    return Container(
      width: 210,
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PREVIEW',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.md),
        if (form.symbol.isNotEmpty) ...[
          Text(form.symbol.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: 4),
          Row(children: [
            _badge(
                form.direction == TradeDirection.long ? 'LONG' : 'SHORT',
                form.direction == TradeDirection.long
                    ? AppColors.profit
                    : AppColors.loss),
            const SizedBox(width: 6),
            _badge(form.assetClass.label, AppColors.primary),
          ]),
        ],
        const Divider(color: AppColors.border, height: 20),
        _pRow('Entry', ep > 0 ? Fmt.price(ep) : '—'),
        _pRow('Exit', xp > 0 ? Fmt.price(xp) : '—'),
        _pRow('Size', size > 0 ? size.toString() : '—'),
        if (sl > 0) _pRow('Stop Loss', Fmt.price(sl)),
        if (tp > 0) _pRow('Take Profit', Fmt.price(tp)),
        const Divider(color: AppColors.border, height: 20),
        _pRow('Gross P&L', gross != 0 ? Fmt.currency(gross) : '—',
            color: gross >= 0 ? AppColors.profit : AppColors.loss),
        _pRow('Net P&L', net != 0 ? Fmt.currency(net) : '—',
            color: net >= 0 ? AppColors.profit : AppColors.loss),
        _pRow('R-Multiple', rm != 0 ? Fmt.rMultiple(rm) : '—',
            color: rm >= 0 ? AppColors.profit : AppColors.loss),
        if (rr > 0) _pRow('Risk:Reward', '1:${rr.toStringAsFixed(2)}'),
        const Spacer(),
        if (!form.rulesFollowed) _badge('✗ Rules Broken', AppColors.loss),
        if (form.isImpulse) ...[
          const SizedBox(height: 6),
          _badge('⚠ Impulse', AppColors.warning)
        ],
      ]),
    );
  }

  Widget _pRow(String l, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(v,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int step, totalSteps;
  final bool submitting, isEdit;
  final VoidCallback onBack, onNext, onSubmit;
  const _BottomNav(
      {required this.step,
      required this.totalSteps,
      required this.submitting,
      required this.isEdit,
      required this.onBack,
      required this.onNext,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          if (step > 0)
            OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 15),
                label: const Text('Back'),
                onPressed: onBack),
          const Spacer(),
          if (step < totalSteps - 1)
            ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Continue'),
                onPressed: onNext)
          else
            ElevatedButton.icon(
              icon: submitting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 15),
              label: Text(isEdit ? 'Update Trade' : 'Save Trade'),
              onPressed: submitting ? null : onSubmit,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.profit),
            ),
        ]),
      );
}

// ─── Step 1: Symbol & Direction ───────────────────────────────────────────────

class _Step1Symbol extends ConsumerWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step1Symbol({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Trading Account'),
        accountsAsync.when(
          data: (list) => DropdownButtonFormField<String>(
            value: form.accountId ?? (list.isNotEmpty ? list.first.id : null),
            decoration: const InputDecoration(hintText: 'Select Account'),
            items: list
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                .toList(),
            onChanged: (v) => notifier.update(form.copyWith(accountId: v)),
            validator: (v) => v == null ? 'Select an account' : null,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Error loading accounts'),
        ),
        _gap(),
        _sectionTitle('Symbol / Asset'),
        Autocomplete<String>(
          optionsBuilder: (v) {
            if (v.text.isEmpty) return const Iterable<String>.empty();
            return CurrencyPairs.all
                .where((s) => s.contains(v.text.toUpperCase()));
          },
          onSelected: (s) => notifier.update(form.copyWith(symbol: s)),
          fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) {
            if (ctrl.text.isEmpty && form.symbol.isNotEmpty) {
              ctrl.text = form.symbol;
            }
            return TextFormField(
              controller: ctrl,
              focusNode: focus,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. EURUSD, GOLD, BTC',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => notifier.update(form.copyWith(symbol: v)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            );
          },
        ),
        _gap(),
        _sectionTitle('Asset Class'),
        Wrap(
          spacing: 10,
          children: AssetClass.values.map((c) {
            final active = form.assetClass == c;
            return ChoiceChip(
              label: Text(c.label),
              selected: active,
              onSelected: (_) => notifier.update(form.copyWith(assetClass: c)),
            );
          }).toList(),
        ),
        _gap(),
        _sectionTitle('Direction'),
        Row(children: [
          Expanded(
            child: _DirectionCard(
              label: 'LONG',
              desc: 'Buy for profit',
              icon: Icons.trending_up_rounded,
              color: AppColors.profit,
              active: form.direction == TradeDirection.long,
              onTap: () => notifier
                  .update(form.copyWith(direction: TradeDirection.long)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _DirectionCard(
              label: 'SHORT',
              desc: 'Sell for profit',
              icon: Icons.trending_down_rounded,
              color: AppColors.loss,
              active: form.direction == TradeDirection.short,
              onTap: () => notifier
                  .update(form.copyWith(direction: TradeDirection.short)),
            ),
          ),
        ]),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border:
              Border.all(color: active ? color : AppColors.border, width: 2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? color : AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: active ? color : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ─── Step 2: Prices & Times ───────────────────────────────────────────────────

class _Step2Prices extends StatelessWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step2Prices({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final f = form;
    final n = notifier;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Entry & Exit Price'),
      _row2(
        _numField(
            label: 'Entry Price',
            hint: '1.08500',
            initialValue: f.entryPrice,
            validator: (v) => _reqNum(v, 'Entry price'),
            onChanged: (v) => n.update(f.copyWith(entryPrice: v))),
        _numField(
            label: 'Exit Price',
            hint: '1.09000',
            initialValue: f.exitPrice,
            validator: (v) => _reqNum(v, 'Exit price'),
            onChanged: (v) => n.update(f.copyWith(exitPrice: v))),
      ),
      _gap(),
      _sectionTitle('Date & Time'),
      _row2(
        _DateTimeField(
            label: 'Entry Time',
            value: f.entryAt,
            validator: (_) => null,
            onChanged: (dt) => n.update(f.copyWith(entryAt: dt))),
        _DateTimeField(
            label: 'Exit Time',
            value: f.exitAt,
            validator: (_) => f.exitAt.isBefore(f.entryAt)
                ? 'Exit must be after entry'
                : null,
            onChanged: (dt) {
              if (!dt.isBefore(f.entryAt)) n.update(f.copyWith(exitAt: dt));
            }),
      ),
      _gap(),
      _sectionTitle('Position'),
      _row2(
        _numField(
            label: 'Position Size',
            hint: '1.00',
            initialValue: f.positionSize,
            validator: (v) => _reqNum(v, 'Position size'),
            onChanged: (v) => n.update(f.copyWith(positionSize: v))),
        _numField(
            label: 'Commission / Spread',
            hint: '0.00',
            initialValue: f.commission,
            validator: _optNum,
            onChanged: (v) => n.update(f.copyWith(commission: v))),
      ),
      _gap(),
      _sectionTitle('Price Levels (optional)'),
      _row2(
        _numField(
            label: 'Stop Loss',
            hint: '1.07800',
            initialValue: f.stopLoss,
            validator: _optNum,
            onChanged: (v) => n.update(f.copyWith(stopLoss: v))),
        _numField(
            label: 'Take Profit',
            hint: '1.09500',
            initialValue: f.takeProfit,
            validator: _optNum,
            onChanged: (v) => n.update(f.copyWith(takeProfit: v))),
      ),
    ]);
  }
}

// ─── Step 3: Risk ─────────────────────────────────────────────────────────────

class _Step3Risk extends StatelessWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step3Risk({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final f = form;
    final n = notifier;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Risk Parameters'),
      _row2(
        _numField(
            label: 'Risk Amount',
            hint: '100.00',
            prefixText: '\$ ',
            initialValue: f.riskAmount,
            validator: (v) => _reqNum(v, 'Risk amount'),
            onChanged: (v) => n.update(f.copyWith(riskAmount: v))),
        _numField(
            label: 'Risk % of Account',
            hint: '1.0',
            prefixText: '% ',
            initialValue: f.riskPct,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final d = double.tryParse(v);
              if (d == null) return 'Invalid';
              if (d < 0 || d > 100) return 'Must be 0–100';
              return null;
            },
            onChanged: (v) => n.update(f.copyWith(riskPct: v))),
      ),
      _gap(),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Risk Discipline Rules',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final rule in [
            'Never risk more than 2% per trade',
            'Minimum 1:2 risk-to-reward ratio',
            'Always define stop loss before entry'
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: AppColors.profit),
                const SizedBox(width: 6),
                Text(rule,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// ─── Step 4: Context ──────────────────────────────────────────────────────────

class _Step4Context extends StatelessWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step4Context({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final f = form;
    final n = notifier;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Market Condition'),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MarketCondition.values.map((mc) {
            final sel = f.marketCondition == mc;
            return ChoiceChip(
                label: Text(mc.label),
                selected: sel,
                onSelected: (_) => n.update(f.copyWith(marketCondition: mc)),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary));
          }).toList()),
      _gap(),
      _sectionTitle('Trading Session'),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TradingSession.values.map((s) {
            final sel = f.session == s;
            return ChoiceChip(
                label: Text(s.label),
                selected: sel,
                onSelected: (_) => n.update(f.copyWith(session: s)),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary));
          }).toList()),
      _gap(),
      _sectionTitle('Setup Quality'),
      _StarRating(
          value: f.setupQuality,
          onChanged: (v) => n.update(f.copyWith(setupQuality: v))),
      _gap(),
      SwitchListTile(
        title: const Text('High-Impact News Day',
            style: TextStyle(color: AppColors.textPrimary)),
        subtitle: const Text('Major news events occurring during this trade',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        value: f.newsDay,
        activeColor: AppColors.warning,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => n.update(f.copyWith(newsDay: v)),
      ),
    ]);
  }
}

// ─── Step 5: Psychology ───────────────────────────────────────────────────────

class _Step5Psychology extends StatelessWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step5Psychology({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final f = form;
    final n = notifier;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Pre / Post Trade Emotions'),
      _row2(
        _EmotionDropdown(
            label: 'Emotion Before',
            value: f.emotionBefore,
            onChanged: (e) => n.update(f.copyWith(emotionBefore: e))),
        _EmotionDropdown(
            label: 'Emotion After',
            value: f.emotionAfter,
            onChanged: (e) => n.update(f.copyWith(emotionAfter: e))),
      ),
      _gap(),
      _sectionTitle('Confidence Level (1–5)'),
      _StarRating(
          value: f.confidence,
          onChanged: (v) => n.update(f.copyWith(confidence: v))),
      _gap(),
      SwitchListTile(
        title: const Text('Rules Followed',
            style: TextStyle(color: AppColors.textPrimary)),
        subtitle: const Text('I followed my trading plan exactly',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        value: f.rulesFollowed,
        activeColor: AppColors.profit,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => n.update(f.copyWith(rulesFollowed: v)),
      ),
      SwitchListTile(
        title: const Text('Impulse Trade',
            style: TextStyle(color: AppColors.textPrimary)),
        subtitle: const Text('Entered without meeting my setup criteria',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        value: f.isImpulse,
        activeColor: AppColors.warning,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => n.update(f.copyWith(isImpulse: v)),
      ),
      if (!f.rulesFollowed || f.isImpulse) ...[
        _gap(),
        _sectionTitle('Mistake Category'),
        DropdownButtonFormField<String>(
          value: f.mistakeType,
          decoration: const InputDecoration(
              labelText: 'What went wrong?',
              labelStyle: TextStyle(color: AppColors.textSecondary)),
          dropdownColor: AppColors.surfaceElevated,
          style: const TextStyle(color: AppColors.textPrimary),
          isExpanded: true,
          items: const [
            'Early entry',
            'Late entry',
            'Moved stop loss',
            'Took profit early',
            'Overtraded',
            'Against the trend',
            'FOMO entry',
            'Revenge trade',
            'Oversized position',
            'No stop loss',
            'Ignored setup rules',
            'Missed entry'
          ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => n.update(f.copyWith(mistakeType: v)),
        ),
      ],
    ]);
  }
}

// ─── Step 6: Reflection ───────────────────────────────────────────────────────

class _Step6Reflection extends StatefulWidget {
  final TradeFormState form;
  final TradeFormNotifier notifier;
  const _Step6Reflection({required this.form, required this.notifier});

  @override
  State<_Step6Reflection> createState() => _Step6ReflectionState();
}

class _Step6ReflectionState extends State<_Step6Reflection> {
  bool _pickingFile = false;

  Future<void> _pickScreenshot() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // critical for web — gets bytes
        dialogTitle: 'Select chart screenshot',
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final bytes = file.bytes;
        if (bytes != null) {
          widget.notifier.update(
            widget.form.copyWith(
              screenshotPath: file.name,
              screenshotBytes: bytes,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;
    final n = widget.notifier;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Post-Trade Reflection'),
      TextFormField(
        initialValue: f.reflection,
        maxLines: 6,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText:
              'What happened? What did you do well?\nWhat would you do differently? Lessons learned?',
          alignLabelWithHint: true,
          labelStyle: TextStyle(color: AppColors.textSecondary),
        ),
        onChanged: (v) => n.update(f.copyWith(reflection: v)),
      ),
      _gap(),
      // ── Screenshot Upload ──────────────────────────────────────────────────
      _sectionTitle('Chart Screenshot  (optional)'),
      const SizedBox(height: 8),
      if (f.screenshotBytes == null &&
          (f.screenshotUrl == null || f.screenshotUrl!.isEmpty)) ...[
        // No image at all — show upload button
        OutlinedButton.icon(
          onPressed: _pickingFile ? null : _pickScreenshot,
          icon: _pickingFile
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(_pickingFile ? 'Selecting…' : 'Upload Chart Screenshot'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ] else ...[
        // Image selected — show preview
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header with Change/Remove buttons
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusMd),
                    topRight: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.image_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.screenshotBytes != null
                          ? (f.screenshotPath ?? 'screenshot.png')
                          : 'Existing chart screenshot',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Change button
                  TextButton.icon(
                    icon: _pickingFile
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: Text(_pickingFile ? '…' : 'Change',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: _pickingFile ? null : _pickScreenshot,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                  // Remove — clears both bytes AND url
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () => n.update(f.copyWith(
                        screenshotPath: null,
                        screenshotBytes: null,
                        screenshotUrl: '')),
                    tooltip: 'Remove screenshot',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ]),
              ),
              // Actual image preview
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusMd),
                  bottomRight: Radius.circular(AppSpacing.radiusMd),
                ),
                child: f.screenshotBytes != null
                    ? Image.memory(
                        f.screenshotBytes!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Preview not available',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : Image.network(
                        f.screenshotUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Could not load image',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
      _gap(),
      // ── Trade Summary ──────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TRADE SUMMARY',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _revRow('Symbol', f.symbol.isNotEmpty ? f.symbol.toUpperCase() : '—'),
          _revRow('Direction',
              f.direction == TradeDirection.long ? 'LONG ▲' : 'SHORT ▼'),
          _revRow('Entry → Exit',
              '${f.entryPrice.isNotEmpty ? f.entryPrice : "—"} → ${f.exitPrice.isNotEmpty ? f.exitPrice : "—"}'),
          _revRow('Risk Amount',
              f.riskAmount.isNotEmpty ? '\$${f.riskAmount}' : '—'),
          _revRow('Rules Followed', f.rulesFollowed ? '✓ Yes' : '✗ No'),
          _revRow('Impulse Trade', f.isImpulse ? '⚠ Yes' : 'No'),
          if (f.emotionBefore != null)
            _revRow('Emotion', f.emotionBefore!.label),
        ]),
      ),
    ]);
  }

  Widget _revRow(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12))),
          Text(val,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        ]),
      );
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  static const _labels = ['Poor', 'Below Avg', 'Average', 'Good', 'Excellent'];
  const _StarRating({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
        ...List.generate(
            5,
            (i) => GestureDetector(
                  onTap: () => onChanged(i + 1),
                  child: Icon(
                      i < value
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          i < value ? AppColors.warning : AppColors.textMuted,
                      size: 28),
                )),
        const SizedBox(width: 8),
        Text(_labels[(value - 1).clamp(0, 4)],
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]);
}

class _EmotionDropdown extends StatelessWidget {
  final String label;
  final EmotionType? value;
  final ValueChanged<EmotionType?> onChanged;
  const _EmotionDropdown(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<EmotionType>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textSecondary)),
        dropdownColor: AppColors.surfaceElevated,
        style: const TextStyle(color: AppColors.textPrimary),
        items: EmotionType.values
            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
            .toList(),
        onChanged: onChanged,
      );
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(String?)? validator;
  const _DateTimeField(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.validator});

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(hours: 1)),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFF3D7EFF))),
          child: child!),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFF3D7EFF))),
          child: child!),
    );
    if (time == null) return;
    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final display =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}  ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: display),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        suffixIcon: const Icon(Icons.calendar_month_outlined,
            size: 16, color: AppColors.textSecondary),
      ),
      onTap: () => _pick(context),
    );
  }
}
