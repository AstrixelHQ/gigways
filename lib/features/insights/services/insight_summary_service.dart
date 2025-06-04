// lib/features/insights/services/insight_summary_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:gigways/features/insights/models/insight_summary_models.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insight_summary_service.g.dart';

@Riverpod(keepAlive: true)
InsightSummaryService insightSummaryService(Ref ref) {
  return InsightSummaryService(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
    trackingRepository: ref.read(trackingRepositoryProvider),
  );
}

class InsightSummaryService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final TrackingRepository _trackingRepository;

  InsightSummaryService({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required TrackingRepository trackingRepository,
  })  : _firestore = firestore,
        _functions = functions,
        _trackingRepository = trackingRepository;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _summaryCollection =>
      _firestore.collection('insight-summary');

  /// Get current insight summary (single document read)
  Future<UserInsightSummary> getSummary(String userId) async {
    try {
      final doc = await _summaryCollection.doc(userId).get();

      if (!doc.exists) {
        return UserInsightSummary.empty(userId);
      }

      return UserInsightSummary.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting insight summary: $e');
      rethrow;
    }
  }

  /// Get summary with real-time fallback
  Future<UserInsightSummary> getSummaryWithFallback(String userId) async {
    try {
      // Try to get from summary first
      final summary = await getSummary(userId);

      // If summary is very outdated (>1 day), calculate fresh
      final now = DateTime.now();
      if (now.difference(summary.lastUpdated).inDays > 1) {
        debugPrint('Summary outdated, calculating fresh data');
        return await _calculateFreshSummary(userId);
      }

      return summary;
    } catch (e) {
      debugPrint(
          'Error getting summary, falling back to real-time calculation: $e');
      return await _calculateFreshSummary(userId);
    }
  }

  /// Real-time calculation fallback
  Future<UserInsightSummary> _calculateFreshSummary(String userId) async {
    try {
      final now = DateTime.now();

      // Calculate period boundaries
      final today = _getToday(now);
      final weekStart = _getWeekStart(now);
      final monthStart = _getMonthStart(now);
      final yearStart = _getYearStart(now);

      // Get sessions for each period (parallel requests)
      final futures = await Future.wait([
        _trackingRepository.getSessionsForTimeRange(
          userId: userId,
          startTime: today,
          endTime: today.add(const Duration(days: 1)),
        ),
        _trackingRepository.getSessionsForTimeRange(
          userId: userId,
          startTime: weekStart,
          endTime: weekStart.add(const Duration(days: 7)),
        ),
        _trackingRepository.getSessionsForTimeRange(
          userId: userId,
          startTime: monthStart,
          endTime: _getMonthEnd(now),
        ),
        _trackingRepository.getSessionsForTimeRange(
          userId: userId,
          startTime: yearStart,
          endTime: _getYearEnd(now),
        ),
      ]);

      final todaySessions = futures[0];
      final weekSessions = futures[1];
      final monthSessions = futures[2];
      final yearSessions = futures[3];

      return UserInsightSummary(
        userId: userId,
        today: _calculatePeriodInsights(todaySessions, today),
        thisWeek: _calculatePeriodInsights(weekSessions, weekStart),
        thisMonth: _calculatePeriodInsights(monthSessions, monthStart),
        thisYear: _calculatePeriodInsights(yearSessions, yearStart),
        lastUpdated: now,
        version: 0, // Indicate this is calculated, not from summary
        validation: ValidationMeta.initial(),
      );
    } catch (e) {
      debugPrint('Error calculating fresh summary: $e');
      return UserInsightSummary.empty(userId);
    }
  }

  /// Calculate insights from sessions
  PeriodInsights _calculatePeriodInsights(
    List<TrackingSession> sessions,
    DateTime periodStart,
  ) {
    if (sessions.isEmpty) {
      return PeriodInsights.empty(periodStart);
    }

    double totalMiles = 0;
    int totalDurationInSeconds = 0;
    double totalEarnings = 0;
    double totalExpenses = 0;
    DateTime periodEnd = periodStart;

    for (final session in sessions) {
      totalMiles += session.miles;
      totalDurationInSeconds += session.durationInSeconds;
      totalEarnings += session.earnings ?? 0;
      totalExpenses += session.expenses ?? 0;

      if (session.endTime != null && session.endTime!.isAfter(periodEnd)) {
        periodEnd = session.endTime!;
      }
    }

    return PeriodInsights(
      totalMiles: totalMiles,
      totalDurationInSeconds: totalDurationInSeconds,
      totalEarnings: totalEarnings,
      totalExpenses: totalExpenses,
      sessionCount: sessions.length,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  /// Retry failed updates manually
  Future<bool> retryFailedUpdates() async {
    try {
      final callable = _functions.httpsCallable('retryFailedInsightUpdates');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error retrying failed updates: $e');
      return false;
    }
  }

  /// Stream insight summary for real-time updates
  Stream<UserInsightSummary> watchSummary(String userId) {
    return _summaryCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return UserInsightSummary.empty(userId);
      }
      return UserInsightSummary.fromMap(snapshot.data()!);
    });
  }

  /// Force refresh summary (triggers validation if needed)
  Future<UserInsightSummary> refreshSummary(String userId) async {
    try {
      // Get current summary
      final summary = await getSummary(userId);

      // Check if validation is needed
      if (_shouldValidate(summary)) {
        await _performValidation(userId, summary);
      }

      // Return updated summary
      return await getSummary(userId);
    } catch (e) {
      debugPrint('Error refreshing summary: $e');
      return await getSummaryWithFallback(userId);
    }
  }

  /// Check if monthly validation is needed
  bool _shouldValidate(UserInsightSummary summary) {
    final now = DateTime.now();
    final lastValidated = summary.validation.lastValidated;

    // Monthly validation
    final daysSinceValidation = now.difference(lastValidated).inDays;

    return daysSinceValidation >= 30 || // Monthly
        summary.validation.needsValidation ||
        summary.validation.consecutiveSuccessfulValidations < 2;
  }

  /// Perform lightweight validation
  Future<void> _performValidation(
      String userId, UserInsightSummary summary) async {
    try {
      // Only validate current month to keep costs low
      final now = DateTime.now();
      final monthStart = _getMonthStart(now);
      final monthEnd = _getMonthEnd(now);

      // Get actual sessions for this month
      final actualSessions = await _trackingRepository.getSessionsForTimeRange(
        userId: userId,
        startTime: monthStart,
        endTime: monthEnd,
      );

      // Calculate expected insights
      final expectedInsights =
          _calculatePeriodInsights(actualSessions, monthStart);
      final storedInsights = summary.thisMonth;

      // Compare and check for discrepancies
      final discrepancy =
          _calculateDiscrepancy(expectedInsights, storedInsights);

      // Update validation metadata
      final updatedValidation = summary.validation.copyWith(
        lastValidated: now,
        lastValidatedPeriod:
            '${now.year}-${now.month.toString().padLeft(2, '0')}',
        needsValidation: discrepancy > 0.05, // 5% tolerance
        consecutiveSuccessfulValidations: discrepancy <= 0.05
            ? summary.validation.consecutiveSuccessfulValidations + 1
            : 0,
      );

      // Update summary with new validation data
      await _summaryCollection.doc(userId).update({
        'validation': updatedValidation.toMap(),
      });

      // If discrepancy is high, trigger correction
      if (discrepancy > 0.1) {
        // 10% discrepancy threshold
        debugPrint(
            'High discrepancy detected: $discrepancy, triggering correction');
        await _correctSummary(userId, summary, expectedInsights);
      }
    } catch (e) {
      debugPrint('Error performing validation: $e');
    }
  }

  /// Calculate discrepancy between expected and stored insights
  double _calculateDiscrepancy(PeriodInsights expected, PeriodInsights stored) {
    // Calculate relative differences for key metrics
    final earningsDiff =
        _relativeDifference(expected.totalEarnings, stored.totalEarnings);
    final milesDiff =
        _relativeDifference(expected.totalMiles, stored.totalMiles);
    final hoursDiff = _relativeDifference(expected.hours, stored.hours);

    // Return maximum discrepancy
    return [earningsDiff, milesDiff, hoursDiff].reduce((a, b) => a > b ? a : b);
  }

  double _relativeDifference(double expected, double actual) {
    if (expected == 0 && actual == 0) return 0;
    if (expected == 0) return actual.abs();
    return (expected - actual).abs() / expected;
  }

  /// Correct summary with calculated data
  Future<void> _correctSummary(
    String userId,
    UserInsightSummary summary,
    PeriodInsights correctedMonth,
  ) async {
    try {
      final correctedSummary = summary.copyWith(
        thisMonth: correctedMonth,
        lastUpdated: DateTime.now(),
        version: summary.version + 1,
        validation: summary.validation.copyWith(needsValidation: false),
      );

      await _summaryCollection.doc(userId).set(correctedSummary.toMap());
    } catch (e) {
      debugPrint('Error correcting summary: $e');
    }
  }

  // Date helper functions
  DateTime _getToday(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  DateTime _getMonthStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _getMonthEnd(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  DateTime _getYearStart(DateTime date) => DateTime(date.year, 1, 1);

  DateTime _getYearEnd(DateTime date) =>
      DateTime(date.year, 12, 31, 23, 59, 59);
}

/// Exception classes for better error handling
class InsightSummaryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  InsightSummaryException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'InsightSummaryException: $message';
}

class ValidationException extends InsightSummaryException {
  ValidationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
