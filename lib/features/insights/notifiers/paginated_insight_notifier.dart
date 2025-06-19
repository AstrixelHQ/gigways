import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/models/insight_summaries.dart';
import 'package:gigways/features/insights/models/paginated_insights.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paginated_insight_notifier.g.dart';
part 'paginated_insight_notifier.freezed.dart';

@freezed
class PaginatedInsightState with _$PaginatedInsightState {
  const factory PaginatedInsightState.initial() = _Initial;
  const factory PaginatedInsightState.loading() = _Loading;
  const factory PaginatedInsightState.loadingMore() = _LoadingMore;
  const factory PaginatedInsightState.success({
    required PaginatedInsights data,
    required List<SummaryCardData> displayData,
    DocumentSnapshot? lastDocument,
  }) = _Success;
  const factory PaginatedInsightState.error(String message) = _Error;

  const PaginatedInsightState._();

  bool get isLoading => this is _Loading;
  bool get isLoadingMore => this is _LoadingMore;
  bool get isSuccess => this is _Success;
  bool get isError => this is _Error;
  bool get isInitial => this is _Initial;

  PaginatedInsights? get data =>
      this is _Success ? (this as _Success).data : null;

  List<SummaryCardData>? get displayData =>
      this is _Success ? (this as _Success).displayData : null;

  DocumentSnapshot? get lastDocument =>
      this is _Success ? (this as _Success).lastDocument : null;
}

@Riverpod(keepAlive: true)
class PaginatedInsightNotifier extends _$PaginatedInsightNotifier {
  static const int _pageSize = 20;

  @override
  PaginatedInsightState build(InsightPeriod period) {
    // Auto-fetch on creation
    Future.microtask(() => fetchInsights());
    return const PaginatedInsightState.initial();
  }

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);

  Future<void> fetchInsights() async {
    state = const PaginatedInsightState.loading();
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      state = const PaginatedInsightState.error('User not authenticated');
      return;
    }

    try {
      final (startTime, endTime) = _getTimeRange(period);
      final limit = _getInitialLimit(period);

      // Get initial page of sessions with pagination
      final result = await _repository.getSessionsPaginated(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
      );

      final paginatedData = _processSessions(result.sessions, period, result.hasMore);
      final displayData = _convertToDisplayData(paginatedData.summaries, period);

      state = PaginatedInsightState.success(
        data: paginatedData,
        displayData: displayData,
        lastDocument: result.lastDoc,
      );
    } catch (e) {
      state = PaginatedInsightState.error(e.toString());
    }
  }

  Future<void> loadMore() async {
    // Guard clause: don't load if not in success state or no more data
    if (!state.isSuccess || !(state.data?.hasMore ?? false)) {
      return;
    }

    final currentState = state as _Success;
    state = const PaginatedInsightState.loadingMore();

    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      // Restore previous state instead of error for auth issues
      state = currentState;
      return;
    }

    try {
      final (startTime, endTime) = _getTimeRange(period);
      final limit = _getInitialLimit(period);

      // Get next page using cursor-based pagination
      final result = await _repository.getSessionsPaginated(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
        startAfter: currentState.lastDocument,
      );

      // If no additional sessions, mark as no more data
      if (result.sessions.isEmpty) {
        final updatedData = currentState.data.copyWith(hasMore: false);
        state = PaginatedInsightState.success(
          data: updatedData,
          displayData: currentState.displayData,
          lastDocument: currentState.lastDocument,
        );
        return;
      }

      // Combine with existing data
      final allSessions = _combineSessionData(currentState.data.summaries, result.sessions);
      final newPaginatedData = _processSessions(allSessions, period, result.hasMore);
      final newDisplayData = _convertToDisplayData(newPaginatedData.summaries, period);

      state = PaginatedInsightState.success(
        data: newPaginatedData,
        displayData: newDisplayData,
        lastDocument: result.lastDoc,
      );
    } catch (e) {
      // Restore previous state on error
      state = currentState;
    }
  }


  List<TrackingSession> _combineSessionData(
      List<dynamic> currentSummaries, List<TrackingSession> newSessions) {
    final allSessions = <TrackingSession>[];

    // Extract sessions from current summaries
    for (final summary in currentSummaries) {
      if (summary is DailySummary) {
        allSessions.addAll(summary.sessions);
      } else if (summary is WeeklySummary) {
        allSessions.addAll(summary.sessions);
      } else if (summary is MonthlySummary) {
        allSessions.addAll(summary.sessions);
      } else if (summary is TrackingSession) {
        allSessions.add(summary);
      }
    }

    // Add new sessions
    allSessions.addAll(newSessions);

    // Remove duplicates and sort
    final uniqueSessions = allSessions.toSet().toList();
    uniqueSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return uniqueSessions;
  }


  PaginatedInsights _processSessions(
      List<TrackingSession> sessions, InsightPeriod period, bool hasMore) {
    switch (period) {
      case InsightPeriod.today:
        // Show individual sessions for today
        return PaginatedInsights(
          summaries: sessions,
          hasMore: hasMore,
          totalCount: sessions.length,
          periodType: InsightPeriodType.daily,
        );
      case InsightPeriod.weekly:
        // Show 7 days worth of daily summaries
        final dailySummaries = _groupSessionsByDay(sessions, 7);
        return PaginatedInsights(
          summaries: dailySummaries,
          hasMore: hasMore,
          totalCount: dailySummaries.length,
          periodType: InsightPeriodType.daily,
        );
      case InsightPeriod.monthly:
        // Show 4-5 weeks worth of weekly summaries
        final weeklySummaries = _groupSessionsByWeek(sessions, 5);
        return PaginatedInsights(
          summaries: weeklySummaries,
          hasMore: hasMore,
          totalCount: weeklySummaries.length,
          periodType: InsightPeriodType.weekly,
        );
      case InsightPeriod.yearly:
        // Show 12 months worth of monthly summaries
        final monthlySummaries = InsightSummaryHelper.groupSessionsByMonth(sessions);
        return PaginatedInsights(
          summaries: monthlySummaries,
          hasMore: hasMore,
          totalCount: monthlySummaries.length,
          periodType: InsightPeriodType.monthly,
        );
    }
  }

  List<SummaryCardData> _convertToDisplayData(
      List<dynamic> summaries, InsightPeriod period) {
    return summaries.map((summary) {
      if (summary is DailySummary) {
        return SummaryCardData.fromDailySummary(summary);
      } else if (summary is WeeklySummary) {
        return SummaryCardData.fromWeeklySummary(summary);
      } else if (summary is MonthlySummary) {
        // Pass isYearlyView = true for yearly tab
        return SummaryCardData.fromMonthlySummary(
          summary, 
          isYearlyView: period == InsightPeriod.yearly,
        );
      } else if (summary is TrackingSession) {
        return SummaryCardData.fromTrackingSession(summary);
      }
      throw Exception('Unknown summary type: ${summary.runtimeType}');
    }).toList();
  }

  (DateTime, DateTime) _getTimeRange(InsightPeriod period) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case InsightPeriod.today:
        // Today's entries only
        return (startOfToday, now);
      case InsightPeriod.weekly:
        // Last 7 days
        final weekStart = startOfToday.subtract(const Duration(days: 6));
        return (weekStart, now);
      case InsightPeriod.monthly:
        // Last 5 weeks (35 days)
        final monthStart = startOfToday.subtract(const Duration(days: 34));
        return (monthStart, now);
      case InsightPeriod.yearly:
        // Last 12 months
        final yearStart = DateTime(now.year - 1, now.month, now.day);
        return (yearStart, now);
    }
  }

  /// Group sessions by day for weekly view (7 days)
  List<DailySummary> _groupSessionsByDay(List<TrackingSession> sessions, int dayCount) {
    if (sessions.isEmpty) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayCount - 1));
    
    // Create a map for each day
    final Map<DateTime, List<TrackingSession>> dayGroups = {};
    
    // Initialize all days even if empty
    for (int i = 0; i < dayCount; i++) {
      final dayDate = startDate.add(Duration(days: i));
      dayGroups[dayDate] = [];
    }
    
    // Group sessions by day
    for (final session in sessions) {
      final sessionDay = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      if (dayGroups.containsKey(sessionDay)) {
        dayGroups[sessionDay]!.add(session);
      }
    }

    final summaries = <DailySummary>[];
    
    dayGroups.forEach((day, daySessions) {
      double totalMiles = 0;
      double totalHours = 0;
      double totalEarnings = 0;
      double totalExpenses = 0;

      for (final session in daySessions) {
        totalMiles += session.miles;
        totalHours += session.durationInSeconds / 3600;
        totalEarnings += session.earnings ?? 0;
        totalExpenses += session.expenses ?? 0;
      }

      summaries.add(DailySummary(
        date: day,
        totalMiles: totalMiles,
        totalHours: totalHours,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        sessionCount: daySessions.length,
        sessions: daySessions,
      ));
    });

    // Sort by date (newest first)
    summaries.sort((a, b) => b.date.compareTo(a.date));
    return summaries;
  }

  /// Group sessions by week for monthly view (5 weeks)
  List<WeeklySummary> _groupSessionsByWeek(List<TrackingSession> sessions, int weekCount) {
    if (sessions.isEmpty) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: (weekCount * 7) - 1));
    
    // Group sessions by week
    final Map<DateTime, List<TrackingSession>> weekGroups = {};
    
    for (final session in sessions) {
      final weekStart = _getWeekStart(session.startTime);
      weekGroups.putIfAbsent(weekStart, () => []).add(session);
    }

    final summaries = <WeeklySummary>[];
    
    weekGroups.forEach((weekStart, weekSessions) {
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      double totalMiles = 0;
      double totalHours = 0;
      double totalEarnings = 0;
      double totalExpenses = 0;

      for (final session in weekSessions) {
        totalMiles += session.miles;
        totalHours += session.durationInSeconds / 3600;
        totalEarnings += session.earnings ?? 0;
        totalExpenses += session.expenses ?? 0;
      }

      summaries.add(WeeklySummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        weekNumber: _getWeekOfYear(weekStart),
        totalMiles: totalMiles,
        totalHours: totalHours,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        sessionCount: weekSessions.length,
        sessions: weekSessions,
      ));
    });

    // Sort by week start (newest first)
    summaries.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return summaries.take(weekCount).toList();
  }

  /// Get week start (Monday as start of week)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Get week number of year
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return (daysDifference / 7).ceil();
  }

  int _getInitialLimit(InsightPeriod period) {
    switch (period) {
      case InsightPeriod.today:
        return _pageSize; // Individual sessions for today
      case InsightPeriod.weekly:
        return _pageSize * 2; // More sessions for 7 days
      case InsightPeriod.monthly:
        return _pageSize * 3; // More sessions for 5 weeks
      case InsightPeriod.yearly:
        return _pageSize * 6; // More sessions for 12 months
    }
  }

  // Update session (for edit functionality)
  Future<void> updateSession(
    TrackingSession session, {
    double? miles,
    int? durationInSeconds,
    double? earnings,
    double? expenses,
  }) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Update in repository
      await _repository.updateSessionData(
        userId: userId,
        sessionId: session.id,
        miles: miles,
        durationInSeconds: durationInSeconds,
        earnings: earnings,
        expenses: expenses,
      );

      // Refresh data
      await fetchInsights();
    } catch (e) {
      state = PaginatedInsightState.error(e.toString());
    }
  }

  // Delete session
  Future<void> deleteSession(TrackingSession session) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Delete from repository
      await _repository.deleteSession(
        userId: userId,
        sessionId: session.id,
      );

      // Refresh data
      await fetchInsights();
    } catch (e) {
      state = PaginatedInsightState.error(e.toString());
    }
  }
}
