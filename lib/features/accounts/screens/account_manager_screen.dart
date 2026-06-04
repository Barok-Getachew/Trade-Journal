import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/account_type.dart';
import '../../../domain/models/account.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../auth/providers/repository_providers.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/account_provider.dart';

class AccountManagerScreen extends ConsumerWidget {
  const AccountManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onAdd: () => _showAccountForm(context, ref, null)),
          Expanded(
            child: accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.loss))),
              data: (accounts) {
                if (accounts.isEmpty) return const _EmptyState();
                final balancesAsync = ref.watch(accountCurrentBalancesProvider);
                final balances = balancesAsync.value ?? {};
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => _AccountTile(
                    account: accounts[i],
                    currentBalance: balances[accounts[i].id],
                    onEdit: () => _showAccountForm(ctx, ref, accounts[i]),
                    onArchive: () async {
                      await ref
                          .read(accountRepositoryProvider)
                          .archive(accounts[i].id);
                      ref.invalidate(accountListProvider);
                    },
                    onDelete: () async {
                      final confirm = await _confirmDelete(ctx);
                      if (confirm == true) {
                        await ref
                            .read(accountRepositoryProvider)
                            .delete(accounts[i].id);
                        ref.invalidate(accountListProvider);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx) => showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Account',
              style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'This will permanently delete the account and ALL its trades.\nThis cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.loss),
                child: const Text('Delete')),
          ],
        ),
      );

  Future<void> _showAccountForm(
      BuildContext ctx, WidgetRef ref, Account? existing) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AccountFormSheet(existing: existing, ref: ref),
    );
    ref.invalidate(accountListProvider);
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          const Text('Trading Accounts',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.compare_arrows_rounded, size: 16),
            label: const Text('Compare'),
            onPressed: () => context.push('/accounts/compare'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Account'),
            onPressed: onAdd,
          ),
        ]),
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_rounded,
                size: 56, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text('No accounts yet',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.sm),
            Text('Add your first trading account to get started.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

// ── Account tile ───────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final Account account;
  final double? currentBalance;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  const _AccountTile({
    required this.account,
    this.currentBalance,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  bool get _isBlown =>
      currentBalance != null &&
      currentBalance! <= 0 &&
      account.initialBalance > 0;

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (account.accountType) {
      AccountType.live => AppColors.profit,
      AccountType.funded => AppColors.primary,
      AccountType.demo => AppColors.textMuted,
    };
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        // Account type indicator
        Container(
          width: 4,
          height: 56,
          decoration: BoxDecoration(
            color: typeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(account.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(width: 8),
                _badge(account.accountType.badgeLabel, typeColor),
                if (_isBlown) ...[
                  const SizedBox(width: 6),
                  _badge('BLOWN', AppColors.loss),
                ],
              ]),
              const SizedBox(height: 4),
              Text(
                '${account.broker ?? 'No broker'} · ${account.currency} · '
                '1:${account.leverage}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              // Current balance row
              Row(children: [
                Text(
                  'Balance: ',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  currentBalance != null
                      ? Fmt.currency(currentBalance!)
                      : Fmt.currency(account.initialBalance),
                  style: TextStyle(
                    color: _isBlown
                        ? AppColors.loss
                        : (currentBalance != null &&
                                currentBalance! > account.initialBalance
                            ? AppColors.profit
                            : AppColors.textSecondary),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (currentBalance != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(start: ${Fmt.currency(account.initialBalance)})',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ]),
            ],
          ),
        ),
        // Actions
        PopupMenuButton<String>(
          color: Theme.of(context).colorScheme.surface,
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'archive') onArchive();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'edit',
                child: Text('Edit',
                    style: TextStyle(color: AppColors.textPrimary))),
            PopupMenuItem(
                value: 'archive',
                child: Text('Archive',
                    style: TextStyle(color: AppColors.textSecondary))),
            PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.loss))),
          ],
        ),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      );
}

// ── Account Form Sheet ─────────────────────────────────────────────────────────

class AccountFormSheet extends StatefulWidget {
  final Account? existing;
  final WidgetRef ref;
  const AccountFormSheet({super.key, this.existing, required this.ref});

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _broker;
  late final TextEditingController _balance;
  late final TextEditingController _leverage;
  late final TextEditingController _target;
  late AccountType _type;
  late String _currency;
  bool _saving = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'AUD', 'CAD'];

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _name = TextEditingController(text: a?.name ?? '');
    _broker = TextEditingController(text: a?.broker ?? '');
    _balance = TextEditingController(
        text: a?.initialBalance.toStringAsFixed(2) ?? '10000');
    _leverage = TextEditingController(text: a?.leverage.toString() ?? '100');
    _target =
        TextEditingController(text: a?.targetBalance?.toStringAsFixed(2) ?? '');
    _type = a?.accountType ?? AccountType.live;
    _currency = a?.currency ?? 'USD';
  }

  @override
  void dispose() {
    _name.dispose();
    _broker.dispose();
    _balance.dispose();
    _leverage.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'broker': _broker.text.trim().isEmpty ? null : _broker.text.trim(),
        'currency': _currency,
        'initial_balance': double.parse(_balance.text),
        'account_type': _type.name,
        'leverage': int.tryParse(_leverage.text) ?? 1,
        'target_balance':
            _target.text.isEmpty ? null : double.tryParse(_target.text),
      };
      if (widget.existing != null) {
        await widget.ref
            .read(accountRepositoryProvider)
            .update(widget.existing!.id, data);
      } else {
        await widget.ref.read(accountRepositoryProvider).insert(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.loss),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(isEdit ? 'Edit Account' : 'New Account',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              // Account Type chips
              const Text('Account Type',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AccountType.values.map((t) {
                  final sel = _type == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: sel,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Account Name *',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _broker,
                decoration: const InputDecoration(
                    labelText: 'Broker Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                        labelText: 'Currency',
                        labelStyle: TextStyle(color: AppColors.textSecondary)),
                    items: _currencies
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: AppColors.textPrimary))))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _leverage,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Leverage',
                        prefixText: '1:',
                        labelStyle: TextStyle(color: AppColors.textSecondary)),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _balance,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Starting Balance *',
                        labelStyle: TextStyle(color: AppColors.textSecondary)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _target,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Target Balance',
                        labelStyle: TextStyle(color: AppColors.textSecondary)),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ]),
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
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(isEdit ? 'Save Changes' : 'Create Account'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
