import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/trade.dart';
import '../../../shared/widgets/cards/glass_card.dart';

class TradeHighlightCard extends StatelessWidget {
  final Trade trade;
  final String title;
  final bool isBest;

  const TradeHighlightCard({
    super.key,
    required this.trade,
    required this.title,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBest ? AppColors.profit : AppColors.loss;

    return Expanded(
      child: InkWell(
        onTap: () => context.push('/trades/${trade.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isBest
                        ? Icons.auto_awesome_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.symbol,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        Fmt.date(trade.entryAt),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${trade.rMultiple >= 0 ? '+' : ''}${trade.rMultiple.toStringAsFixed(1)}R',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
