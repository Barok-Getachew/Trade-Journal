import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/print_service.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../auth/providers/repository_providers.dart';

final _tradeDetailProvider = FutureProvider.family((ref, String id) async {
  return ref.read(tradeRepositoryProvider).fetchById(id);
});

class TradeDetailScreen extends ConsumerWidget {
  final String tradeId;
  const TradeDetailScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradeAsync = ref.watch(_tradeDetailProvider(tradeId));

    return tradeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (trade) {
        if (trade == null) {
          return const EmptyState(
            title: 'Trade not found',
            icon: Icons.search_off_rounded,
          );
        }
        return Scrollbar(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 700
                  ? AppSpacing.md
                  : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    DirectionBadge(isLong: trade.direction.name == 'long'),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      trade.symbol,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      trade.assetClass.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    // ── Print / PDF button ───────────────────────────
                    IconButton(
                      icon: const Icon(Icons.print_rounded,
                          color: AppColors.textSecondary, size: 20),
                      tooltip: 'Print / Save as PDF',
                      onPressed: () => PrintService.printTrade(
                        context: context,
                        trade: trade,
                      ),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit'),
                      onPressed: () => context.push('/trades/$tradeId/edit'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Builder(builder: (ctx) {
                  final isMobile = MediaQuery.of(ctx).size.width < 700;

                  // Shared cards
                  final perfCard = GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performance',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(color: AppColors.border, height: 20),
                        _row(context, 'Net P&L', Fmt.currency(trade.netPnl),
                            color: trade.isWin
                                ? AppColors.profit
                                : AppColors.loss),
                        _row(context, 'R-Multiple',
                            Fmt.rMultiple(trade.rMultiple),
                            color: trade.isWin
                                ? AppColors.profit
                                : AppColors.loss),
                        _row(
                            context, 'Gross P&L', Fmt.currency(trade.grossPnl)),
                        _row(context, 'Commission',
                            Fmt.currency(trade.commission)),
                        _row(context, 'Return %', Fmt.percent(trade.returnPct)),
                        _row(context, 'Holding',
                            Fmt.duration(trade.holdingDuration)),
                        _row(context, 'Risk:Reward',
                            '1:${trade.riskReward.toStringAsFixed(2)}'),
                      ],
                    ),
                  );

                  final detailsCard = GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trade Details',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(color: AppColors.border, height: 20),
                        _row(context, 'Entry', Fmt.price(trade.entryPrice)),
                        _row(context, 'Exit', Fmt.price(trade.exitPrice)),
                        _row(context, 'Stop Loss', Fmt.price(trade.stopLoss)),
                        _row(context, 'Take Profit',
                            Fmt.price(trade.takeProfit)),
                        _row(context, 'Position Size',
                            trade.positionSize.toString()),
                        _row(context, 'Risk Amount',
                            Fmt.currency(trade.riskAmount)),
                        _row(context, 'Risk %',
                            '${trade.riskPct.toStringAsFixed(2)}%'),
                        _row(
                            context, 'Entry Time', Fmt.dateTime(trade.entryAt)),
                        _row(context, 'Exit Time', Fmt.dateTime(trade.exitAt)),
                      ],
                    ),
                  );

                  final psychCard = GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Psychology',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(color: AppColors.border, height: 20),
                        _row(context, 'Emotion Before',
                            trade.emotionBefore?.label ?? '—'),
                        _row(context, 'Emotion After',
                            trade.emotionAfter?.label ?? '—'),
                        _row(context, 'Confidence', '${trade.confidence}/5'),
                        _row(context, 'Rules Followed',
                            trade.rulesFollowed ? 'Yes ✓' : 'No ✗',
                            color: trade.rulesFollowed
                                ? AppColors.profit
                                : AppColors.loss),
                        _row(context, 'Impulse Trade',
                            trade.isImpulse ? 'Yes' : 'No',
                            color: trade.isImpulse
                                ? AppColors.loss
                                : AppColors.textSecondary),
                        if (trade.mistakeType != null)
                          _row(context, 'Mistake', trade.mistakeType!,
                              color: AppColors.warning),
                      ],
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        perfCard,
                        const SizedBox(height: AppSpacing.md),
                        detailsCard,
                        const SizedBox(height: AppSpacing.md),
                        psychCard,
                      ],
                    );
                  }

                  // Desktop: two-column layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: perfCard),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          children: [
                            detailsCard,
                            const SizedBox(height: AppSpacing.md),
                            psychCard,
                          ],
                        ),
                      ),
                    ],
                  );
                }),

                if (trade.reflection != null &&
                    trade.reflection!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reflection',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          trade.reflection!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
                // ── Screenshot ──────────────────────────────────────────────
                const SizedBox(height: AppSpacing.md),
                _ScreenshotCard(url: trade.screenshotUrl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(BuildContext ctx, String label, String? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
          Text(
            value ?? '—',
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screenshot Card ──────────────────────────────────────────────────────────

class _ScreenshotCard extends StatefulWidget {
  final String? url;
  const _ScreenshotCard({required this.url});

  @override
  State<_ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<_ScreenshotCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.url != null && widget.url!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.candlestick_chart_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Chart Screenshot',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
            ),
            const Spacer(),
            if (hasUrl)
              _FullscreenButton(
                onTap: () => _openFullscreen(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── No screenshot placeholder ──────────────────────────────────────
        if (!hasUrl) const _NoScreenshotPlaceholder(),

        // ── Image card ──────────────────────────────────────────────────────
        if (hasUrl)
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openFullscreen(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hovered
                        ? AppColors.primary.withOpacity(0.6)
                        : AppColors.border,
                    width: _hovered ? 1.5 : 1,
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.18),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The image
                      Image.network(
                        widget.url!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return _ShimmerPlaceholder(progress: progress);
                        },
                        errorBuilder: (_, __, ___) => _ErrorPlaceholder(
                          pulseAnim: _pulseAnim,
                        ),
                      ),

                      // Hover overlay — use Positioned.fill so it never
                      // requests an explicit height from its parent.
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _hovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.60),
                                ],
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _ViewFullscreenHint(),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Caption ─────────────────────────────────────────────────────────
        if (hasUrl) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Tap to view full screen • Pinch to zoom',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => _FullscreenImageDialog(url: widget.url!),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _NoScreenshotPlaceholder extends StatelessWidget {
  const _NoScreenshotPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
          // dashed effect via a solid border styled by decoration
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No screenshot attached',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Edit this trade to upload a chart screenshot',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FullscreenButton({required this.onTap});

  @override
  State<_FullscreenButton> createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<_FullscreenButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_full_rounded,
                size: 13,
                color: _hovered ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Full Screen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewFullscreenHint extends StatelessWidget {
  const _ViewFullscreenHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'View Full Screen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final ImageChunkEvent progress;
  const _ShimmerPlaceholder({required this.progress});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.progress.expectedTotalBytes != null
        ? widget.progress.cumulativeBytesLoaded /
            widget.progress.expectedTotalBytes!
        : null;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [
              AppColors.surfaceElevated,
              AppColors.surfaceHighlight,
              AppColors.surfaceElevated,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: pct,
                  color: AppColors.primary,
                  strokeWidth: 3,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pct != null
                    ? 'Loading ${(pct * 100).toStringAsFixed(0)}%'
                    : 'Loading screenshot…',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _ErrorPlaceholder({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: AppColors.surfaceElevated,
      child: Center(
        child: FadeTransition(
          opacity: pulseAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: AppColors.textMuted.withOpacity(0.6),
              ),
              const SizedBox(height: 10),
              const Text(
                'Screenshot unavailable',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fullscreen Dialog ────────────────────────────────────────────────────────

class _FullscreenImageDialog extends StatefulWidget {
  final String url;
  const _FullscreenImageDialog({required this.url});

  @override
  State<_FullscreenImageDialog> createState() => _FullscreenImageDialogState();
}

class _FullscreenImageDialogState extends State<_FullscreenImageDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // ── Zoomable image ─────────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: InteractiveViewer(
                      maxScale: 6,
                      minScale: 0.5,
                      child: Image.network(
                        widget.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top controls bar ───────────────────────────────────────
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Label with icon
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.candlestick_chart_rounded,
                                  color: Colors.white70, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Chart Screenshot',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom hint bar ────────────────────────────────────────
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _HintChip(
                              icon: Icons.pinch_rounded,
                              label: 'Pinch to zoom'),
                          const SizedBox(width: 12),
                          _HintChip(
                              icon: Icons.pan_tool_alt_rounded,
                              label: 'Drag to pan'),
                          const SizedBox(width: 12),
                          _HintChip(
                              icon: Icons.touch_app_rounded,
                              label: 'Tap to hide UI'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
