// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/models/daily_narrative.dart';
import '../../domain/models/weekly_narrative.dart';
import '../../domain/models/trade.dart';
import 'formatters.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color constants for PDFs (Premium slate-based theme)
// ─────────────────────────────────────────────────────────────────────────────

const _kPrimary = PdfColor.fromInt(0xFF3D7EFF); // Active Primary Blue
const _kProfit = PdfColor.fromInt(0xFF10B981);  // Emerald Green
const _kLoss = PdfColor.fromInt(0xFFEF4444);    // Coral Red
const _kSurface = PdfColor.fromInt(0xFFF8FAFC); // Slate 50 (warm off-white)
const _kBorder = PdfColor.fromInt(0xFFE2E8F0);  // Slate 200 (subtle dividers)
const _kText = PdfColor.fromInt(0xFF0F172A);    // Slate 900 (deep dark text)
const _kMuted = PdfColor.fromInt(0xFF64748B);   // Slate 500 (cool secondary gray)
const _kAccent1 = PdfColor.fromInt(0xFF8B5CF6); // Purple
const _kAccent2 = PdfColor.fromInt(0xFF0D9488); // Teal
const _kAccent3 = PdfColor.fromInt(0xFFEA580C); // Orange/Amber

// ─────────────────────────────────────────────────────────────────────────────
// Main service
// ─────────────────────────────────────────────────────────────────────────────

class PrintService {
  /// Opens a modern and beautiful fullscreen-like dialog with an interactive PDF preview.
  /// Renders on Web, Desktop, and Mobile without native plugin issues.
  static Future<void> _showPreview({
    required BuildContext context,
    required Future<pw.Document> Function() pdfBuilder,
    required String filename,
  }) async {
    final c = AppColors.of(context);

    // ── Step 1: Build PDF bytes with a loading dialog ──────────────────────
    // PdfPreview widget crashes Flutter web with hundreds of
    // "Assertion failed: window.dart:99" errors, so we skip it entirely.
    // Instead: build bytes first, then show an action dialog. On web, the
    // browser's own print dialog (triggered by Printing.layoutPdf) acts as
    // the full-featured print preview.
    Uint8List? bytes;
    var spinnerShowing = true;

    // Show spinner WITHOUT await so PDF builds in the background.
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _PdfLoadingDialog(colors: c, filename: filename),
    ).then((_) => spinnerShowing = false);

    try {
      final pdf = await pdfBuilder();
      bytes = await pdf.save();
    } catch (e) {
      if (context.mounted && spinnerShowing) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    // Dismiss spinner
    if (context.mounted && spinnerShowing) Navigator.of(context).pop();
    if (!context.mounted) return;

    // ── Step 2: Show action dialog ─────────────────────────────────────────
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => _PdfActionDialog(
        filename: filename,
        bytes: bytes!,
        colors: c,
      ),
    );
  }

  static Future<pw.ThemeData> _buildTheme() async {
    // Use built-in Helvetica — no PdfGoogleFonts (printing package removed).
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
    );
  }

  // ── Daily Narrative ─────────────────────────────────────────────────────────
  static Future<void> printDailyNarrative({
    required BuildContext context,
    required DailyNarrative narrative,
  }) async {
    await _showPreview(
      context: context,
      filename: 'daily_narrative_${narrative.narrativeDate.toIso8601String().substring(0, 10)}.pdf',
      pdfBuilder: () async {
        final pdf = pw.Document();
        final d = narrative.narrativeDate;
        final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
              badge1: narrative.pair?.isNotEmpty == true ? narrative.pair! : null,
              badge2: narrative.session?.isNotEmpty == true ? narrative.session! : null,
            ),
            pw.SizedBox(height: 16),

            // ── Rule card ─────────────────────────────────────────────────────────
            _infoBox(
              'Complete every morning before session opens. '
              'If Sentence 5 is not complete — the trade does not exist.',
            ),
            pw.SizedBox(height: 16),

            // ── Sentences ────────────────────────────────────────────────────────
            _sentenceBlock(
              1,
              'HTF Bias & Delivery',
              narrative.s1HtfBias,
              _kPrimary,
              question: 'What has already been delivered and what is the institutional positioning?',
            ),
            _sentenceBlock(
              2,
              'Current Price Action & Evidence',
              narrative.s2PriceAction,
              _kAccent1,
              question: 'What is price doing RIGHT NOW and what is the institutional fingerprint proving it?',
            ),
            _sentenceBlock(
              3,
              'Liquidity Draw',
              narrative.s3LiquidityDraw,
              _kAccent2,
              question: 'What has not been taken yet and why do institutions need it?',
            ),
            _sentenceBlock(
              4,
              'The Path',
              narrative.s4Path,
              _kAccent3,
              question: 'How will price get there? What manipulation happens before delivery?',
            ),
            _sentenceBlock(
              5,
              'Execution Plan ⚡ (MANDATORY)',
              narrative.s5Execution,
              _kLoss,
              question: 'This must be complete BEFORE price reaches your zone. No exceptions.',
            ),

            // ── Status ────────────────────────────────────────────────────────────
            pw.SizedBox(height: 20),
            _statusRow([
              _StatusItem('Pre-Session Complete', narrative.preSessionComplete),
              _StatusItem('Post-Trade Attached', narrative.postAttachmentComplete),
            ]),

            if (narrative.postAttachmentComplete) ...[
              pw.SizedBox(height: 20),
              _sectionTitle('Post-Trade Review'),
              if (narrative.postBreakdown?.isNotEmpty == true)
                _textBlock('Breakdown & Execution Notes', narrative.postBreakdown!),
              if (narrative.postEmotionalState?.isNotEmpty == true)
                _textBlock('Emotional State & Psychology', narrative.postEmotionalState!),
            ],
          ],
        ));
        return pdf;
      },
    );
  }

  // ── Weekly Narrative ────────────────────────────────────────────────────────
  static Future<void> printWeeklyNarrative({
    required BuildContext context,
    required WeeklyNarrative narrative,
  }) async {
    await _showPreview(
      context: context,
      filename: 'weekly_narrative_${narrative.weekOf.toIso8601String().substring(0, 10)}.pdf',
      pdfBuilder: () async {
        final pdf = pw.Document();
        final w = narrative.weekOf;
        final wEnd = w.add(const Duration(days: 6));
        final weekStr = '${w.day}/${w.month}/${w.year} – ${wEnd.day}/${wEnd.month}/${wEnd.year}';
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
              badge1: narrative.primaryInstrument?.isNotEmpty == true ? narrative.primaryInstrument! : null,
              badge2: narrative.highImpactNews?.isNotEmpty == true ? '📰 ${narrative.highImpactNews}' : null,
            ),
            pw.SizedBox(height: 16),

            // ── Steps ──────────────────────────────────────────────────────────
            _sentenceBlock(
              1,
              'COT & Macro Positioning',
              narrative.step1Cot,
              _kPrimary,
              question: 'Where are institutions positioned heading into this week?',
            ),
            _sentenceBlock(
              2,
              'HTF Structure',
              narrative.step2HtfStructure,
              _kAccent1,
              question: 'What does the weekly/daily chart say about where price is going?',
            ),

            // Liquidity map table (Step 3)
            if (narrative.liquidityMap.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _liqTable(narrative.liquidityMap),
            ],

            _sentenceBlock(
              4,
              'AMD Weekly Bias',
              narrative.step4Amd,
              _kAccent2,
              question: 'How will institutions use this week\'s structure and news?',
            ),

            // Scenarios
            pw.SizedBox(height: 16),
            _sectionTitle('Step 5 — The Two Scenarios'),
            if (narrative.scenarioA?.isNotEmpty == true)
              _textBlock('Scenario A (Primary Path)', narrative.scenarioA!),
            if (narrative.scenarioB?.isNotEmpty == true)
              _textBlock('Scenario B (Alternative Path)', narrative.scenarioB!),

            // Reflection (if done)
            if (narrative.reflectionComplete) ...[
              pw.SizedBox(height: 20),
              _divider(),
              pw.SizedBox(height: 12),
              _sectionTitle('Week-End Reflection'),
              if (narrative.reflScenarioPlayed?.isNotEmpty == true)
                _textBlock('Scenario That Played Out', narrative.reflScenarioPlayed!),
              pw.SizedBox(height: 8),
              _statusRow([
                _StatusItem('AMD Correctly Identified', narrative.reflAmdCorrect),
              ]),
              if (narrative.reflCleanestDay?.isNotEmpty == true)
                _textBlock('Cleanest Day of the Week', narrative.reflCleanestDay!),
              if (narrative.reflCompleteS5Count != null)
                _textBlock(
                  'Execution Rate',
                  'Completed Sentence 5 checklist for ${narrative.reflCompleteS5Count} trades this week',
                ),
              if (narrative.reflCarryForward?.isNotEmpty == true)
                _textBlock('Lessons & Carry Forward', narrative.reflCarryForward!),
            ],
          ],
        ));
        return pdf;
      },
    );
  }

  // ── Trade Journal PDF ────────────────────────────────────────────────────────
  static Future<void> printTrade({
    required BuildContext context,
    required Trade trade,
  }) async {
    await _showPreview(
      context: context,
      filename: 'trade_${trade.symbol}_${trade.entryAt.toIso8601String().substring(0, 10)}.pdf',
      pdfBuilder: () async {
        final pdf = pw.Document();
        final theme = await _buildTheme();

        Uint8List? imageBytes;
        if (trade.screenshotUrl != null && trade.screenshotUrl!.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(trade.screenshotUrl!));
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
            }
          } catch (e) {
            debugPrint('Failed to download trade image: $e');
          }
        }

        // 2. Add Main Details Page
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: theme,
          build: (ctx) => [
            // Header
            _buildHeader(
              title: 'TRADE PERFORMANCE REPORT',
              subtitle: trade.symbol,
              badge1: trade.direction.name.toUpperCase(),
              badge2: trade.assetClass.label,
            ),
            pw.SizedBox(height: 20),

            // Side-by-side Tables for Clean UI
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Performance Results'),
                      pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
                          bottom: pw.BorderSide(color: _kBorder, width: 0.5),
                        ),
                        children: [
                          _tableRow('Net P&L', Fmt.currency(trade.netPnl),
                              valueColor: trade.isWin ? _kProfit : _kLoss),
                          _tableRow('R-Multiple', Fmt.rMultiple(trade.rMultiple),
                              valueColor: trade.isWin ? _kProfit : _kLoss),
                          _tableRow('Gross P&L', Fmt.currency(trade.grossPnl)),
                          _tableRow('Commission', Fmt.currency(trade.commission)),
                          _tableRow('Return %', Fmt.percent(trade.returnPct)),
                          _tableRow('Holding Duration', Fmt.duration(trade.holdingDuration)),
                          _tableRow('Risk:Reward Ratio', '1:${trade.riskReward.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.SizedBox(height: 20),

                      _sectionTitle('Psychology & Context'),
                      pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
                          bottom: pw.BorderSide(color: _kBorder, width: 0.5),
                        ),
                        children: [
                          _tableRow('Emotion Before', trade.emotionBefore?.label ?? '—'),
                          _tableRow('Emotion After', trade.emotionAfter?.label ?? '—'),
                          _tableRow('Confidence Level', '${trade.confidence}/5'),
                          _tableRow('Rules Followed', trade.rulesFollowed ? 'Yes ✓' : 'No ✗',
                              valueColor: trade.rulesFollowed ? _kProfit : _kLoss),
                          _tableRow('Impulse Trade', trade.isImpulse ? 'Yes' : 'No',
                              valueColor: trade.isImpulse ? _kLoss : _kMuted),
                          if (trade.mistakeType?.isNotEmpty == true)
                            _tableRow('Mistake Type', trade.mistakeType!, valueColor: _kLoss),
                          _tableRow('Setup Quality', '${trade.setupQuality}/5'),
                          if (trade.session != null)
                            _tableRow('Session', trade.session!.label),
                          if (trade.marketCondition != null)
                            _tableRow('Market Condition', trade.marketCondition!.label),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                // Right Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Execution Metrics'),
                      pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
                          bottom: pw.BorderSide(color: _kBorder, width: 0.5),
                        ),
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
                      pw.SizedBox(height: 20),

                      _sectionTitle('Pre-Trade Checklist'),
                      pw.SizedBox(height: 6),
                      _statusRow([
                        _StatusItem('Plan Match', trade.planMatch),
                        _StatusItem('Risk OK', trade.riskOk),
                        _StatusItem('RR OK', trade.rrOk),
                        _StatusItem('Confirmation', trade.confirmation),
                        _StatusItem('Screenshot', trade.screenshotReady),
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            // Reflection Notes
            if (trade.reflection?.isNotEmpty == true) ...[
              pw.SizedBox(height: 20),
              _textBlock('Reflection & Trade Notes', trade.reflection!),
            ],

            // Trade Screenshot
            if (imageBytes != null) ...[
              pw.SizedBox(height: 20),
              _sectionTitle('Chart Screenshot'),
              pw.SizedBox(height: 8),
              pw.Container(
                constraints: const pw.BoxConstraints(maxHeight: 350),
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  color: _kSurface,
                ),
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ],
          ],
        ));


        return pdf;
      },
    );
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
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 4,
                height: 28,
                decoration: const pw.BoxDecoration(
                  color: _kPrimary,
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
                            letterSpacing: 1.5)),
                    pw.SizedBox(height: 2),
                    pw.Text(subtitle,
                        style: pw.TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              if (badge1 != null || badge2 != null) ...[
                pw.Row(
                  children: [
                    if (badge1 != null) _badge(badge1, _kPrimary),
                    if (badge2 != null) ...[
                      pw.SizedBox(width: 8),
                      _badge(badge2, _kMuted),
                    ],
                  ],
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 1,
            color: _kBorder,
          ),
        ],
      ),
    );
  }

  static PdfColor _tintColor(PdfColor color, double factor) {
    final r = color.red + (1.0 - color.red) * (1.0 - factor);
    final g = color.green + (1.0 - color.green) * (1.0 - factor);
    final b = color.blue + (1.0 - color.blue) * (1.0 - factor);
    return PdfColor(r, g, b);
  }

  static pw.Widget _sentenceBlock(
    int n,
    String title,
    String? content,
    PdfColor color, {
    String? question,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _kSurface,
            border: pw.Border(
              left: pw.BorderSide(color: color, width: 3.0),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: _tintColor(color, 0.05),
                child: pw.Row(children: [
                  pw.Text('$n. $title',
                      style: pw.TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5)),
                ]),
              ),
              if (question != null && question.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, right: 12, top: 6),
                  child: pw.Text(
                    question,
                    style: pw.TextStyle(
                      color: _kMuted,
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
                child: pw.Text(
                  content?.isNotEmpty == true ? content! : '(not filled)',
                  style: pw.TextStyle(
                    color: content?.isNotEmpty == true ? _kText : _kMuted,
                    fontSize: 11,
                    height: 1.3,
                    fontStyle: content?.isNotEmpty == true ? pw.FontStyle.normal : pw.FontStyle.italic,
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
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: _kSurface,
            border: pw.Border(
              left: pw.BorderSide(color: _kBorder, width: 2.0),
            ),
          ),
          child: pw.Text(content,
              style: pw.TextStyle(color: _kText, fontSize: 11, height: 1.3)),
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
              fontSize: 12,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _infoBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _tintColor(_kPrimary, 0.05),
        border: const pw.Border(
          left: pw.BorderSide(color: _kPrimary, width: 3.0),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _kPrimary,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }

  static pw.Widget _badge(String label, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: _tintColor(color, 0.08),
        border: pw.Border.all(
          color: _tintColor(color, 0.3),
          width: 1.0,
        ),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
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
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
            bottom: pw.BorderSide(color: _kBorder, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _kSurface),
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
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(label, style: pw.TextStyle(color: _kMuted, fontSize: 9)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          value ?? '—',
          style: pw.TextStyle(
              color: valueColor ?? _kText,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.right,
        ),
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

// ── PDF Loading Dialog ───────────────────────────────────────────────────────

class _PdfLoadingDialog extends StatelessWidget {
  final dynamic colors;
  final String filename;
  const _PdfLoadingDialog({required this.colors, required this.filename});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: c.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              'Building PDF…',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filename,
              style: TextStyle(color: c.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PDF Action Dialog ────────────────────────────────────────────────────────

class _PdfActionDialog extends StatelessWidget {
  final String filename;
  final Uint8List bytes;
  final dynamic colors;

  const _PdfActionDialog({
    required this.filename,
    required this.bytes,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.primaryDim,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.picture_as_pdf_rounded,
                  color: c.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Ready',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filename,
              style: TextStyle(color: c.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: c.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Click "Print / Preview" to see a full print preview in the browser.',
                      style: TextStyle(color: c.primary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Buttons ───────────────────────────────────────────────────
            Row(
              children: [
                // Open in new tab — user can print with Ctrl+P / browser menu
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.open_in_new_rounded,
                    label: 'Open / Print',
                    primary: c.primary,
                    filled: false,
                    onTap: () {
                      final blob = html.Blob([bytes], 'application/pdf');
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      html.window.open(url, '_blank');
                      // Revoke after a short delay
                      Future.delayed(
                        const Duration(seconds: 30),
                        () => html.Url.revokeObjectUrl(url),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Download PDF directly
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    primary: c.primary,
                    filled: true,
                    onTap: () {
                      final blob = html.Blob([bytes], 'application/pdf');
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      html.AnchorElement(href: url)
                        ..setAttribute('download', filename)
                        ..click();
                      html.Url.revokeObjectUrl(url);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close',
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.primary,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: filled ? Colors.white : primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

