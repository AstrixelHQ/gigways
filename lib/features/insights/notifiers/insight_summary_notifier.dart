import 'package:flutter/material.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/models/insight_summary_models.dart';
import 'package:gigways/features/insights/services/insight_error_handler.dart';
import 'package:gigways/features/insights/services/insight_summary_service.dart';
import 'package:gigways/features/insights/services/insight_sync_queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insight_summary_notifier.g.dart';

enum InsightSummaryStatus {
  initial,
  loading,
  success,
  error,
  usingFallback,
}

class InsightSummaryState {
  final InsightSummaryStatus status;
  final UserInsightSummary? summary;
  final String? errorMessage;
  final bool hasQueuedUpdates;
  final bool isValidating;

  InsightSummaryState({
    this.status = InsightSummaryStatus.initial,
    this.summary,
    this.errorMessage,
    this.hasQueuedUpdates = false,
    this.isValidating = false,
  });

  InsightSummaryState copyWith({
    InsightSummaryStatus? status,
    UserInsightSummary? summary,
    String? errorMessage,
    bool? hasQueuedUpdates,
    bool? isValidating,
  }) {
    return InsightSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
      hasQueuedUpdates: hasQueuedUpdates ?? this.hasQueuedUpdates,
      isValidating: isValidating ?? this.isValidating,
    );
  }

  bool get isLoading => status == InsightSummaryStatus.loading;
  bool get hasError => status == InsightSummaryStatus.error;
  bool get isUsingFallback => status == InsightSummaryStatus.usingFallback;
  bool get hasData => summary != null;
}

@Riverpod(keepAlive: true)
class InsightSummaryNotifier extends _$InsightSummaryNotifier {
  InsightSummaryService get _service => ref.read(insightSummaryServiceProvider);
  InsightErrorHandler get _errorHandler =>
      ref.read(insightErrorHandlerProvider);
  InsightSyncQueue get _syncQueue => ref.read(insightSyncQueueProvider);

  @override
  InsightSummaryState build() {
    watchSummary();

    return InsightSummaryState();
  }

  /// Load insight summary
  Future<void> loadSummary({bool force = false}) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    if (!force && state.hasData && !state.hasError) {
      return; // Already have good data
    }

    state = state.copyWith(status: InsightSummaryStatus.loading);

    try {
      final summary = await _service.getSummaryWithFallback(user.uid);

      // Check sync queue status
      final syncStatus = await _errorHandler.getSyncStatus();

      state = state.copyWith(
        status: summary.version == 0
            ? InsightSummaryStatus.usingFallback
            : InsightSummaryStatus.success,
        summary: summary,
        hasQueuedUpdates: syncStatus.hasQueuedItems,
        errorMessage: null,
      );
    } catch (e) {
      // Handle error with all 3 strategies
      final result = await _errorHandler.handleSummaryError(
        user.uid,
        e is Exception ? e : Exception(e.toString()),
        null, // No context available in notifier
      );

      state = state.copyWith(
        status: result.success
            ? InsightSummaryStatus.usingFallback
            : InsightSummaryStatus.error,
        summary: result.summary,
        errorMessage: result.error?.toString(),
      );
    }
  }

  /// Refresh summary (includes validation)
  Future<void> refreshSummary() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    state = state.copyWith(isValidating: true);

    try {
      final summary = await _service.refreshSummary(user.uid);

      // Check sync queue status
      final syncStatus = await _errorHandler.getSyncStatus();

      state = state.copyWith(
        status: InsightSummaryStatus.success,
        summary: summary,
        hasQueuedUpdates: syncStatus.hasQueuedItems,
        isValidating: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: InsightSummaryStatus.error,
        errorMessage: e.toString(),
        isValidating: false,
      );
    }
  }

  /// Retry pending updates
  Future<void> retryPendingUpdates() async {
    try {
      final success = await _errorHandler.retryAllPending();

      if (success) {
        // Reload summary after successful retry
        await loadSummary(force: true);
      }
    } catch (e) {
      debugPrint('Error retrying pending updates: $e');
    }
  }

  /// Watch summary for real-time updates
  void watchSummary() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    _service.watchSummary(user.uid).listen(
      (summary) {
        if (state.status != InsightSummaryStatus.loading) {
          state = state.copyWith(
            summary: summary,
            status: InsightSummaryStatus.success,
          );
        }
      },
      onError: (error) {
        debugPrint('Error watching summary: $error');
      },
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(
      status: state.hasData
          ? InsightSummaryStatus.success
          : InsightSummaryStatus.initial,
      errorMessage: null,
    );
  }

  /// Get specific period insight
  PeriodInsights? getPeriodInsight(InsightPeriod period) {
    if (!state.hasData) return null;

    switch (period) {
      case InsightPeriod.today:
        return state.summary!.today;
      case InsightPeriod.weekly:
        return state.summary!.thisWeek;
      case InsightPeriod.monthly:
        return state.summary!.thisMonth;
      case InsightPeriod.yearly:
        return state.summary!.thisYear;
    }
  }

  /// Force app open validation (monthly)
  Future<void> performAppOpenValidation() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) {
      await loadSummary(force: true);
      return;
    }

    // Always check if we need fresh data for today
    final now = DateTime.now();
    
    if (!state.hasData) {
      await loadSummary(force: true);
      return;
    }

    final summary = state.summary!;
    final lastUpdated = summary.lastUpdated;
    
    // Force refresh if:
    // 1. Last update was on a different day (to ensure today's data is current)
    // 2. Using fallback data (version 0)
    // 3. Monthly validation is needed
    final isDifferentDay = lastUpdated.day != now.day || 
                          lastUpdated.month != now.month || 
                          lastUpdated.year != now.year;
    
    final isUsingFallback = summary.version == 0;
    
    final daysSinceValidation = now.difference(summary.validation.lastValidated).inDays;
    final needsMonthlyValidation = daysSinceValidation >= 30;

    if (isDifferentDay || isUsingFallback || needsMonthlyValidation) {
      await refreshSummary();
    }
  }
}
