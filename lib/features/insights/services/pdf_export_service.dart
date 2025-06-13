import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_export_service.g.dart';

@Riverpod(keepAlive: true)
PdfExportService pdfExportService(Ref ref) {
  return PdfExportService(
    firestore: FirebaseFirestore.instance,
    ref: ref,
  );
}

class PdfExportService {
  final FirebaseFirestore _firestore;

  AuthData get _authNotifier => ref.watch(authNotifierProvider);
  TrackingRepository get _trackingRepository =>
      ref.read(trackingRepositoryProvider);

  final Ref ref;

  PdfExportService({
    required FirebaseFirestore firestore,
    required this.ref,
  }) : _firestore = firestore;

  /// Collection reference for tracking export limits
  CollectionReference<Map<String, dynamic>> get _exportsCollection =>
      _firestore.collection('user-exports');

  /// Check if user can export (once per month limit)
  Future<bool> canUserExport(String userId) async {
    try {
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final exportDoc = await _exportsCollection.doc(userId).get();

      if (!exportDoc.exists) {
        return true; // First time export
      }

      final data = exportDoc.data()!;
      final lastExportMonth = data['lastExportMonth'] as String?;

      return lastExportMonth != currentMonth;
    } catch (e) {
      debugPrint('Error checking export eligibility: $e');
      return false;
    }
  }

  /// Update export tracking after successful export
  Future<void> _updateExportTracking(String userId) async {
    try {
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      await _exportsCollection.doc(userId).set({
        'userId': userId,
        'lastExportMonth': currentMonth,
        'lastExportDate': Timestamp.fromDate(now),
        'exportCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating export tracking: $e');
    }
  }

  /// Export yearly insights to PDF
  Future<ExportResult> exportYearlyInsights({
    required int year,
    VoidCallback? onProgress,
  }) async {
    try {
      final user = _authNotifier.user;
      if (user == null) {
        return ExportResult.error('User not authenticated');
      }

      // Check export eligibility
      final canExport = await canUserExport(user.uid);
      if (!canExport) {
        return ExportResult.error(
            'You can only export once per month. Please try again next month.');
      }

      onProgress?.call();

      // Get yearly data
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

      final sessions = await _trackingRepository.getSessionsForTimeRange(
        userId: user.uid,
        startTime: yearStart,
        endTime: yearEnd,
      );

      onProgress?.call();

      if (sessions.isEmpty) {
        return ExportResult.error('No tracking data found for $year');
      }

      // Generate PDF
      final pdfBytes = await _generatePdf(
        user: _authNotifier.userData!,
        sessions: sessions,
        year: year,
      );

      onProgress?.call();

      // Save PDF to device
      final filePath = await _savePdfToDevice(pdfBytes, year);

      // Update export tracking
      await _updateExportTracking(user.uid);

      onProgress?.call();

      return ExportResult.success(filePath);
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return ExportResult.error('Failed to export PDF: ${e.toString()}');
    }
  }

  /// Generate PDF document
  Future<Uint8List> _generatePdf({
    required UserModel user,
    required List<TrackingSession> sessions,
    required int year,
  }) async {
    final pdf = pw.Document();

    // Load logo asset
    final logoBytes = await rootBundle.load('assets/image/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Calculate totals
    final yearlyTotals = _calculateYearlyTotals(sessions);
    final monthlyBreakdown = _calculateMonthlyBreakdown(sessions, year);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader(logoImage, user, year),
          pw.SizedBox(height: 30),
          _buildMonthlyBreakdown(monthlyBreakdown, yearlyTotals),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build PDF header with logo and user info
  pw.Widget _buildHeader(pw.MemoryImage logo, UserModel user, int year) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logo, width: 80, height: 80),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Yearly Insights Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Jan 1, $year - Dec 31, $year',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Driver Information',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Name: ${user.fullName}'),
                  pw.Text('Email: ${user.email}'),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Report Generated',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(DateTime.now())}'),
                  pw.Text(
                      'Time: ${DateFormat('h:mm a').format(DateTime.now())}'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  /// Build monthly breakdown section with yearly totals
  pw.Widget _buildMonthlyBreakdown(List<MonthlyData> monthlyData, YearlyTotals yearlyTotals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Yearly Summary Header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Yearly Summary - ${DateTime.now().year}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactSummaryCard('Miles', '${yearlyTotals.totalMiles.toStringAsFixed(1)}'),
                  _buildCompactSummaryCard('Hours', '${yearlyTotals.totalHours.toStringAsFixed(1)}'),
                  _buildCompactSummaryCard('Earnings', '\$${yearlyTotals.totalEarnings.toStringAsFixed(2)}'),
                  _buildCompactSummaryCard('Expenses', '\$${yearlyTotals.totalExpenses.toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: yearlyTotals.netEarnings >= 0 ? PdfColors.green50 : PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Net Earnings: \$${yearlyTotals.netEarnings.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: yearlyTotals.netEarnings >= 0 ? PdfColors.green700 : PdfColors.red700,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        
        // Monthly Breakdown
        pw.Text(
          'Monthly Breakdown',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Month', isHeader: true),
                _buildTableCell('Miles', isHeader: true),
                _buildTableCell('Hours', isHeader: true),
                _buildTableCell('Earnings', isHeader: true),
                _buildTableCell('Expenses', isHeader: true),
                _buildTableCell('Net Earnings', isHeader: true),
              ],
            ),
            // Data rows
            ...monthlyData.map((month) => pw.TableRow(
                  children: [
                    _buildTableCell(month.monthName),
                    _buildTableCell(month.miles > 0 ? '${month.miles.toStringAsFixed(1)}' : '-'),
                    _buildTableCell(month.hours > 0 ? '${month.hours.toStringAsFixed(1)}' : '-'),
                    _buildTableCell(month.earnings > 0 ? '\$${month.earnings.toStringAsFixed(2)}' : '-'),
                    _buildTableCell(month.expenses > 0 ? '\$${month.expenses.toStringAsFixed(2)}' : '-'),
                    _buildTableCell(
                      month.netEarnings != 0 ? '\$${month.netEarnings.toStringAsFixed(2)}' : '-',
                      color: month.netEarnings > 0 ? PdfColors.green700 : 
                             month.netEarnings < 0 ? PdfColors.red700 : PdfColors.grey600,
                    ),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 20),
        
        // Footer
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Total Sessions: ${yearlyTotals.totalSessions}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Report generated on ${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build compact summary card for yearly totals
  pw.Widget _buildCompactSummaryCard(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build footer with disclaimer
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey300,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disclaimer:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'GigWays provides mileage tracking and summary reports to assist with record-keeping. While designed to align with IRS standards, these reports are not a substitute for professional tax advice. Users should consult a qualified tax advisor to ensure accuracy and compliance with all tax regulations.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              lineSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GigWays - Professional Mileage Tracking',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build table cell with consistent styling
  pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }


  /// Save PDF to device storage
  Future<String> _savePdfToDevice(Uint8List pdfBytes, int year) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'gigways_insights_$year.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Calculate yearly totals from sessions
  YearlyTotals _calculateYearlyTotals(List<TrackingSession> sessions) {
    double totalMiles = 0;
    double totalHours = 0;
    double totalEarnings = 0;
    double totalExpenses = 0;

    for (final session in sessions) {
      totalMiles += session.miles;
      totalHours += session.durationInSeconds / 3600;
      totalEarnings += session.earnings ?? 0;
      totalExpenses += session.expenses ?? 0;
    }

    return YearlyTotals(
      totalMiles: totalMiles,
      totalHours: totalHours,
      totalEarnings: totalEarnings,
      totalExpenses: totalExpenses,
      netEarnings: totalEarnings - totalExpenses,
      totalSessions: sessions.length,
    );
  }

  /// Calculate monthly breakdown from sessions
  List<MonthlyData> _calculateMonthlyBreakdown(
      List<TrackingSession> sessions, int year) {
    final monthlyMap = <int, MonthlyData>{};

    // Initialize all months
    for (int month = 1; month <= 12; month++) {
      monthlyMap[month] = MonthlyData(
        month: month,
        monthName: DateFormat('MMMM').format(DateTime(year, month)),
        miles: 0,
        hours: 0,
        earnings: 0,
        expenses: 0,
      );
    }

    // Aggregate sessions by month
    for (final session in sessions) {
      final month = session.startTime.month;
      final monthData = monthlyMap[month]!;

      monthlyMap[month] = MonthlyData(
        month: month,
        monthName: monthData.monthName,
        miles: monthData.miles + session.miles,
        hours: monthData.hours + (session.durationInSeconds / 3600),
        earnings: monthData.earnings + (session.earnings ?? 0),
        expenses: monthData.expenses + (session.expenses ?? 0),
      );
    }

    return monthlyMap.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Open the generated PDF file
  Future<void> openPdf(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Error opening PDF: $e');
    }
  }
}

/// Data models for PDF generation
class YearlyTotals {
  final double totalMiles;
  final double totalHours;
  final double totalEarnings;
  final double totalExpenses;
  final double netEarnings;
  final int totalSessions;

  YearlyTotals({
    required this.totalMiles,
    required this.totalHours,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.netEarnings,
    required this.totalSessions,
  });
}

class MonthlyData {
  final int month;
  final String monthName;
  final double miles;
  final double hours;
  final double earnings;
  final double expenses;

  MonthlyData({
    required this.month,
    required this.monthName,
    required this.miles,
    required this.hours,
    required this.earnings,
    required this.expenses,
  });

  double get netEarnings => earnings - expenses;
}

/// Export result wrapper
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;

  ExportResult.success(this.filePath)
      : success = true,
        error = null;

  ExportResult.error(this.error)
      : success = false,
        filePath = null;
}
