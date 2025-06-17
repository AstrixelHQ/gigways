import 'package:gigways/features/insights/models/insight_summaries.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

/// Paginated insight data for different periods
class PaginatedInsights {
  final List<dynamic> summaries; // WeeklySummary for monthly, MonthlySummary for yearly
  final bool hasMore;
  final String? nextCursor;
  final int totalCount;
  final InsightPeriodType periodType;

  PaginatedInsights({
    required this.summaries,
    required this.hasMore,
    this.nextCursor,
    required this.totalCount,
    required this.periodType,
  });

  PaginatedInsights copyWith({
    List<dynamic>? summaries,
    bool? hasMore,
    String? nextCursor,
    int? totalCount,
    InsightPeriodType? periodType,
  }) {
    return PaginatedInsights(
      summaries: summaries ?? this.summaries,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      totalCount: totalCount ?? this.totalCount,
      periodType: periodType ?? this.periodType,
    );
  }
}

enum InsightPeriodType {
  daily,   // Shows individual tracking sessions
  weekly,  // Shows weekly summaries
  monthly, // Shows monthly summaries
  yearly,  // Shows monthly summaries
}

/// Summary card data for the UI
class SummaryCardData {
  final String title;
  final String subtitle;
  final double totalMiles;
  final double totalHours;
  final double totalEarnings;
  final double totalExpenses;
  final int sessionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  SummaryCardData({
    required this.title,
    required this.subtitle,
    required this.totalMiles,
    required this.totalHours,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.sessionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  double get netEarnings => totalEarnings - totalExpenses;

  factory SummaryCardData.fromWeeklySummary(WeeklySummary weekly) {
    return SummaryCardData(
      title: weekly.weekTitle, // "This Week", "Last Week", or "Week X"
      subtitle: weekly.dateRange, // "Jan 1 - Jan 7"
      totalMiles: weekly.totalMiles,
      totalHours: weekly.totalHours,
      totalEarnings: weekly.totalEarnings,
      totalExpenses: weekly.totalExpenses,
      sessionCount: weekly.sessionCount,
      periodStart: weekly.weekStart,
      periodEnd: weekly.weekEnd,
    );
  }

  factory SummaryCardData.fromMonthlySummary(MonthlySummary monthly, {bool isYearlyView = false}) {
    return SummaryCardData(
      title: isYearlyView 
          ? monthly.yearlyTitle  // "January 2024" (always with year)
          : monthly.monthTitle,  // "This Month", "Last Month", "January", or "January 2024"
      subtitle: isYearlyView 
          ? '${monthly.sessionCount} sessions' // "14 sessions" for yearly view
          : monthly.fullDateRange, // "January 1 - 31" or "January 1 - 31, 2024" for monthly view
      totalMiles: monthly.totalMiles,
      totalHours: monthly.totalHours,
      totalEarnings: monthly.totalEarnings,
      totalExpenses: monthly.totalExpenses,
      sessionCount: monthly.sessionCount,
      periodStart: monthly.monthStart,
      periodEnd: DateTime(monthly.monthStart.year, monthly.monthStart.month + 1, 0),
    );
  }

  factory SummaryCardData.fromTrackingSession(TrackingSession session) {
    final duration = session.durationInSeconds / 3600; // Convert to hours
    
    return SummaryCardData(
      title: _formatDate(session.startTime),
      subtitle: _formatTimeRange(session.startTime, session.endTime),
      totalMiles: session.miles,
      totalHours: duration,
      totalEarnings: session.earnings ?? 0.0,
      totalExpenses: session.expenses ?? 0.0,
      sessionCount: 1,
      periodStart: session.startTime,
      periodEnd: session.endTime ?? session.startTime,
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatTimeRange(DateTime start, DateTime? end) {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return '$startTime - In Progress';
    
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }
}
