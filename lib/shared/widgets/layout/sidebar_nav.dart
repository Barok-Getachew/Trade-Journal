import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:journal/core/theme/app_colors.dart';
import 'package:journal/core/theme/app_spacing.dart';
import 'package:journal/features/accounts/providers/account_provider.dart';
import 'package:journal/features/auth/providers/auth_provider.dart';
import 'package:journal/features/profile/profile_dialog.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconActive;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    iconActive: Icons.dashboard_rounded,
    route: '/dashboard',
  ),
  _NavItem(
    label: 'Trade Journal',
    icon: Icons.receipt_long_outlined,
    iconActive: Icons.receipt_long_rounded,
    route: '/trades',
  ),
  _NavItem(
    label: 'Analytics',
    icon: Icons.bar_chart_outlined,
    iconActive: Icons.bar_chart_rounded,
    route: '/analytics',
  ),
  _NavItem(
    label: 'Accounts',
    icon: Icons.account_balance_outlined,
    iconActive: Icons.account_balance_rounded,
    route: '/accounts',
  ),
  _NavItem(
    label: 'Daily Review',
    icon: Icons.today_outlined,
    iconActive: Icons.today_rounded,
    route: '/daily-review',
  ),
  _NavItem(
    label: 'Weekly Review',
    icon: Icons.calendar_view_week_outlined,
    iconActive: Icons.calendar_view_week_rounded,
    route: '/weekly-review',
  ),
  _NavItem(
    label: 'Monthly Audit',
    icon: Icons.assessment_outlined,
    iconActive: Icons.assessment_rounded,
    route: '/monthly-audit',
  ),
  _NavItem(
    label: 'Risk Rules',
    icon: Icons.security_outlined,
    iconActive: Icons.security_rounded,
    route: '/risk-rules',
  ),
  _NavItem(
    label: 'Daily Narrative',
    icon: Icons.edit_note_outlined,
    iconActive: Icons.edit_note_rounded,
    route: '/daily-narrative',
  ),
  _NavItem(
    label: 'Weekly Narrative',
    icon: Icons.psychology_outlined,
    iconActive: Icons.psychology_rounded,
    route: '/weekly-narrative-builder',
  ),
];

class SidebarNav extends ConsumerWidget {
  final bool isDrawer;
  const SidebarNav({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final accountsAsync = ref.watch(accountListProvider);
    final selected = ref.watch(selectedAccountProvider);

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'TradeOS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // ── Account switcher ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: accountsAsync.when(
              loading: () => const SizedBox(
                height: 36,
                child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (accounts) {
                final items = <DropdownMenuItem<String>>[
                  const DropdownMenuItem(
                    value: '__all__',
                    child: Text('All Accounts',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  ...accounts.map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(children: [
                        _typeDot(a.accountType.name),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(a.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 12)),
                        ),
                      ]),
                    ),
                  ),
                ];
                return DropdownButtonFormField<String>(
                  value: selected == null ? '__all__' : selected.id,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: items,
                  onChanged: (id) {
                    if (id == '__all__') {
                      ref.read(selectedAccountProvider.notifier).state = null;
                    } else {
                      final account = accounts.firstWhere((a) => a.id == id);
                      ref.read(selectedAccountProvider.notifier).state =
                          account;
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // ── Nav items ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _navItems.map((item) {
                final isActive = location.startsWith(item.route);
                return _SidebarItem(item: item, isActive: isActive);
              }).toList(),
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // ── User profile tile ──────────────────────────────────────────────
          _UserProfileTile(),
        ],
      ),
    );
  }

  Widget _typeDot(String type) {
    final color = switch (type) {
      'live' => AppColors.profit,
      'funded' => AppColors.primary,
      _ => AppColors.textMuted,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── User Profile Tile ──────────────────────────────────────────────────────────

class _UserProfileTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(userEmailProvider);
    final initial = ref.watch(userInitialProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: PopupMenuButton<_UserAction>(
        offset: const Offset(0, -120),
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _UserAction.profile,
            child: Row(children: [
              const Icon(Icons.manage_accounts_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              const Text('Profile & Settings',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ]),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _UserAction.signOut,
            child: Row(children: [
              const Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.loss),
              const SizedBox(width: 10),
              const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.loss,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
        onSelected: (action) async {
          if (action == _UserAction.profile) {
            await showProfileDialog(context);
          } else if (action == _UserAction.signOut) {
            _confirmSignOut(context, ref);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                    const Text(
                      'Trader',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Sign Out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Clean up state before signing out
              ref.read(selectedAccountProvider.notifier).state = null;
              ref.invalidate(accountListProvider);
              await Supabase.instance.client.auth.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.loss,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

enum _UserAction { profile, signOut }

// ── Sidebar nav item ───────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;

  const _SidebarItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: isActive ? AppColors.primaryDim : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          hoverColor: AppColors.surfaceHighlight,
          onTap: () => context.go(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.iconActive : item.icon,
                  color:
                      isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isActive
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
