import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
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

// ── Mobile layout — bottom nav + drawer ───────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navIndexOf(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          _getTitle(location),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        actions: [
          // Hamburger opens full sidebar as a Drawer
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textSecondary),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      endDrawer: const Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(child: SidebarNav(isDrawer: true)),
      ),
      body: ClipRect(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/dashboard',
                isActive: currentIndex == 0,
              ),
              _BottomNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Trades',
                route: '/trades',
                isActive: currentIndex == 1,
              ),
              _BottomNavItem(
                icon: Icons.add_circle_outline_rounded,
                activeIcon: Icons.add_circle_rounded,
                label: 'New',
                route: '/trades/new',
                isActive: currentIndex == 2,
                highlight: true,
              ),
              _BottomNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Analytics',
                route: '/analytics',
                isActive: currentIndex == 3,
              ),
              _BottomNavItem(
                icon: Icons.today_outlined,
                activeIcon: Icons.today_rounded,
                label: 'Review',
                route: '/daily-review',
                isActive: currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _navIndexOf(String location) {
    if (location.startsWith('/trades/new')) return 2;
    if (location.startsWith('/trades')) return 1;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/daily-review')) return 4;
    return 0;
  }

  String _getTitle(String location) {
    if (location.startsWith('/trades/new')) return 'New Trade';
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
    return 'Dashboard';
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;
  final bool highlight;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              highlight
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isActive ? activeIcon : icon,
                          color: Colors.white, size: 22),
                    )
                  : Icon(isActive ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared App Bar (desktop only) ─────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
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
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Refresh data',
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(_timeNow(), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }

  String _getTitle(String location) {
    if (location.startsWith('/trades/new')) return 'New Trade';
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
    return 'Dashboard';
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
