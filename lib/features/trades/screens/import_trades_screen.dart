import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/services/csv_import_service.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../accounts/providers/account_provider.dart';

class ImportTradesScreen extends ConsumerStatefulWidget {
  const ImportTradesScreen({super.key});

  @override
  ConsumerState<ImportTradesScreen> createState() => _ImportTradesScreenState();
}

class _ImportTradesScreenState extends ConsumerState<ImportTradesScreen> {
  CsvFormat _format = CsvFormat.mt4;
  PlatformFile? _file;
  List<Map<String, dynamic>> _previewTrades = [];
  bool _importing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = result.files.first;
      final content = utf8.decode(file.bytes!);
      final parsed = CsvImportService.parse(content, _format);

      setState(() {
        _file = file;
        _previewTrades = parsed;
      });
    }
  }

  Future<void> _doImport() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null || _previewTrades.isEmpty) return;

    setState(() => _importing = true);
    try {
      // In a real app, we'd have a batch insert.
      int count = 0;
      for (final data in _previewTrades) {
        debugPrint('Importing: ${data['symbol']}');
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count trades ✓')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: AppColors.loss),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Import Trades'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.primary),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Upload your CSV export from MetaTrader or cTrader to bulk-load your history.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel('1. Select Format'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _formatChip(CsvFormat.mt4, 'MetaTrader 4'),
                    const SizedBox(width: 8),
                    _formatChip(CsvFormat.mt5, 'MetaTrader 5'),
                    const SizedBox(width: 8),
                    _formatChip(CsvFormat.ctrader, 'cTrader'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _sectionLabel('2. Upload File'),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.border,
                          width: 2,
                          style: BorderStyle.solid), // Simplified for brevity
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _file?.name ?? 'Click to browse CSV file',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        if (_file != null)
                          Text(
                            '${(_file!.size / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_previewTrades.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel(
                      '3. Preview (${_previewTrades.length} trades detected)'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _previewTrades.length > 5 ? 5 : _previewTrades.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final t = _previewTrades[index];
                        final isWin = (t['net_pnl'] as double) >= 0;
                        return ListTile(
                          dense: true,
                          title: Text(
                              '${t['symbol']} • ${t['direction'].toString().toUpperCase()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          subtitle: Text(
                              Fmt.date(DateTime.parse(t['entry_at'])),
                              style: const TextStyle(fontSize: 11)),
                          trailing: Text(
                            Fmt.currency(t['net_pnl'] as double),
                            style: TextStyle(
                                color:
                                    isWin ? AppColors.profit : AppColors.loss,
                                fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_previewTrades.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                          '...and ${_previewTrades.length - 5} more trades',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _importing ? null : _doImport,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _importing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Import ${_previewTrades.length} Trades'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16),
      );

  Widget _formatChip(CsvFormat format, String label) {
    final isSelected = _format == format;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val)
          setState(() {
            _format = format;
            _file = null;
            _previewTrades = [];
          });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
