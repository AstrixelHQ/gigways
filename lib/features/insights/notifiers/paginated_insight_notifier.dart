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
}

@Riverpod(keepAlive: true)
class PaginatedInsightNotifier extends _$PaginatedInsightNotifier {
  static const int _pageSize = 10;

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

      // Get initial page of sessions
      final sessions = await _repository.getSessionsForTimeRange(
        endTime: endTime,
        startTime: startTime,
        userId: userId,
      );

      final paginatedData = _processSessions(sessions, period);
      final displayData =
          _convertToDisplayData(paginatedData.summaries, period);

      state = PaginatedInsightState.success(
        data: paginatedData,
        displayData: displayData,
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

      // Get next page based on current data
      final additionalSessions = await _getNextPage(
        userId: userId,
        period: period,
        currentData: currentState.data,
        startTime: startTime,
        endTime: endTime,
      );

      // If no additional sessions, mark as no more data
      if (additionalSessions.isEmpty) {
        final updatedData = currentState.data.copyWith(hasMore: false);
        state = PaginatedInsightState.success(
          data: updatedData,
          displayData: currentState.displayData,
        );
        return;
      }

      // Combine with existing data
      final allSessions =
          _combineSessionData(currentState.data.summaries, additionalSessions);
      final newPaginatedData = _processSessions(allSessions, period);
      final newDisplayData =
          _convertToDisplayData(newPaginatedData.summaries, period);

      state = PaginatedInsightState.success(
        data: newPaginatedData,
        displayData: newDisplayData,
      );
    } catch (e) {
      // Restore previous state on error
      state = currentState;
    }
  }

  Future<List<TrackingSession>> _getNextPage({
    required String userId,
    required InsightPeriod period,
    required PaginatedInsights currentData,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // For now, implement simple offset-based pagination
    // In production, you'd use cursor-based pagination
    final currentCount = _getCurrentSessionCount(currentData.summaries);

    return await _repository.getSessionsForTimeRange(
      endTime: endTime,
      startTime: startTime,
      userId: userId,
    );
  }

  List<TrackingSession> _combineSessionData(
      List<dynamic> currentSummaries, List<TrackingSession> newSessions) {
    final allSessions = <TrackingSession>[];

    // Extract sessions from current summaries
    for (final summary in currentSummaries) {
      if (summary is WeeklySummary) {
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

  int _getCurrentSessionCount(List<dynamic> summaries) {
    int count = 0;
    for (final summary in summaries) {
      if (summary is WeeklySummary) {
        count += summary.sessionCount;
      } else if (summary is MonthlySummary) {
        count += summary.sessionCount;
      } else if (summary is TrackingSession) {
        count += 1;
      }
    }
    return count;
  }

  PaginatedInsights _processSessions(
      List<TrackingSession> sessions, InsightPeriod period) {
    switch (period) {
      case InsightPeriod.today:
        return PaginatedInsights(
          summaries: sessions,
          hasMore: sessions.length == _getInitialLimit(period),
          totalCount: sessions.length,
          periodType: InsightPeriodType.daily,
        );
      case InsightPeriod.weekly:
        final weeklySummaries =
            InsightSummaryHelper.groupSessionsByWeek(sessions);
        return PaginatedInsights(
          summaries: weeklySummaries,
          hasMore: sessions.length == _getInitialLimit(period),
          totalCount: weeklySummaries.length,
          periodType: InsightPeriodType.weekly,
        );
      case InsightPeriod.monthly:
        final weeklySummaries =
            InsightSummaryHelper.groupSessionsByWeek(sessions);
        return PaginatedInsights(
          summaries: weeklySummaries,
          hasMore: sessions.length ==
              _getInitialLimit(period), // Check original sessions count
          totalCount: weeklySummaries.length,
          periodType: InsightPeriodType.weekly,
        );
      case InsightPeriod.yearly:
        final monthlySummaries =
            InsightSummaryHelper.groupSessionsByMonth(sessions);
        return PaginatedInsights(
          summaries: monthlySummaries,
          hasMore: sessions.length ==
              _getInitialLimit(period), // Check original sessions count
          totalCount: monthlySummaries.length,
          periodType: InsightPeriodType.monthly,
        );
    }
  }

  List<SummaryCardData> _convertToDisplayData(
      List<dynamic> summaries, InsightPeriod period) {
    return summaries.map((summary) {
      if (summary is WeeklySummary) {
        return SummaryCardData.fromWeeklySummary(summary);
      } else if (summary is MonthlySummary) {
        return SummaryCardData.fromMonthlySummary(summary);
      } else if (summary is TrackingSession) {
        return SummaryCardData.fromTrackingSession(summary);
      }
      throw Exception('Unknown summary type: ${summary.runtimeType}');
    }).toList();
  }

  (DateTime, DateTime) _getTimeRange(InsightPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case InsightPeriod.today:
        return (now.subtract(const Duration(days: 1)), now);
      case InsightPeriod.weekly:
        // Get data from last 4 weeks (28 days) for better weekly aggregation
        return (now.subtract(const Duration(days: 28)), now);
      case InsightPeriod.monthly:
        return (now.subtract(const Duration(days: 90)), now); // 3 months for better weekly grouping
      case InsightPeriod.yearly:
        return (now.subtract(const Duration(days: 365)), now);
    }
  }

  int _getInitialLimit(InsightPeriod period) {
    switch (period) {
      case InsightPeriod.today:
      case InsightPeriod.weekly:
        return _pageSize;
      case InsightPeriod.monthly:
        return _pageSize * 4; // Load enough for ~4 weeks
      case InsightPeriod.yearly:
        return _pageSize * 12; // Load enough for ~12 months
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
