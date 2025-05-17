class InsightEntry {
  final String date;
  final String time;
  final double miles;
  final double hours;
  final double earnings;
  final double expenses;

  InsightEntry({
    required this.date,
    required this.time,
    required this.miles,
    required this.hours,
    required this.earnings,
    required this.expenses,
  });
  
  /// Calculate net earnings (earnings - expenses)
  double get netEarnings => earnings - expenses;
  
  /// Create a copy with updated values
  InsightEntry copyWith({
    String? date,
    String? time,
    double? miles,
    double? hours,
    double? earnings,
    double? expenses,
  }) {
    return InsightEntry(
      date: date ?? this.date,
      time: time ?? this.time,
      miles: miles ?? this.miles,
      hours: hours ?? this.hours,
      earnings: earnings ?? this.earnings,
      expenses: expenses ?? this.expenses,
    );
  }
}