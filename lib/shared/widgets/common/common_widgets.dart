import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Profit/Loss colored text widget.
class PnlText extends StatelessWidget {
  final double value;
  final String Function(double)? formatter;
  final TextStyle? style;
  final bool showSign;

  const PnlText({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = value > 0
        ? c.profit
        : value < 0
            ? c.loss
            : c.textSecondary;

    final defaultFmt =
        formatter ??
        (v) {
          final sign = v > 0 && showSign ? '+' : '';
          return '$sign${v.toStringAsFixed(2)}';
        };

    return Text(
      defaultFmt(value),
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Direction badge (LONG / SHORT).
class DirectionBadge extends StatelessWidget {
  final bool isLong;
  const DirectionBadge({super.key, required this.isLong});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLong ? c.profitDim : c.lossDim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isLong ? '▲ LONG' : '▼ SHORT',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isLong ? c.profit : c.loss,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Status badge for rules followed / broken.
class DisciplineBadge extends StatelessWidget {
  final bool rulesFollowed;
  const DisciplineBadge({super.key, required this.rulesFollowed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: rulesFollowed ? c.profitDim : c.lossDim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rulesFollowed ? '✓ Followed' : '✗ Broken',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: rulesFollowed ? c.profit : c.loss,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Simple loading shimmer placeholder.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: [
              c.surface,
              c.surfaceElevated,
              c.surface,
            ],
            stops: [0, _anim.value, 1],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget.
class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: c.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: c.textSecondary),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
