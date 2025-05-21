// lib/core/services/schedule_notification_service.dart
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
    tz.initializeTimeZones();
  }

  final NotificationService _notificationService = NotificationService();

  // Base IDs for notifications
  static const int _startNotificationIdBase = 2000;
  static const int _endNotificationIdBase = 2100;

  // Map to store schedule information for comparison
  // This helps detect changes and avoid duplicate notifications
  final Map<String, ScheduleInfo> _scheduleRegistry = {};

  // Schedule notifications for an entire week based on user's schedule
  Future<void> scheduleWeeklyNotifications(ScheduleModel? schedule) async {
    if (schedule == null) return;

    // First, generate the current schedule info map for comparison
    final Map<String, ScheduleInfo> newScheduleInfo = {};

    schedule.weeklySchedule.forEach((day, daySchedule) {
      if (daySchedule != null) {
        newScheduleInfo[day] = ScheduleInfo(
          startHour: daySchedule.timeRange.start.hour,
          startMinute: daySchedule.timeRange.start.minute,
          endHour: daySchedule.timeRange.end.hour,
          endMinute: daySchedule.timeRange.end.minute,
        );
      }
    });

    // Compare with existing schedule and update only what changed
    await _updateScheduleNotifications(
        newScheduleInfo, schedule.employmentType);
  }

  // Update schedule notifications based on changes
  Future<void> _updateScheduleNotifications(
    Map<String, ScheduleInfo> newScheduleInfo,
    String employmentType,
  ) async {
    // Find days that need to be canceled (removed schedules)
    final List<String> daysToCancel = [];
    _scheduleRegistry.forEach((day, info) {
      if (!newScheduleInfo.containsKey(day)) {
        daysToCancel.add(day);
      }
    });

    // Cancel removed schedules
    for (final day in daysToCancel) {
      await _cancelDayNotifications(day);
      _scheduleRegistry.remove(day);
      debugPrint('Canceled schedule notifications for $day');
    }

    // Update or create schedules for days in the new schedule
    newScheduleInfo.forEach((day, newInfo) async {
      if (_scheduleRegistry.containsKey(day)) {
        // Check if schedule has changed
        if (_scheduleRegistry[day]!.startHour != newInfo.startHour ||
            _scheduleRegistry[day]!.startMinute != newInfo.startMinute ||
            _scheduleRegistry[day]!.endHour != newInfo.endHour ||
            _scheduleRegistry[day]!.endMinute != newInfo.endMinute) {
          // Schedule has changed, cancel old and create new
          await _cancelDayNotifications(day);
          await _scheduleDayNotifications(
            day,
            newInfo,
            employmentType,
            isUpdate: true,
          );

          _scheduleRegistry[day] = newInfo;
          debugPrint('Updated schedule notifications for $day');
        }
        // If unchanged, do nothing to avoid duplicate notifications
      } else {
        // New schedule day, create notifications
        await _scheduleDayNotifications(day, newInfo, employmentType);
        _scheduleRegistry[day] = newInfo;
        debugPrint('Created new schedule notifications for $day');
      }
    });
  }

  // Schedule notifications for a specific day
  Future<void> _scheduleDayNotifications(
    String dayName,
    ScheduleInfo info,
    String employmentType, {
    bool isUpdate = false,
  }) async {
    final int dayIndex = _getDayIndex(dayName);
    if (dayIndex == -1) return;

    final now = DateTime.now();

    // Calculate the next occurrence of this weekday
    final daysUntilTarget = (dayIndex - now.weekday + 7) % 7;
    final nextOccurrence =
        DateTime(now.year, now.month, now.day + daysUntilTarget);

    // Generate unique notification IDs for this day
    final startId = _startNotificationIdBase + (dayIndex * 10);
    final endId = _endNotificationIdBase + (dayIndex * 10);

    // Schedule start notification (15 minutes before)
    final startTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      info.startHour,
      info.startMinute,
    ).subtract(const Duration(minutes: 15));

    // Only schedule if the time is in the future
    if (startTime.isAfter(now)) {
      await _scheduleNotification(
        id: startId,
        title: 'Shift Starting Soon',
        body: 'Your $dayName shift is starting in 15 minutes.',
        scheduledTime: startTime,
        payload: 'schedule_start_$dayName',
      );
    }

    // Check if this is an overnight shift (end time earlier than start time)
    final bool isOvernightShift = info.endHour < info.startHour ||
        (info.endHour == info.startHour && info.endMinute < info.startMinute);

    // Schedule end notification (15 minutes before)
    final endTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day + (isOvernightShift ? 1 : 0), // Next day if overnight
      info.endHour,
      info.endMinute,
    ).subtract(const Duration(minutes: 15));

    if (endTime.isAfter(now)) {
      await _scheduleNotification(
        id: endId,
        title: 'Shift Ending Soon',
        body: 'Your $dayName shift is ending in 15 minutes.',
        scheduledTime: endTime,
        payload: 'schedule_end_$dayName',
      );
    }

    // Log what we scheduled
    debugPrint('Scheduled notifications for $dayName:');
    debugPrint('- Start: ${startTime.toString()}, ID: $startId');
    debugPrint(
        '- End: ${endTime.toString()} (${isOvernightShift ? "overnight shift" : "same-day shift"}), ID: $endId');
  }

  // Cancel notifications for a specific day
  Future<void> _cancelDayNotifications(String dayName) async {
    try {
      final flutterLocalNotificationsPlugin = _notificationService.plugin;
      final dayIndex = _getDayIndex(dayName);

      if (dayIndex == -1) return;

      // Cancel start and end notifications for this day
      await flutterLocalNotificationsPlugin
          .cancel(_startNotificationIdBase + (dayIndex * 10));
      await flutterLocalNotificationsPlugin
          .cancel(_endNotificationIdBase + (dayIndex * 10));

      debugPrint('Canceled notifications for $dayName');
    } catch (e) {
      debugPrint('Error canceling day notifications: $e');
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
    final flutterLocalNotificationsPlugin = _notificationService.plugin;

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
      // First cancel any existing notification with this ID
      await flutterLocalNotificationsPlugin.cancel(id);

      // Then schedule the new notification
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
      final flutterLocalNotificationsPlugin = _notificationService.plugin;

      // Cancel notifications for each day that we have registered
      for (final day in _scheduleRegistry.keys) {
        final dayIndex = _getDayIndex(day);
        if (dayIndex != -1) {
          await flutterLocalNotificationsPlugin
              .cancel(_startNotificationIdBase + (dayIndex * 10));
          await flutterLocalNotificationsPlugin
              .cancel(_endNotificationIdBase + (dayIndex * 10));
        }
      }

      // Clear our registry
      _scheduleRegistry.clear();

      debugPrint('Canceled all schedule notifications');
    } catch (e) {
      debugPrint('Error canceling schedule notifications: $e');
    }
  }

  // Handle notification payload when tapped
  void handleNotificationPayload(String payload) {
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

// Class to store schedule information for comparison
class ScheduleInfo {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  ScheduleInfo({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}
