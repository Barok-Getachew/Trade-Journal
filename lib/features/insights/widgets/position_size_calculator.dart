import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../dashboard/providers/dashboard_provider.dart';

/// Opens the Position Size Calculator as a modal bottom sheet.
Future<void> showPositionSizeCalculator(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PositionSizeSheet(),
  );
}

class _PositionSizeSheet extends ConsumerStatefulWidget {
  const _PositionSizeSheet();

  @override
  ConsumerState<_PositionSizeSheet> createState() =>
      _PositionSizeSheetState();
}

class _PositionSizeSheetState extends ConsumerState<_PositionSizeSheet> {
  final _balanceCtrl = TextEditingController();
  final _riskPctCtrl = TextEditingController(text: '1.0');
  final _stopDistCtrl = TextEditingController();
  final _pipValueCtrl = TextEditingController(text: '10.0');

  bool _useForexMode = true; // false = generic (stop in $)

  @override
  void initState() {
    super.initState();
    // Pre-fill balance from current account
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final balanceAsync = ref.read(currentBalanceProvider);
      balanceAsync.whenData((bal) {
        _balanceCtrl.text = bal.current.toStringAsFixed(0);
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _riskPctCtrl.dispose();
    _stopDistCtrl.dispose();
    _pipValueCtrl.dispose();
    super.dispose();
  }

  double get _balance => double.tryParse(_balanceCtrl.text) ?? 0;
  double get _riskPct => double.tryParse(_riskPctCtrl.text) ?? 1;
  double get _stopDist => double.tryParse(_stopDistCtrl.text) ?? 0;
  double get _pipValue => double.tryParse(_pipValueCtrl.text) ?? 10;

  double get _riskAmount => _balance * _riskPct / 100;

  double get _positionSize {
    if (_stopDist <= 0) return 0;
    if (_useForexMode) {
      // lots = riskAmount / (stopPips × pipValuePerLot)
      return _riskAmount / (_stopDist * _pipValue);
    } else {
      // units = riskAmount / stopDistance($)
      return _riskAmount / _stopDist;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final size = _positionSize;
    final riskOk = _riskPct <= 2;

    return Container(
      margin: EdgeInsets.only(
        left: isMobile ? 0 : 80,
        right: isMobile ? 0 : 80,
        bottom: isMobile ? 0 : 40,
        top: 40,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(AppSpacing.radiusXl),
          bottom: isMobile
              ? Radius.zero
              : const Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, -8))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Position Size Calculator',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('Risk-based lot size calculator',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border),
          // Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Text('Mode:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                _ModeChip(
                  label: '📈 Forex (Pips)',
                  selected: _useForexMode,
                  onTap: () => setState(() => _useForexMode = true),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: '📊 Generic (\$)',
                  selected: !_useForexMode,
                  onTap: () => setState(() => _useForexMode = false),
                ),
              ],
            ),
          ),
          // Inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CalcField(
                        controller: _balanceCtrl,
                        label: 'Account Balance',
                        prefix: '\$',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CalcField(
                        controller: _riskPctCtrl,
                        label: 'Risk %',
                        suffix: '%',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _CalcField(
                        controller: _stopDistCtrl,
                        label: _useForexMode ? 'Stop Loss (Pips)' : 'Stop Loss (\$)',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_useForexMode) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CalcField(
                          controller: _pipValueCtrl,
                          label: 'Pip Value (\$/lot)',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Results panel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primaryDim.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ResultTile(
                    label: 'Risk Amount',
                    value: '\$${_riskAmount.toStringAsFixed(2)}',
                    color: riskOk ? AppColors.profit : AppColors.warning,
                    note: riskOk ? null : '> 2% — High Risk',
                  ),
                ),
                Container(
                    width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _ResultTile(
                    label: _useForexMode ? 'Lot Size' : 'Units',
                    value: _useForexMode
                        ? size.toStringAsFixed(2)
                        : size.toStringAsFixed(0),
                    color: AppColors.primary,
                    note: _useForexMode && size > 0
                        ? '${(size * 100000).toStringAsFixed(0)} units'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Risk warning
          if (_riskPct > 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningDim,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Risking more than 2% per trade significantly increases account blow-up risk.',
                        style: TextStyle(
                            color: AppColors.warning, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _CalcField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String> onChanged;

  const _CalcField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        prefixText: prefix,
        suffixText: suffix,
        prefixStyle: const TextStyle(color: AppColors.textMuted),
        suffixStyle: const TextStyle(color: AppColors.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: AppColors.surfaceElevated,
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
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? note;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          if (note != null)
            Text(note!,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
