import 'package:cloud_firestore/cloud_firestore.dart';

/// Main insight summary document stored per user
class UserInsightSummary {
  final String userId;
  final PeriodInsights today;
  final PeriodInsights thisWeek;
  final PeriodInsights thisMonth;
  final PeriodInsights thisYear;
  final DateTime lastUpdated;
  final int version;
  final ValidationMeta validation;

  UserInsightSummary({
    required this.userId,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.thisYear,
    required this.lastUpdated,
    required this.version,
    required this.validation,
  });

  factory UserInsightSummary.empty(String userId) {
    final now = DateTime.now();
    return UserInsightSummary(
      userId: userId,
      today: PeriodInsights.empty(_getToday(now)),
      thisWeek: PeriodInsights.empty(_getWeekStart(now)),
      thisMonth: PeriodInsights.empty(_getMonthStart(now)),
      thisYear: PeriodInsights.empty(_getYearStart(now)),
      lastUpdated: now,
      version: 1,
      validation: ValidationMeta.initial(),
    );
  }

  factory UserInsightSummary.fromMap(Map<String, dynamic> data) {
    return UserInsightSummary(
      userId: data['userId'] ?? '',
      today: PeriodInsights.fromMap(data['today'] ?? {}),
      thisWeek: PeriodInsights.fromMap(data['thisWeek'] ?? {}),
      thisMonth: PeriodInsights.fromMap(data['thisMonth'] ?? {}),
      thisYear: PeriodInsights.fromMap(data['thisYear'] ?? {}),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      version: data['version'] ?? 1,
      validation: ValidationMeta.fromMap(data['validation'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'today': today.toMap(),
      'thisWeek': thisWeek.toMap(),
      'thisMonth': thisMonth.toMap(),
      'thisYear': thisYear.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'version': version,
      'validation': validation.toMap(),
    };
  }

  UserInsightSummary copyWith({
    PeriodInsights? today,
    PeriodInsights? thisWeek,
    PeriodInsights? thisMonth,
    PeriodInsights? thisYear,
    DateTime? lastUpdated,
    int? version,
    ValidationMeta? validation,
  }) {
    return UserInsightSummary(
      userId: userId,
      today: today ?? this.today,
      thisWeek: thisWeek ?? this.thisWeek,
      thisMonth: thisMonth ?? this.thisMonth,
      thisYear: thisYear ?? this.thisYear,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      validation: validation ?? this.validation,
    );
  }

  // Period boundary helpers
  static DateTime _getToday(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  static DateTime _getMonthStart(DateTime date) =>
      DateTime(date.year, date.month, 1);
  static DateTime _getYearStart(DateTime date) => DateTime(date.year, 1, 1);
}

class PeriodInsights {
  final double totalMiles;
  final int totalDurationInSeconds;
  final double totalEarnings;
  final double totalExpenses;
  final int sessionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  PeriodInsights({
    required this.totalMiles,
    required this.totalDurationInSeconds,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.sessionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  factory PeriodInsights.empty(DateTime periodStart) {
    return PeriodInsights(
      totalMiles: 0.0,
      totalDurationInSeconds: 0,
      totalEarnings: 0.0,
      totalExpenses: 0.0,
      sessionCount: 0,
      periodStart: periodStart,
      periodEnd: periodStart,
    );
  }

  factory PeriodInsights.fromMap(Map<String, dynamic> data) {
    return PeriodInsights(
      totalMiles: (data['totalMiles'] ?? 0.0).toDouble(),
      totalDurationInSeconds: data['totalDurationInSeconds'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      totalExpenses: (data['totalExpenses'] ?? 0.0).toDouble(),
      sessionCount: data['sessionCount'] ?? 0,
      periodStart:
          (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMiles': totalMiles,
      'totalDurationInSeconds': totalDurationInSeconds,
      'totalEarnings': totalEarnings,
      'totalExpenses': totalExpenses,
      'sessionCount': sessionCount,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
    };
  }

  // Quick calculations
  double get hours => totalDurationInSeconds / 3600;
  double get netEarnings => totalEarnings - totalExpenses;

  PeriodInsights add(PeriodInsights other) {
    return PeriodInsights(
      totalMiles: totalMiles + other.totalMiles,
      totalDurationInSeconds:
          totalDurationInSeconds + other.totalDurationInSeconds,
      totalEarnings: totalEarnings + other.totalEarnings,
      totalExpenses: totalExpenses + other.totalExpenses,
      sessionCount: sessionCount + other.sessionCount,
      periodStart: periodStart,
      periodEnd:
          periodEnd.isAfter(other.periodEnd) ? periodEnd : other.periodEnd,
    );
  }

  PeriodInsights subtract(PeriodInsights other) {
    return PeriodInsights(
      totalMiles: (totalMiles - other.totalMiles).clamp(0.0, double.infinity),
      totalDurationInSeconds:
          (totalDurationInSeconds - other.totalDurationInSeconds)
              .clamp(0, 999999999),
      totalEarnings:
          (totalEarnings - other.totalEarnings).clamp(0.0, double.infinity),
      totalExpenses:
          (totalExpenses - other.totalExpenses).clamp(0.0, double.infinity),
      sessionCount: (sessionCount - other.sessionCount).clamp(0, 999999),
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}

class ValidationMeta {
  final DateTime lastValidated;
  final String lastValidatedPeriod;
  final bool needsValidation;
  final int consecutiveSuccessfulValidations;

  ValidationMeta({
    required this.lastValidated,
    required this.lastValidatedPeriod,
    required this.needsValidation,
    required this.consecutiveSuccessfulValidations,
  });

  factory ValidationMeta.initial() {
    final now = DateTime.now();
    return ValidationMeta(
      lastValidated: now,
      lastValidatedPeriod:
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
      needsValidation: true,
      consecutiveSuccessfulValidations: 0,
    );
  }

  factory ValidationMeta.fromMap(Map<String, dynamic> data) {
    return ValidationMeta(
      lastValidated:
          (data['lastValidated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastValidatedPeriod: data['lastValidatedPeriod'] ?? '',
      needsValidation: data['needsValidation'] ?? true,
      consecutiveSuccessfulValidations:
          data['consecutiveSuccessfulValidations'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastValidated': Timestamp.fromDate(lastValidated),
      'lastValidatedPeriod': lastValidatedPeriod,
      'needsValidation': needsValidation,
      'consecutiveSuccessfulValidations': consecutiveSuccessfulValidations,
    };
  }

  ValidationMeta copyWith({
    DateTime? lastValidated,
    String? lastValidatedPeriod,
    bool? needsValidation,
    int? consecutiveSuccessfulValidations,
  }) {
    return ValidationMeta(
      lastValidated: lastValidated ?? this.lastValidated,
      lastValidatedPeriod: lastValidatedPeriod ?? this.lastValidatedPeriod,
      needsValidation: needsValidation ?? this.needsValidation,
      consecutiveSuccessfulValidations: consecutiveSuccessfulValidations ??
          this.consecutiveSuccessfulValidations,
    );
  }
}

class PendingInsightUpdate {
  final String id;
  final String userId;
  final Map<String, dynamic> sessionData;
  final InsightUpdateType type;
  final DateTime timestamp;
  final int retryCount;

  PendingInsightUpdate({
    required this.id,
    required this.userId,
    required this.sessionData,
    required this.type,
    required this.timestamp,
    required this.retryCount,
  });

  factory PendingInsightUpdate.fromMap(Map<String, dynamic> data) {
    return PendingInsightUpdate(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      sessionData: Map<String, dynamic>.from(data['sessionData'] ?? {}),
      type: InsightUpdateType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => InsightUpdateType.sessionEnd,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      retryCount: data['retryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sessionData': sessionData,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'retryCount': retryCount,
    };
  }
}

enum InsightUpdateType {
  sessionEnd,
  sessionEdit,
  sessionDelete,
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final double discrepancy;
  final ValidationSeverity severity;
  final String message;

  ValidationResult({
    required this.isValid,
    required this.discrepancy,
    required this.severity,
    required this.message,
  });
}

enum ValidationSeverity {
  info,
  warning,
  error,
  critical,
}
