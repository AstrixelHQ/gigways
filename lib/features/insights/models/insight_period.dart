enum InsightPeriod {
  today,
  weekly,
  monthly,
  yearly;

  static InsightPeriod fromString(String period) {
    switch (period) {
      case 'today' || 'Today':
        return InsightPeriod.today;
      case 'weekly' || 'Week':
        return InsightPeriod.weekly;
      case 'monthly' || 'Month':
        return InsightPeriod.monthly;
      case 'yearly' || 'Year':
        return InsightPeriod.yearly;
      default:
        throw Exception('Invalid period: $period');
    }
  }
}

extension InsightPeriodExtension on InsightPeriod {
  String get displayName {
    switch (this) {
      case InsightPeriod.today:
        return 'Today';
      case InsightPeriod.weekly:
        return 'Week';
      case InsightPeriod.monthly:
        return 'Month';
      case InsightPeriod.yearly:
        return 'Year';
    }
  }

  String get description {
    switch (this) {
      case InsightPeriod.today:
        return 'All sessions today';
      case InsightPeriod.weekly:
        return 'Last 7 days summary';
      case InsightPeriod.monthly:
        return '4-5 weeks overview';
      case InsightPeriod.yearly:
        return '12 months breakdown';
    }
  }
}
