/// Represents a complete user schedule
class ScheduleModel {
  final String employmentType; // "Part-Time" or "Full-Time"
  final String shiftPreference; // "Day" or "Night"
  final Map<String, DayScheduleModel?> weeklySchedule;

  ScheduleModel({
    required this.employmentType,
    required this.shiftPreference,
    required this.weeklySchedule,
  });

  // Create a default schedule with null values for all days
  factory ScheduleModel.defaultSchedule() {
    final Map<String, DayScheduleModel?> defaultWeeklySchedule = {
      'Monday': null,
      'Tuesday': null,
      'Wednesday': null,
      'Thursday': null,
      'Friday': null,
      'Saturday': null,
      'Sunday': null,
    };

    return ScheduleModel(
      employmentType: 'Part-Time',
      shiftPreference: 'Day',
      weeklySchedule: defaultWeeklySchedule,
    );
  }

  // Create from Firestore data
  factory ScheduleModel.fromMap(Map<String, dynamic> data) {
    final Map<String, DayScheduleModel?> scheduleMap = {};

    // Get weekly schedule data
    final Map<String, dynamic>? weeklyData = data['weeklySchedule'];

    if (weeklyData != null) {
      for (final day in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ]) {
        final dayData = weeklyData[day];
        if (dayData != null) {
          scheduleMap[day] = DayScheduleModel.fromMap(dayData);
        } else {
          scheduleMap[day] = null;
        }
      }
    } else {
      // Create default empty schedule if no data exists
      for (final day in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ]) {
        scheduleMap[day] = null;
      }
    }

    return ScheduleModel(
      employmentType: data['employmentType'] ?? 'Part-Time',
      shiftPreference: data['shiftPreference'] ?? 'Day',
      weeklySchedule: scheduleMap,
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> weeklyScheduleMap = {};

    weeklySchedule.forEach((day, schedule) {
      if (schedule != null) {
        weeklyScheduleMap[day] = schedule.toMap();
      }
    });

    return {
      'employmentType': employmentType,
      'shiftPreference': shiftPreference,
      'weeklySchedule': weeklyScheduleMap,
    };
  }

  // Create a copy with updated values
  ScheduleModel copyWith({
    String? employmentType,
    String? shiftPreference,
    Map<String, DayScheduleModel?>? weeklySchedule,
  }) {
    return ScheduleModel(
      employmentType: employmentType ?? this.employmentType,
      shiftPreference: shiftPreference ?? this.shiftPreference,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
    );
  }
}

/// Represents a single day's schedule
class DayScheduleModel {
  final TimeRangeModel timeRange;

  DayScheduleModel({
    required this.timeRange,
  });

  factory DayScheduleModel.fromMap(Map<String, dynamic> data) {
    return DayScheduleModel(
      timeRange: TimeRangeModel.fromMap(data['timeRange'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeRange': timeRange.toMap(),
    };
  }

  DayScheduleModel copyWith({
    TimeRangeModel? timeRange,
  }) {
    return DayScheduleModel(
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

/// Represents a time range with start and end times
class TimeRangeModel {
  final TimeOfDayModel start;
  final TimeOfDayModel end;

  TimeRangeModel({
    required this.start,
    required this.end,
  });

  factory TimeRangeModel.fromMap(Map<String, dynamic> data) {
    return TimeRangeModel(
      start: TimeOfDayModel.fromMap(data['start'] ?? {'hour': 9, 'minute': 0}),
      end: TimeOfDayModel.fromMap(data['end'] ?? {'hour': 17, 'minute': 0}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start.toMap(),
      'end': end.toMap(),
    };
  }

  // Format time range as a string (e.g., "9:00 AM - 5:00 PM")
  String format() {
    return '${start.format()} - ${end.format()}';
  }
}

/// Represents a time of day with hour and minute
class TimeOfDayModel {
  final int hour;
  final int minute;

  TimeOfDayModel({
    required this.hour,
    required this.minute,
  });

  factory TimeOfDayModel.fromMap(Map<String, dynamic> data) {
    return TimeOfDayModel(
      hour: data['hour'] ?? 0,
      minute: data['minute'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  // Format time as a string (e.g., "9:00 AM")
  String format() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}
