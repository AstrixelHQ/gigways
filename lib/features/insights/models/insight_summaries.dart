import 'package:gigways/features/tracking/models/tracking_model.dart';

/// Weekly summary for monthly view
class WeeklySummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int weekNumber;
  final double totalMiles;
  final double totalHours;
  final double totalEarnings;
  final double totalExpenses;
  final int sessionCount;
  final List<TrackingSession> sessions;

  WeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.weekNumber,
    required this.totalMiles,
    required this.totalHours,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.sessionCount,
    required this.sessions,
  });

  double get netEarnings => totalEarnings - totalExpenses;

  String get dateRange {
    final startMonth = _monthName(weekStart.month);
    final endMonth = _monthName(weekEnd.month);

    if (startMonth == endMonth) {
      return '$startMonth ${weekStart.day}-${weekEnd.day}';
    } else {
      return '$startMonth ${weekStart.day} - $endMonth ${weekEnd.day}';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

/// Monthly summary for yearly view
class MonthlySummary {
  final DateTime monthStart;
  final String monthName;
  final int year;
  final double totalMiles;
  final double totalHours;
  final double totalEarnings;
  final double totalExpenses;
  final int sessionCount;
  final List<TrackingSession> sessions;

  MonthlySummary({
    required this.monthStart,
    required this.monthName,
    required this.year,
    required this.totalMiles,
    required this.totalHours,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.sessionCount,
    required this.sessions,
  });

  double get netEarnings => totalEarnings - totalExpenses;
}

/// Helper class to group sessions into summaries
class InsightSummaryHelper {
  /// Group sessions by week (Sunday start)
  static List<WeeklySummary> groupSessionsByWeek(
      List<TrackingSession> sessions) {
    if (sessions.isEmpty) return [];

    final Map<DateTime, List<TrackingSession>> weekGroups = {};

    for (final session in sessions) {
      final weekStart = _getWeekStart(session.startTime);
      weekGroups.putIfAbsent(weekStart, () => []).add(session);
    }

    final summaries = <WeeklySummary>[];

    weekGroups.forEach((weekStart, weekSessions) {
      final weekEnd = weekStart
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

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
        weekNumber: _getWeekNumber(weekStart),
        totalMiles: totalMiles,
        totalHours: totalHours,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        sessionCount: weekSessions.length,
        sessions: weekSessions,
      ));
    });

    // Sort by week start date (newest first)
    summaries.sort((a, b) => b.weekStart.compareTo(a.weekStart));

    return summaries;
  }

  /// Group sessions by month
  static List<MonthlySummary> groupSessionsByMonth(
      List<TrackingSession> sessions) {
    if (sessions.isEmpty) return [];

    final Map<DateTime, List<TrackingSession>> monthGroups = {};

    for (final session in sessions) {
      final monthStart =
          DateTime(session.startTime.year, session.startTime.month, 1);
      monthGroups.putIfAbsent(monthStart, () => []).add(session);
    }

    final summaries = <MonthlySummary>[];

    monthGroups.forEach((monthStart, monthSessions) {
      double totalMiles = 0;
      double totalHours = 0;
      double totalEarnings = 0;
      double totalExpenses = 0;

      for (final session in monthSessions) {
        totalMiles += session.miles;
        totalHours += session.durationInSeconds / 3600;
        totalEarnings += session.earnings ?? 0;
        totalExpenses += session.expenses ?? 0;
      }

      summaries.add(MonthlySummary(
        monthStart: monthStart,
        monthName: _getMonthName(monthStart.month),
        year: monthStart.year,
        totalMiles: totalMiles,
        totalHours: totalHours,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        sessionCount: monthSessions.length,
        sessions: monthSessions,
      ));
    });

    // Sort by month start date (newest first)
    summaries.sort((a, b) => b.monthStart.compareTo(a.monthStart));

    return summaries;
  }

  /// Get week start (Sunday)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday % 7; // Sunday = 0
    return DateTime(date.year, date.month, date.day - weekday);
  }

  /// Get week number in month
  static int _getWeekNumber(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final weekStart = _getWeekStart(firstDayOfMonth);
    return ((date.difference(weekStart).inDays) / 7).floor() + 1;
  }

  /// Get month name
  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
