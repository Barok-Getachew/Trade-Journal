import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/risk_rule.dart';
import '../../accounts/providers/account_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/repository_providers.dart';
import '../providers/risk_rules_provider.dart';

class RiskRulesScreen extends ConsumerStatefulWidget {
  const RiskRulesScreen({super.key});

  @override
  ConsumerState<RiskRulesScreen> createState() => _RiskRulesScreenState();
}

class _RiskRulesScreenState extends ConsumerState<RiskRulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dailyLoss = TextEditingController(text: '2.0');
  final _weeklyLoss = TextEditingController(text: '5.0');
  final _maxTrades = TextEditingController(text: '3');
  final _maxRisk = TextEditingController(text: '1.0');
  final _minRR = TextEditingController(text: '1.5');
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRules());
  }

  Future<void> _loadRules() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      setState(() => _loaded = true);
      return;
    }
    final rule =
        await ref.read(riskRuleRepositoryProvider).fetchForAccount(account.id);
    if (rule != null && mounted) {
      setState(() {
        _dailyLoss.text = rule.maxDailyLossPct.toString();
        _weeklyLoss.text = rule.maxWeeklyLossPct.toString();
        _maxTrades.text = rule.maxTradesPerDay.toString();
        _maxRisk.text = rule.maxRiskPerTrade.toString();
        _minRR.text = rule.minRrRatio.toString();
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _dailyLoss.dispose();
    _weeklyLoss.dispose();
    _maxTrades.dispose();
    _maxRisk.dispose();
    _minRR.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an account first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
      final rule = RiskRule(
        id: '',
        userId: userId,
        accountId: account.id,
        maxDailyLossPct: double.parse(_dailyLoss.text),
        maxWeeklyLossPct: double.parse(_weeklyLoss.text),
        maxTradesPerDay: int.parse(_maxTrades.text),
        maxRiskPerTrade: double.parse(_maxRisk.text),
        minRrRatio: double.parse(_minRR.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(riskRuleRepositoryProvider).upsert(rule);
      ref.invalidate(riskRulesProvider(account.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risk rules saved ✓'),
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
    final account = ref.watch(selectedAccountProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(children: [
                          const Icon(Icons.security_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.md),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Risk Rules',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700)),
                              Text('Discipline enforcement parameters',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ]),
                        if (account == null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.warningDim,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Row(children: [
                              Icon(Icons.warning_rounded,
                                  color: AppColors.warning),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Select an account from the dashboard to configure its risk rules.',
                                    style: TextStyle(color: AppColors.warning)),
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        // Loss Limits
                        _sectionHeader('Loss Limits'),
                        const SizedBox(height: AppSpacing.md),
                        Row(children: [
                          Expanded(
                            child: _ruleField(
                              ctrl: _dailyLoss,
                              label: 'Max Daily Loss %',
                              hint: '2.0',
                              suffix: '%',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _ruleField(
                              ctrl: _weeklyLoss,
                              label: 'Max Weekly Loss %',
                              hint: '5.0',
                              suffix: '%',
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        // Trade Limits
                        _sectionHeader('Trade Limits'),
                        const SizedBox(height: AppSpacing.md),
                        Row(children: [
                          Expanded(
                            child: _ruleField(
                              ctrl: _maxTrades,
                              label: 'Max Trades / Day',
                              hint: '3',
                              isInt: true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _ruleField(
                              ctrl: _maxRisk,
                              label: 'Max Risk / Trade %',
                              hint: '1.0',
                              suffix: '%',
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        // R:R Minimum
                        _sectionHeader('Risk:Reward Minimum'),
                        const SizedBox(height: AppSpacing.md),
                        _ruleField(
                          ctrl: _minRR,
                          label: 'Minimum R:R Ratio',
                          hint: '1.5',
                          prefix: '1:',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Explanation card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('How rules are enforced',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              SizedBox(height: 8),
                              Text(
                                '• Violations are logged to your discipline audit trail\n'
                                '• Dashboard shows red warning banners for active violations\n'
                                '• Trades submitted beyond daily loss limit are flagged\n'
                                '• Pre-trade checklist verifies R:R before each trade',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.6),
                              ),
                            ],
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
                                : const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save Risk Rules'),
                            onPressed:
                                (_saving || account == null) ? null : _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15),
      );

  Widget _ruleField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    String? suffix,
    String? prefix,
    bool isInt = false,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: isInt
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              isInt ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'))
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          prefixText: prefix,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (isInt) {
            if (int.tryParse(v) == null) return 'Enter a number';
          } else {
            if (double.tryParse(v) == null) return 'Enter a number';
          }
          return null;
        },
      );
}
