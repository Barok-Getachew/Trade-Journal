import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/daily_narrative.dart';
import '../../domain/models/weekly_narrative.dart';
import '../../domain/models/trade.dart';
import 'formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color constants for PDFs
// ─────────────────────────────────────────────────────────────────────────────

final _kPrimary = PdfColor.fromHex('#3D7EFF');
final _kProfit = PdfColor.fromHex('#059669');
final _kLoss = PdfColor.fromHex('#DC2626');
final _kBg = PdfColors.white;
final _kSurface = PdfColor.fromHex('#F2F6FF');
final _kBorder = PdfColor.fromHex('#D1D9EE');
final _kText = PdfColor.fromHex('#0D1117');
final _kMuted = PdfColor.fromHex('#6B7280');
final _kAccent1 = PdfColor.fromHex('#7C3AED');
final _kAccent2 = PdfColor.fromHex('#059669');
final _kAccent3 = PdfColor.fromHex('#D97706');

// ─────────────────────────────────────────────────────────────────────────────
// Main service
// ─────────────────────────────────────────────────────────────────────────────

class PrintService {
  static Future<pw.ThemeData> _buildTheme() async {
    try {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
        italic: await PdfGoogleFonts.interItalic(),
      );
    } catch (_) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      );
    }
  }

  // ── Daily Narrative ─────────────────────────────────────────────────────────
  static Future<void> printDailyNarrative({
    required BuildContext context,
    required DailyNarrative narrative,
  }) async {
    try {
      final pdf = pw.Document();
      final d = narrative.narrativeDate;
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

      final theme = await _buildTheme();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (ctx) => [
          // ── Header ────────────────────────────────────────────────────────────
          _buildHeader(
            title: 'DAILY PRE-SESSION NARRATIVE',
            subtitle: dateStr,
            badge1:
                narrative.pair?.isNotEmpty == true ? narrative.pair! : null,
            badge2: narrative.session?.isNotEmpty == true
                ? narrative.session!
                : null,
          ),
          pw.SizedBox(height: 18),

          // ── Rule card ─────────────────────────────────────────────────────────
          _infoBox(
            'Complete every morning before session opens. '
            'If Sentence 5 is not complete — the trade does not exist.',
          ),
          pw.SizedBox(height: 16),

          // ── Sentences ────────────────────────────────────────────────────────
          _sentenceBlock(
              1, 'HTF Bias & Delivery', narrative.s1HtfBias, _kPrimary),
          _sentenceBlock(2, 'Current Price Action & Evidence',
              narrative.s2PriceAction, _kAccent1),
          _sentenceBlock(
              3, 'Liquidity Draw', narrative.s3LiquidityDraw, _kAccent2),
          _sentenceBlock(4, 'The Path', narrative.s4Path, _kAccent3),
          _sentenceBlock(
              5, 'Execution Plan ⚡ (MANDATORY)', narrative.s5Execution, _kLoss),

          // ── Status ────────────────────────────────────────────────────────────
          pw.SizedBox(height: 20),
          _statusRow([
            _StatusItem(
              'Pre-Session Complete',
              narrative.preSessionComplete,
            ),
            _StatusItem(
              'Post-Trade Attached',
              narrative.postAttachmentComplete,
            ),
          ]),

          if (narrative.postAttachmentComplete) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Post-Trade Review'),
            if (narrative.postBreakdown?.isNotEmpty == true)
              _textBlock('Breakdown', narrative.postBreakdown!),
            if (narrative.postEmotionalState?.isNotEmpty == true)
              _textBlock('Emotional State', narrative.postEmotionalState!),
          ],
        ],
      ));

      await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print PDF: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
  }

  // ── Weekly Narrative ────────────────────────────────────────────────────────
  static Future<void> printWeeklyNarrative({
    required BuildContext context,
    required WeeklyNarrative narrative,
  }) async {
    try {
      final pdf = pw.Document();
      final w = narrative.weekOf;
      final wEnd = w.add(const Duration(days: 6));
      final weekStr =
          '${w.day}/${w.month}/${w.year} – ${wEnd.day}/${wEnd.month}/${wEnd.year}';

      final theme = await _buildTheme();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (ctx) => [
          // ── Header ─────────────────────────────────────────────────────────
          _buildHeader(
            title: 'WEEKLY PRE-WEEK NARRATIVE',
            subtitle: 'Week of $weekStr',
            badge1: narrative.primaryInstrument?.isNotEmpty == true
                ? narrative.primaryInstrument!
                : null,
            badge2: narrative.highImpactNews?.isNotEmpty == true
                ? '📰 ${narrative.highImpactNews}'
                : null,
          ),
          pw.SizedBox(height: 18),

          // ── Steps ──────────────────────────────────────────────────────────
          _sentenceBlock(
              1, 'COT & Macro Positioning', narrative.step1Cot, _kPrimary),
          _sentenceBlock(2, 'HTF Structure', narrative.step2HtfStructure, _kAccent1),

          // Liquidity map table
          if (narrative.liquidityMap.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _liqTable(narrative.liquidityMap),
          ],

          _sentenceBlock(4, 'AMD Weekly Bias', narrative.step4Amd, _kAccent2),

          // Scenarios
          pw.SizedBox(height: 10),
          _sectionTitle('Step 5 — The Two Scenarios'),
          if (narrative.scenarioA?.isNotEmpty == true)
            _textBlock('Scenario A', narrative.scenarioA!),
          if (narrative.scenarioB?.isNotEmpty == true)
            _textBlock('Scenario B', narrative.scenarioB!),

          // Reflection (if done)
          if (narrative.reflectionComplete) ...[
            pw.SizedBox(height: 20),
            _divider(),
            pw.SizedBox(height: 12),
            _sectionTitle('Week-End Reflection'),
            if (narrative.reflScenarioPlayed?.isNotEmpty == true)
              _textBlock('Scenario That Played', narrative.reflScenarioPlayed!),
            _statusRow([
              _StatusItem('AMD Correctly Identified', narrative.reflAmdCorrect),
            ]),
            if (narrative.reflCleanestDay?.isNotEmpty == true)
              _textBlock('Cleanest Day', narrative.reflCleanestDay!),
            if (narrative.reflCompleteS5Count != null)
              _textBlock('Complete S5 Count',
                  '${narrative.reflCompleteS5Count} trades'),
            if (narrative.reflCarryForward?.isNotEmpty == true)
              _textBlock('Carry Forward', narrative.reflCarryForward!),
          ],
        ],
      ));

      await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print PDF: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
  }

  // ── Trade Journal PDF ────────────────────────────────────────────────────────
  static Future<void> printTrade({
    required BuildContext context,
    required Trade trade,
  }) async {
    try {
      final pdf = pw.Document();
      final theme = await _buildTheme();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (ctx) => [
          // ── Header ─────────────────────────────────────────────────────────
          _buildHeader(
            title: 'TRADE JOURNAL',
            subtitle: trade.symbol,
            badge1: trade.direction.name.toUpperCase(),
            badge2: trade.assetClass.label,
          ),
          pw.SizedBox(height: 18),

          // ── Performance table ───────────────────────────────────────────────
          _sectionTitle('Performance'),
          pw.Table(
            border: pw.TableBorder.all(
                color: _kBorder, width: 0.5),
            children: [
              _tableRow('Net P&L', Fmt.currency(trade.netPnl),
                  valueColor: trade.isWin ? _kProfit : _kLoss),
              _tableRow('R-Multiple', Fmt.rMultiple(trade.rMultiple),
                  valueColor: trade.isWin ? _kProfit : _kLoss),
              _tableRow('Gross P&L', Fmt.currency(trade.grossPnl)),
              _tableRow('Commission', Fmt.currency(trade.commission)),
              _tableRow('Return %', Fmt.percent(trade.returnPct)),
              _tableRow('Holding', Fmt.duration(trade.holdingDuration)),
              _tableRow(
                  'Risk:Reward', '1:${trade.riskReward.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Trade Details ──────────────────────────────────────────────────
          _sectionTitle('Entry / Exit'),
          pw.Table(
            border: pw.TableBorder.all(
                color: _kBorder, width: 0.5),
            children: [
              _tableRow('Entry Price', Fmt.price(trade.entryPrice)),
              _tableRow('Exit Price', Fmt.price(trade.exitPrice)),
              _tableRow('Stop Loss', Fmt.price(trade.stopLoss)),
              _tableRow('Take Profit', Fmt.price(trade.takeProfit)),
              _tableRow('Position Size', trade.positionSize.toString()),
              _tableRow('Risk Amount', Fmt.currency(trade.riskAmount)),
              _tableRow('Risk %', '${trade.riskPct.toStringAsFixed(2)}%'),
              _tableRow('Entry Time', Fmt.dateTime(trade.entryAt)),
              _tableRow('Exit Time', Fmt.dateTime(trade.exitAt)),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Psychology ────────────────────────────────────────────────────
          _sectionTitle('Psychology & Context'),
          pw.Table(
            border: pw.TableBorder.all(
                color: _kBorder, width: 0.5),
            children: [
              _tableRow(
                  'Emotion Before', trade.emotionBefore?.label ?? '—'),
              _tableRow(
                  'Emotion After', trade.emotionAfter?.label ?? '—'),
              _tableRow(
                  'Confidence', '${trade.confidence}/5'),
              _tableRow(
                  'Rules Followed',
                  trade.rulesFollowed ? 'Yes ✓' : 'No ✗',
                  valueColor:
                      trade.rulesFollowed ? _kProfit : _kLoss),
              _tableRow(
                  'Impulse Trade',
                  trade.isImpulse ? 'Yes' : 'No',
                  valueColor: trade.isImpulse ? _kLoss : _kMuted),
              if (trade.mistakeType?.isNotEmpty == true)
                _tableRow('Mistake', trade.mistakeType!,
                    valueColor: _kAccent3),
              _tableRow('Setup Quality', '${trade.setupQuality}/5'),
              if (trade.session != null)
                _tableRow('Session', trade.session!.label),
              if (trade.marketCondition != null)
                _tableRow('Market Condition', trade.marketCondition!.label),
            ],
          ),

          // ── Reflection ────────────────────────────────────────────────────
          if (trade.reflection?.isNotEmpty == true) ...[
            pw.SizedBox(height: 14),
            _textBlock('Reflection', trade.reflection!),
          ],

          // ── Checklist ────────────────────────────────────────────────────
          pw.SizedBox(height: 14),
          _sectionTitle('Entry Checklist'),
          _statusRow([
            _StatusItem('Plan Match', trade.planMatch),
            _StatusItem('Risk OK', trade.riskOk),
            _StatusItem('RR OK', trade.rrOk),
            _StatusItem('Confirmation', trade.confirmation),
            _StatusItem('Screenshot', trade.screenshotReady),
          ]),
        ],
      ));

      await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print PDF: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    String? badge1,
    String? badge2,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _kSurface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _kBorder, width: 1.0),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: _kPrimary,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title,
                        style: pw.TextStyle(
                            color: _kPrimary,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2)),
                    pw.Text(subtitle,
                        style: pw.TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (badge1 != null || badge2 != null) ...[
            pw.SizedBox(height: 10),
            pw.Row(children: [
              if (badge1 != null) _badge(badge1, _kPrimary),
              if (badge2 != null) ...[
                pw.SizedBox(width: 8),
                _badge(badge2, _kMuted),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  static pw.Widget _sentenceBlock(
      int n, String title, String? content, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _kSurface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _kBorder),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor(
                      color.red, color.green, color.blue, 0.08),
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    decoration: pw.BoxDecoration(
                      color: color,
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text('$n',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(title,
                      style: pw.TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                ]),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(
                  content?.isNotEmpty == true
                      ? content!
                      : '(not filled)',
                  style: pw.TextStyle(
                    color: content?.isNotEmpty == true
                        ? _kText
                        : _kMuted,
                    fontSize: 11,
                    fontStyle: content?.isNotEmpty == true
                        ? pw.FontStyle.normal
                        : pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _textBlock(String label, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Text(label,
            style: pw.TextStyle(
                color: _kMuted,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1A1D2E'),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _kBorder),
          ),
          child: pw.Text(content,
              style: pw.TextStyle(
                  color: PdfColors.white, fontSize: 11)),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title,
          style: pw.TextStyle(
              color: _kText,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _infoBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor(_kPrimary.red, _kPrimary.green, _kPrimary.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
            color: PdfColor(
                _kPrimary.red, _kPrimary.green, _kPrimary.blue, 0.4)),
      ),
      child: pw.Text(text,
          style:
              pw.TextStyle(color: _kPrimary, fontSize: 10)),
    );
  }

  static pw.Widget _badge(String label, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.15),
        borderRadius: pw.BorderRadius.circular(99),
        border: pw.Border.all(
            color: PdfColor(color.red, color.green, color.blue, 0.4)),
      ),
      child: pw.Text(label,
          style: pw.TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _divider() => pw.Container(
        height: 0.5,
        color: _kBorder,
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
      );

  static pw.Widget _liqTable(List<LiquidityLevel> liq) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Step 3 — Weekly Liquidity Map'),
        pw.Table(
          border: pw.TableBorder.all(
              color: _kBorder, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration:
                  pw.BoxDecoration(color: _kSurface),
              children: [
                _th('Type'),
                _th('Level'),
                _th('Notes'),
              ],
            ),
            ...liq.map((l) => pw.TableRow(children: [
                  _td(l.type),
                  _td(l.level.isEmpty ? '—' : l.level),
                  _td(l.notes.isEmpty ? '—' : l.notes),
                ])),
          ],
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
                color: _kMuted,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _td(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            style: pw.TextStyle(color: _kText, fontSize: 10)),
      );

  static pw.TableRow _tableRow(String label, String? value,
      {PdfColor? valueColor}) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: pw.Text(label,
            style: pw.TextStyle(color: _kMuted, fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: pw.Text(value ?? '—',
            style: pw.TextStyle(
                color: valueColor ?? _kText,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold)),
      ),
    ]);
  }

  static pw.Widget _statusRow(List<_StatusItem> items) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 6,
      children: items.map((item) {
        final isDone = item.value == true;
        final isUnknown = item.value == null;
        final color = isUnknown ? _kMuted : (isDone ? _kProfit : _kLoss);
        final icon = isUnknown ? '—' : (isDone ? '✓' : '✗');
        return _badge('$icon ${item.label}', color);
      }).toList(),
    );
  }
}

class _StatusItem {
  final String label;
  final bool? value;
  const _StatusItem(this.label, this.value);
}
