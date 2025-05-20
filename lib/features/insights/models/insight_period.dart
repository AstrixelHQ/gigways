enum InsightPeriod {
  today,
  weekly,
  monthly,
  yearly;

  static InsightPeriod fromString(String period) {
    switch (period) {
      case 'today' || 'Today':
        return InsightPeriod.today;
      case 'weekly' || 'Weekly':
        return InsightPeriod.weekly;
      case 'monthly' || 'Monthly':
        return InsightPeriod.monthly;
      case 'yearly' || 'Yearly':
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
        return 'Weekly';
      case InsightPeriod.monthly:
        return 'Monthly';
      case InsightPeriod.yearly:
        return 'Yearly';
    }
  }
}
