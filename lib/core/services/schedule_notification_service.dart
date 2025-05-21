import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:gigways/features/schedule/models/schedule_models.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_notification_service.g.dart';

@Riverpod(keepAlive: true)
ScheduleNotificationService scheduleNotificationService(Ref ref) {
  return ScheduleNotificationService();
}

class ScheduleNotificationService {
  static final ScheduleNotificationService _instance =
      ScheduleNotificationService._internal();
  factory ScheduleNotificationService() => _instance;

  ScheduleNotificationService._internal() {
    // Initialize timezone data
    tz.initializeTimeZones();
  }

  final NotificationService _notificationService = NotificationService();

  // Notification IDs - using a range to avoid conflicts with other notifications
  // 2000-2099: Start notifications
  // 2100-2199: End notifications
  static const int _startNotificationIdBase = 2000;
  static const int _endNotificationIdBase = 2100;

  // Map to store notification IDs for each day
  final Map<String, int> _scheduledNotificationIds = {};

  // Schedule notifications for an entire week
  Future<void> scheduleWeeklyNotifications(ScheduleModel? schedule) async {
    if (schedule == null) return;

    // Cancel all previous schedule notifications
    await cancelAllScheduleNotifications();

    // Create notifications for each day with a schedule
    schedule.weeklySchedule.forEach((day, daySchedule) {
      if (daySchedule != null) {
        _scheduleForDay(day, daySchedule, schedule.employmentType);
      }
    });
  }

  // Schedule notifications for a specific day
  Future<void> _scheduleForDay(
    String dayName,
    DayScheduleModel daySchedule,
    String employmentType,
  ) async {
    final int dayIndex = _getDayIndex(dayName);
    if (dayIndex == -1) return;

    final now = DateTime.now();

    // Calculate the next occurrence of this weekday
    final daysUntilTarget = (dayIndex - now.weekday + 7) % 7;
    final nextOccurrence =
        DateTime(now.year, now.month, now.day + daysUntilTarget);

    // Create start time
    final startHour = daySchedule.timeRange.start.hour;
    final startMinute = daySchedule.timeRange.start.minute;

    // Create end time
    final endHour = daySchedule.timeRange.end.hour;
    final endMinute = daySchedule.timeRange.end.minute;

    // Schedule start notification (15 minutes before)
    final startTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      startHour,
      startMinute,
    ).subtract(const Duration(minutes: 15));

    // Only schedule if the time is in the future
    if (startTime.isAfter(now)) {
      final startId = _startNotificationIdBase + dayIndex;
      _scheduleNotification(
        id: startId,
        title: 'Shift Starting Soon',
        body: 'Your $dayName shift is starting in 15 minutes.',
        scheduledTime: startTime,
        payload: 'schedule_start_$dayName',
      );

      // Store notification ID
      _scheduledNotificationIds['${dayName}_start'] = startId;
    }

    // Schedule end notification (15 minutes before)
    final endTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      endHour,
      endMinute,
    ).subtract(const Duration(minutes: 15));

    if (endTime.isAfter(now)) {
      final endId = _endNotificationIdBase + dayIndex;
      _scheduleNotification(
        id: endId,
        title: 'Shift Ending Soon',
        body: 'Your $dayName shift is ending in 15 minutes.',
        scheduledTime: endTime,
        payload: 'schedule_end_$dayName',
      );

      // Store notification ID
      _scheduledNotificationIds['${dayName}_end'] = endId;
    }

    // Schedule recurring notifications for next week(s)
    // This ensures notifications continue even after the first week
    _scheduleRecurringNotifications(dayName, daySchedule, employmentType);
  }

  // Schedule the same notifications 7 days later to maintain recurring pattern
  Future<void> _scheduleRecurringNotifications(
    String dayName,
    DayScheduleModel daySchedule,
    String employmentType,
  ) async {
    // Schedule for the next few weeks to ensure coverage
    for (int weekOffset = 1; weekOffset <= 4; weekOffset++) {
      final now = DateTime.now();
      final dayIndex = _getDayIndex(dayName);
      if (dayIndex == -1) continue;

      // Calculate the target day with week offset
      final daysUntilTarget = (dayIndex - now.weekday + 7) % 7;
      final futureOccurrence = DateTime(
          now.year, now.month, now.day + daysUntilTarget + (weekOffset * 7));

      // Schedule start notification for future week
      final futureStartTime = DateTime(
        futureOccurrence.year,
        futureOccurrence.month,
        futureOccurrence.day,
        daySchedule.timeRange.start.hour,
        daySchedule.timeRange.start.minute,
      ).subtract(const Duration(minutes: 15));

      final futureStartId =
          _startNotificationIdBase + dayIndex + (weekOffset * 10);
      _scheduleNotification(
        id: futureStartId,
        title: 'Shift Starting Soon',
        body: 'Your $dayName shift is starting in 15 minutes.',
        scheduledTime: futureStartTime,
        payload: 'schedule_start_${dayName}_future_$weekOffset',
      );

      // Schedule end notification for future week
      final futureEndTime = DateTime(
        futureOccurrence.year,
        futureOccurrence.month,
        futureOccurrence.day,
        daySchedule.timeRange.end.hour,
        daySchedule.timeRange.end.minute,
      ).subtract(const Duration(minutes: 15));

      final futureEndId = _endNotificationIdBase + dayIndex + (weekOffset * 10);
      _scheduleNotification(
        id: futureEndId,
        title: 'Shift Ending Soon',
        body: 'Your $dayName shift is ending in 15 minutes.',
        scheduledTime: futureEndTime,
        payload: 'schedule_end_${dayName}_future_$weekOffset',
      );

      // Store these IDs too
      _scheduledNotificationIds['${dayName}_start_future_$weekOffset'] =
          futureStartId;
      _scheduledNotificationIds['${dayName}_end_future_$weekOffset'] =
          futureEndId;
    }
  }

  // Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final flutterLocalNotificationsPlugin = _notificationService._notifications;

    final tzDateTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Schedule Notifications',
      channelDescription: 'Notifications for your work schedule',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFC7B299), // Golden color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
          'Scheduled notification for ${scheduledTime.toString()}, ID: $id');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Convert day name to index (Monday = 1, Sunday = 7)
  int _getDayIndex(String dayName) {
    switch (dayName) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      default:
        return -1;
    }
  }

  // Cancel all schedule-related notifications
  Future<void> cancelAllScheduleNotifications() async {
    try {
      final flutterLocalNotificationsPlugin =
          _notificationService._notifications;

      // Cancel by ID range
      for (int id = _startNotificationIdBase;
          id < _startNotificationIdBase + 100;
          id++) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }

      for (int id = _endNotificationIdBase;
          id < _endNotificationIdBase + 100;
          id++) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }

      // Also cancel notifications stored in our tracking map
      _scheduledNotificationIds.forEach((key, id) async {
        await flutterLocalNotificationsPlugin.cancel(id);
      });

      _scheduledNotificationIds.clear();

      debugPrint('Canceled all schedule notifications');
    } catch (e) {
      debugPrint('Error canceling schedule notifications: $e');
    }
  }

  // Handle notification interactions
  void handleNotificationPayload(String? payload) {
    if (payload == null) return;

    if (payload.startsWith('schedule_start_')) {
      // Handle start shift notification
      debugPrint('User tapped on shift start notification');
      // Navigate to schedule page or show relevant info
    } else if (payload.startsWith('schedule_end_')) {
      // Handle end shift notification
      debugPrint('User tapped on shift end notification');
      // Navigate to schedule page or show relevant info
    }
  }
}
