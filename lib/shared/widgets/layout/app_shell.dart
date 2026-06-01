import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/profile_dialog.dart';
import 'sidebar_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _kMobileBreak = 700.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < _kMobileBreak;
      if (isMobile) {
        return _MobileShell(child: child);
      }
      return _DesktopShell(child: child);
    });
  }
}

// ── Desktop layout — sidebar + main content ───────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isTradeForm = location == '/trades/new' ||
        (location.startsWith('/trades/') && location.endsWith('/edit'));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isTradeForm
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go('/trades/new'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Log Trade',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
      body: Row(
        children: [
          const SidebarNav(),
          Expanded(
            child: Column(
              children: [
                _AppBar(),
                Expanded(child: ClipRect(child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout — premium bottom nav ───────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final navIndex = _navIndexOf(location);
    final isSubPage = _isSubPage(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, location, isSubPage),
      body: ClipRect(child: child),
      bottomNavigationBar: _MobileBottomNav(
        currentIndex: navIndex,
        location: location,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, String location, bool isSubPage) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: isSubPage ? 4 : 16,
      automaticallyImplyLeading: false,
      leading: isSubPage
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
            )
          : null,
      title: Text(
        _getTitle(location),
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17),
      ),
      actions: [
        Consumer(
          builder: (ctx, ref, _) {
            final isLight = ref.watch(themeProvider) == ThemeMode.light;
            return IconButton(
              icon: Icon(
                isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => ref.read(themeProvider.notifier).toggle(),
            );
          },
        ),
        Consumer(
          builder: (ctx, ref, _) {
            final initial = ref.watch(userInitialProvider);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => showProfileDialog(ctx),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  bool _isSubPage(String location) {
    if (location == '/trades') return false;
    if (location.startsWith('/trades/')) return true;
    if (location.startsWith('/accounts/')) return true;
    if (location.startsWith('/weekly-review/')) return true;
    if (location.startsWith('/daily-review/')) return true;
    return false;
  }

  int _navIndexOf(String location) {
    if (location.startsWith('/trades')) return 1;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/daily-narrative') ||
        location.startsWith('/weekly-narrative-builder') ||
        location.startsWith('/narrative-history') ||
        location.startsWith('/daily-review') ||
        location.startsWith('/weekly-review') ||
        location.startsWith('/accounts') ||
        location.startsWith('/risk-rules') ||
        location.startsWith('/monthly-audit')) return 4;
    return 0;
  }

  String _getTitle(String location) {
    if (location.startsWith('/trades/new')) return 'New Trade';
    if (location.startsWith('/trades/import')) return 'Import Trades';
    if (location.contains('/trades/') && location.endsWith('/edit')) {
      return 'Edit Trade';
    }
    if (location.startsWith('/trades/')) return 'Trade Detail';
    if (location.startsWith('/trades')) return 'Trade Journal';
    if (location.startsWith('/analytics')) return 'Analytics';
    if (location.startsWith('/accounts')) return 'Accounts';
    if (location.startsWith('/daily-review')) return 'Daily Review';
    if (location.startsWith('/weekly-review')) return 'Weekly Review';
    if (location.startsWith('/monthly-audit')) return 'Monthly Audit';
    if (location.startsWith('/risk-rules')) return 'Risk Rules';
    if (location.startsWith('/daily-narrative')) return 'Daily Narrative';
    if (location.startsWith('/weekly-narrative-builder')) return 'Weekly Narrative';
    if (location.startsWith('/narrative-history')) return 'Narrative History';
    return 'Dashboard';
  }
}

// ── Premium bottom navigation bar ─────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final String location;
  const _MobileBottomNav(
      {required this.currentIndex, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavTab(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                current: currentIndex,
                onTap: () => context.go('/'),
              ),
              _NavTab(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Trades',
                index: 1,
                current: currentIndex,
                onTap: () => context.go('/trades'),
              ),
              // Center FAB-style "+" button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/trades/new'),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              _NavTab(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Analytics',
                index: 3,
                current: currentIndex,
                onTap: () => context.go('/analytics'),
              ),
              _NavTab(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'More',
                index: 4,
                current: currentIndex,
                onTap: () => _showMore(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MoreSheet(),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More bottom sheet ──────────────────────────────────────────────────────────

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          _sectionLabel('Reviews'),
          _SheetTile(
            icon: Icons.today_rounded,
            label: 'Daily Review',
            iconColor: AppColors.primary,
            onTap: () { Navigator.pop(context); context.go('/daily-review'); },
          ),
          _SheetTile(
            icon: Icons.date_range_rounded,
            label: 'Weekly Review',
            iconColor: AppColors.primary,
            onTap: () { Navigator.pop(context); context.go('/weekly-review'); },
          ),
          _SheetTile(
            icon: Icons.calendar_month_outlined,
            label: 'Monthly Audit',
            iconColor: AppColors.primary,
            onTap: () { Navigator.pop(context); context.go('/monthly-audit'); },
          ),
          _sectionLabel('Narratives'),
          _SheetTile(
            icon: Icons.edit_note_rounded,
            label: 'Daily Narrative',
            iconColor: const Color(0xFF3D7EFF),
            onTap: () { Navigator.pop(context); context.go('/daily-narrative'); },
          ),
          _SheetTile(
            icon: Icons.psychology_rounded,
            label: 'Weekly Narrative',
            iconColor: const Color(0xFF7C3AED),
            onTap: () { Navigator.pop(context); context.go('/weekly-narrative-builder'); },
          ),
          _SheetTile(
            icon: Icons.history_rounded,
            label: 'Narrative History',
            iconColor: AppColors.textSecondary,
            onTap: () { Navigator.pop(context); context.go('/narrative-history'); },
          ),
          _sectionLabel('Settings'),
          _SheetTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Accounts',
            onTap: () { Navigator.pop(context); context.go('/accounts'); },
          ),
          _SheetTile(
            icon: Icons.shield_outlined,
            label: 'Risk Rules',
            onTap: () { Navigator.pop(context); context.go('/risk-rules'); },
          ),
          _SheetTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            iconColor: AppColors.loss,
            labelColor: AppColors.loss,
            onTap: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: labelColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Shared App Bar (desktop only) ─────────────────────────────────────────────

class _AppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = ref.watch(themeProvider) == ThemeMode.light;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            _getTitle(GoRouterState.of(context).matchedLocation),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
            ),
            color: AppColors.textSecondary,
            tooltip: isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode',
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Refresh data',
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          const SizedBox(width: AppSpacing.md),
          _UserAvatarChip(),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }

  String _getTitle(String location) {
    if (location.startsWith('/trades/new')) return 'New Trade';
    if (location.startsWith('/trades/import')) return 'Import Trades';
    if (location.contains('/trades/') && location.endsWith('/edit'))
      return 'Edit Trade';
    if (location.startsWith('/trades/')) return 'Trade Detail';
    if (location.startsWith('/trades')) return 'Trade Journal';
    if (location.startsWith('/analytics')) return 'Analytics';
    if (location.startsWith('/accounts')) return 'Accounts';
    if (location.startsWith('/daily-review')) return 'Daily Review';
    if (location.startsWith('/weekly-review')) return 'Weekly Review';
    if (location.startsWith('/monthly-audit')) return 'Monthly Audit';
    if (location.startsWith('/risk-rules')) return 'Risk Rules';
    if (location.startsWith('/daily-narrative')) return 'Daily Narrative';
    if (location.startsWith('/weekly-narrative-builder')) return 'Weekly Narrative';
    if (location.startsWith('/narrative-history')) return 'Narrative History';
    return 'Dashboard';
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// ── User avatar chip (desktop AppBar) ─────────────────────────────────────────

class _UserAvatarChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = ref.watch(userInitialProvider);
    final email = ref.watch(userEmailProvider);

    return Tooltip(
      message: email,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showProfileDialog(context),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
