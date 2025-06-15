import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/insights/models/insight_entry.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

part 'pdf_report_service.g.dart';

@Riverpod(keepAlive: true)
PdfReportService pdfReportService(Ref ref) {
  return PdfReportService();
}

class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  factory PdfReportService() => _instance;
  PdfReportService._internal();

  // App colors in PDF format
  static final _primaryColor = PdfColor.fromHex('#C7B299'); // Golden
  static final _primaryColorVeryLight = PdfColor.fromHex('#F5F1ED');
  static final _darkColor = PdfColor.fromHex('#000000'); // Black
  static final _greyColor = PdfColor.fromHex('#666666'); // Grey
  static final _lightGreyColor = PdfColor.fromHex('#E0E0E0'); // Light Grey
  static final _veryLightGreyColor =
      PdfColor.fromHex('#F5F5F5'); // Very Light Grey

  /// Generate PDF report for the given period and data
  Future<String?> generateEarningsReport({
    required InsightPeriod period,
    required List<TrackingSession> sessions,
    required TrackingInsights insights,
    required String userName,
    required String userState,
  }) async {
    try {
      // Don't generate if no data
      if (sessions.isEmpty) {
        return null;
      }

      final helveticaData = await rootBundle.load(Assets.fonts.helvetica);

      final helveticaBoldData =
          await rootBundle.load(Assets.fonts.helveticaBold);

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(helveticaData),
          bold: pw.Font.ttf(helveticaBoldData),
        ),
      );

      // Load logo
      final logoData = await _loadLogo();

      // Convert sessions to entries for easier processing
      final entries = _convertSessionsToEntries(sessions);

      // Calculate additional analytics
      final analytics = _calculateAnalytics(sessions, insights);

      // Add pages to PDF
      await _addPages(
        pdf: pdf,
        period: period,
        entries: entries,
        insights: insights,
        analytics: analytics,
        userName: userName,
        userState: userState,
        logoData: logoData,
      );

      // Save PDF to file
      final filePath = await _savePdfToFile(pdf, period);

      return filePath;
    } catch (e) {
      debugPrint('Error generating PDF report: $e');
      return null;
    }
  }

  /// Open the generated PDF file
  Future<bool> openPdfFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error opening PDF file: $e');
      return false;
    }
  }

  /// Share the generated PDF file
  Future<void> sharePdfFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'My GigWays Earnings Report',
        subject: 'GigWays Earnings Report',
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Load app logo as bytes
  Future<Uint8List?> _loadLogo() async {
    try {
      final byteData = await rootBundle.load(Assets.image.logo.path);
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading logo: $e');
      return null;
    }
  }

  /// Convert tracking sessions to insight entries
  List<InsightEntry> _convertSessionsToEntries(List<TrackingSession> sessions) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    // Sort sessions by start time (newest first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions.map((session) {
      final date = dateFormatter.format(session.startTime);
      final startTime = timeFormatter.format(session.startTime);
      final endTime = session.endTime != null
          ? timeFormatter.format(session.endTime!)
          : 'In Progress';
      final time = '$startTime - $endTime';
      final hours = session.durationInSeconds / 3600;

      return InsightEntry(
        date: date,
        time: time,
        miles: session.miles,
        hours: hours,
        earnings: session.earnings ?? 0.0,
        expenses: session.expenses ?? 0.0,
      );
    }).toList();
  }

  /// Calculate additional analytics
  Map<String, dynamic> _calculateAnalytics(
      List<TrackingSession> sessions, TrackingInsights insights) {
    if (sessions.isEmpty) {
      return {
        'avgEarningsPerHour': 0.0,
        'avgMilesPerHour': 0.0,
        'mostProductiveDay': 'N/A',
        'totalSessions': 0,
      };
    }

    // Average earnings per hour
    final avgEarningsPerHour =
        insights.hours > 0 ? insights.totalEarnings / insights.hours : 0.0;

    // Average miles per hour
    final avgMilesPerHour =
        insights.hours > 0 ? insights.totalMiles / insights.hours : 0.0;

    // Most productive day (day with highest earnings)
    final dayEarnings = <String, double>{};
    for (final session in sessions) {
      if (session.earnings != null && session.earnings! > 0) {
        final day = DateFormat('EEEE').format(session.startTime);
        dayEarnings[day] = (dayEarnings[day] ?? 0) + session.earnings!;
      }
    }

    String mostProductiveDay = 'N/A';
    if (dayEarnings.isNotEmpty) {
      mostProductiveDay =
          dayEarnings.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return {
      'avgEarningsPerHour': avgEarningsPerHour,
      'avgMilesPerHour': avgMilesPerHour,
      'mostProductiveDay': mostProductiveDay,
      'totalSessions': sessions.length,
    };
  }

  /// Add all pages to the PDF document
  Future<void> _addPages({
    required pw.Document pdf,
    required InsightPeriod period,
    required List<InsightEntry> entries,
    required TrackingInsights insights,
    required Map<String, dynamic> analytics,
    required String userName,
    required String userState,
    required Uint8List? logoData,
  }) async {
    // Calculate date range
    final dateRange = _getDateRangeForPeriod(period);

    // Add main report page
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          _buildHeader(logoData, period, dateRange, userName),

          pw.SizedBox(height: 20),

          // Summary Section
          _buildSummarySection(insights, analytics),

          pw.SizedBox(height: 20),

          // Analytics Section
          _buildAnalyticsSection(analytics, insights),

          pw.SizedBox(height: 20),

          // Activity Log Header
          pw.Text(
            'Activity Log',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),

          pw.SizedBox(height: 10),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // Add activity log pages if there are entries
    if (entries.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(32),
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildActivityLogTable(entries),
          ],
          footer: (context) => _buildFooter(context),
        ),
      );
    }
  }

  /// Build PDF header section
  pw.Widget _buildHeader(Uint8List? logoData, InsightPeriod period,
      String dateRange, String userName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo or App Name
            logoData != null
                ? pw.Image(pw.MemoryImage(logoData), height: 40)
                : pw.Text(
                    'GigWays',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),

            pw.SizedBox(height: 8),

            pw.Text(
              'Earnings Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _darkColor,
              ),
            ),

            pw.SizedBox(height: 4),

            pw.Text(
              period.displayName,
              style: pw.TextStyle(
                fontSize: 16,
                color: _greyColor,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                color: _greyColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Driver: $userName',
              style: pw.TextStyle(
                fontSize: 12,
                color: _greyColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Period: $dateRange',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _darkColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build summary section with key metrics
  pw.Widget _buildSummarySection(
      TrackingInsights insights, Map<String, dynamic> analytics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),

          pw.SizedBox(height: 12),

          // Summary metrics in 2x2 grid
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard('Total Miles',
                    '${insights.totalMiles.toStringAsFixed(1)} mi'),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildSummaryCard(
                    'Total Hours', '${insights.hours.toStringAsFixed(1)} hrs'),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard('Total Earnings',
                    '\$${insights.totalEarnings.toStringAsFixed(2)}'),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildSummaryCard('Total Expenses',
                    '\$${insights.totalExpenses.toStringAsFixed(2)}'),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Net earnings (full width, highlighted)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _primaryColorVeryLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Net Earnings',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                pw.Text(
                  '\$${(insights.totalEarnings - insights.totalExpenses).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build analytics section
  pw.Widget _buildAnalyticsSection(
      Map<String, dynamic> analytics, TrackingInsights insights) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lightGreyColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Analytics',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard('Avg. Earnings/Hour',
                    '\$${analytics['avgEarningsPerHour'].toStringAsFixed(2)}'),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildAnalyticsCard('Avg. Miles/Hour',
                    '${analytics['avgMilesPerHour'].toStringAsFixed(1)} mi'),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard(
                    'Most Productive Day', analytics['mostProductiveDay']),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildAnalyticsCard(
                    'Total Sessions', '${analytics['totalSessions']}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual summary card
  pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _veryLightGreyColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: _greyColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _darkColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual analytics card
  pw.Widget _buildAnalyticsCard(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            color: _greyColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _darkColor,
          ),
        ),
      ],
    );
  }

  /// Build activity log table
  pw.Widget _buildActivityLogTable(List<InsightEntry> entries) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGreyColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5), // Date & Time
        1: const pw.FlexColumnWidth(1.5), // Miles
        2: const pw.FlexColumnWidth(1.5), // Hours
        3: const pw.FlexColumnWidth(1.5), // Earnings
        4: const pw.FlexColumnWidth(1.5), // Expenses
        5: const pw.FlexColumnWidth(1.5), // Net
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColorVeryLight),
          children: [
            _buildTableHeader('Date & Time'),
            _buildTableHeader('Miles'),
            _buildTableHeader('Hours'),
            _buildTableHeader('Earnings'),
            _buildTableHeader('Expenses'),
            _buildTableHeader('Net'),
          ],
        ),

        // Data rows
        ...entries.map((entry) => pw.TableRow(
              children: [
                _buildTableCell('${entry.date}\n${entry.time}'),
                _buildTableCell('${entry.miles.toStringAsFixed(1)}'),
                _buildTableCell('${entry.hours.toStringAsFixed(1)}'),
                _buildTableCell('\$${entry.earnings.toStringAsFixed(2)}'),
                _buildTableCell('\$${entry.expenses.toStringAsFixed(2)}'),
                _buildTableCell('\$${entry.netEarnings.toStringAsFixed(2)}'),
              ],
            )),
      ],
    );
  }

  /// Build table header cell
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _darkColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build table data cell
  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: _darkColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build footer with disclaimer and page numbers
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(color: _lightGreyColor),

          pw.SizedBox(height: 8),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _veryLightGreyColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'GigWays provides gig drivers with a reliable platform to track earnings, mileage, hours worked, and business expenses. This report is for informational purposes only and does not constitute tax, legal, or financial advice. GigWays is not a licensed tax advisor. Please consult a certified professional for personalized guidance.',
              style: pw.TextStyle(
                fontSize: 9,
                color: _greyColor,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),

          pw.SizedBox(height: 8),

          // Page number
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by GigWays',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _greyColor,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _greyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get formatted date range for the given period
  String _getDateRangeForPeriod(InsightPeriod period) {
    final now = DateTime.now();

    switch (period) {
      case InsightPeriod.today:
        return DateFormat('MMMM dd, yyyy').format(now);

      case InsightPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(endOfWeek)}';

      case InsightPeriod.monthly:
        return DateFormat('MMMM yyyy').format(now);

      case InsightPeriod.yearly:
        return DateFormat('yyyy').format(now);
    }
  }

  /// Get filename for the PDF report based on period
  String _getFilenameForPeriod(InsightPeriod period) {
    final now = DateTime.now();

    switch (period) {
      case InsightPeriod.today:
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        return 'gigway_${dateStr}_${dateStr}_report.pdf';

      case InsightPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
        final endStr = DateFormat('yyyy-MM-dd').format(endOfWeek);
        return 'gigway_${startStr}_${endStr}_report.pdf';

      case InsightPeriod.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final startStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
        final endStr = DateFormat('yyyy-MM-dd').format(endOfMonth);
        return 'gigway_${startStr}_${endStr}_report.pdf';

      case InsightPeriod.yearly:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        final startStr = DateFormat('yyyy-MM-dd').format(startOfYear);
        final endStr = DateFormat('yyyy-MM-dd').format(endOfYear);
        return 'gigway_${startStr}_${endStr}_report.pdf';
    }
  }

  /// Save PDF to file and return file path
  Future<String> _savePdfToFile(pw.Document pdf, InsightPeriod period) async {
    final bytes = await pdf.save();

    // Get appropriate directory (handles Android/iOS differences)
    final directory = await _getAppropriateDirectory();

    // Create filename with period-specific date range
    final filename = _getFilenameForPeriod(period);

    // Get unique file path (handles file conflicts)
    final filePath = await _getUniqueFilePath(directory.path, filename);

    // Save file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file.path;
  }

  /// Get appropriate directory for saving files
  Future<Directory> _getAppropriateDirectory() async {
    if (Platform.isAndroid) {
      // Try to get external storage directory first
      try {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }
      } catch (e) {
        debugPrint('Could not access Downloads directory: $e');
      }
    }

    // Fallback to app documents directory (works on both platforms)
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  /// Get unique file path to avoid conflicts
  Future<String> _getUniqueFilePath(String directory, String filename) async {
    String filePath = '$directory/$filename';
    File file = File(filePath);

    int counter = 1;
    while (await file.exists()) {
      // Extract name and extension
      final lastDotIndex = filename.lastIndexOf('.');
      final name = filename.substring(0, lastDotIndex);
      final extension = filename.substring(lastDotIndex);

      // Create new filename with counter
      final newFilename = '${name}_$counter$extension';
      filePath = '$directory/$newFilename';
      file = File(filePath);
      counter++;
    }

    return filePath;
  }
}
