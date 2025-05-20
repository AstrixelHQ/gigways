enum InsightPeriod { today, weekly, monthly, yearly }

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
