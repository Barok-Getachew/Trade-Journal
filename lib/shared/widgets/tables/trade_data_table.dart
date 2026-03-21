import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/trade.dart';
import '../../../core/utils/formatters.dart';
import '../common/common_widgets.dart';

typedef TradeAction = void Function(Trade trade);

class TradeDataTable extends StatefulWidget {
  final List<Trade> trades;
  final TradeAction? onTap;
  final TradeAction? onDelete;

  const TradeDataTable({
    super.key,
    required this.trades,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TradeDataTable> createState() => _TradeDataTableState();
}

class _TradeDataTableState extends State<TradeDataTable> {
  int _sortCol = 0;
  bool _ascending = false;
  int _hoveredRow = -1;

  static const _columns = [
    'Date',
    'Symbol',
    'Side',
    'Net P&L',
    'R-Multiple',
    'W/L',
    'Rules',
    'Strategy',
  ];

  List<Trade> get _sorted {
    final list = List<Trade>.from(widget.trades);
    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 0:
          cmp = a.entryAt.compareTo(b.entryAt);
          break;
        case 1:
          cmp = a.symbol.compareTo(b.symbol);
          break;
        case 3:
          cmp = a.netPnl.compareTo(b.netPnl);
          break;
        case 4:
          cmp = a.rMultiple.compareTo(b.rMultiple);
          break;
        default:
          cmp = 0;
      }
      return _ascending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trades.isEmpty) {
      return const EmptyState(
        title: 'No trades found',
        message: 'Log your first trade to get started',
        icon: Icons.receipt_long_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: Row(
            children: _columns.asMap().entries.map((e) {
              return _buildHeaderCell(e.value, e.key);
            }).toList(),
          ),
        ),
        // Rows
        ...(_sorted.asMap().entries.map((e) => _buildRow(e.value, e.key))),
      ],
    );
  }

  Widget _buildHeaderCell(String label, int col) {
    final isActive = _sortCol == col;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          if (_sortCol == col) {
            _ascending = !_ascending;
          } else {
            _sortCol = col;
            _ascending = true;
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  _ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Trade trade, int idx) {
    final isHovered = _hoveredRow == idx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = idx),
      onExit: (_) => setState(() => _hoveredRow = -1),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(trade),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.surfaceHighlight : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              _cell(Fmt.date(trade.entryAt)),
              _cell(trade.symbol, bold: true, color: AppColors.textPrimary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: DirectionBadge(isLong: trade.direction.name == 'long'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: PnlText(
                    value: trade.netPnl,
                    formatter: (v) => Fmt.currency(v),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: PnlText(
                    value: trade.rMultiple,
                    formatter: (v) => Fmt.rMultiple(v),
                  ),
                ),
              ),
              _cell(
                trade.isWin
                    ? 'WIN'
                    : trade.isLoss
                    ? 'LOSS'
                    : 'B/E',
                color: trade.isWin
                    ? AppColors.profit
                    : trade.isLoss
                    ? AppColors.loss
                    : AppColors.textSecondary,
                bold: true,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: DisciplineBadge(rulesFollowed: trade.rulesFollowed),
                ),
              ),
              _cell(
                trade.strategyId?.substring(0, 8) ?? '—',
                color: AppColors.textSecondary,
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: AppColors.textMuted,
                  hoverColor: AppColors.lossDim,
                  onPressed: () => widget.onDelete?.call(trade),
                  tooltip: 'Delete trade',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {Color? color, bool bold = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
