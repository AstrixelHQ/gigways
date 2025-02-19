import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// Enum for notification channels
enum NotificationChannel {
  driving(
    id: 'driving_status',
    name: 'Driving Status',
    description: 'Notifications for driving status updates',
    importance: Importance.high,
  ),
  breaks(
    id: 'break_time',
    name: 'Break Time',
    description: 'Notifications for break time reminders',
    importance: Importance.high,
  ),
  schedule(
    id: 'schedule',
    name: 'Schedule Updates',
    description: 'Notifications for schedule changes',
    importance: Importance.min,
  ),
  system(
    id: 'system',
    name: 'System',
    description: 'System notifications and updates',
    importance: Importance.low,
  );

  final String id;
  final String name;
  final String description;
  final Importance importance;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
  });
}

// Notification data model
class NotificationData {
  final String title;
  final String body;
  final NotificationChannel channel;
  final String? payload;
  final bool ongoing;
  final Color? color;
  final int? id;
  final Duration? timeoutAfter;
  final bool autoCancel;

  const NotificationData({
    required this.title,
    required this.body,
    required this.channel,
    this.payload,
    this.ongoing = false,
    this.color,
    this.id,
    this.timeoutAfter,
    this.autoCancel = true,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller for notification taps
  final _notificationTapController = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _notificationTapController.stream;

  int _notificationId = 0;

  // Initialize notification service
  Future<void> initialize() async {
    print('🔔 Initializing notification service...');

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings for all platforms
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize notifications
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    print('✅ Notification service initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (var channel in NotificationChannel.values) {
        final androidChannel = AndroidNotificationChannel(
          channel.id,
          channel.name,
          description: channel.description,
          importance: channel.importance,
        );

        await androidPlugin.createNotificationChannel(androidChannel);
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    _notificationTapController.add(response.payload);
  }

  Future<void> show(NotificationData notification) async {
    try {
      final id = notification.id ?? _getNextNotificationId();

      print('🔔 Showing notification: ${notification.title}');

      final androidDetails = AndroidNotificationDetails(
        notification.channel.id,
        notification.channel.name,
        channelDescription: notification.channel.description,
        importance: notification.channel.importance,
        priority: Priority.high,
        ongoing: notification.ongoing,
        autoCancel: notification.autoCancel,
        color: notification.color,
        timeoutAfter: notification.timeoutAfter?.inMilliseconds,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        notification.title,
        notification.body,
        details,
        payload: notification.payload,
      );
    } catch (e) {
      print('❌ Failed to show notification: $e');
    }
  }

  // Cancel a specific notification
  Future<void> cancel(int id) async {
    print('🔔 Cancelling notification: $id');
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    print('🔔 Cancelling all notifications');
    await _notifications.cancelAll();
  }

  // Get next notification ID
  int _getNextNotificationId() {
    return _notificationId++;
  }

  // Clean up resources
  void dispose() {
    _notificationTapController.close();
  }
}

// Extension for driving-specific notifications
extension DrivingNotifications on NotificationService {
  Future<void> showDrivingStarted() async {
    await show(
      const NotificationData(
        id: 1001,
        title: 'Driving Detected',
        body: 'You are currently driving. Stay safe!',
        channel: NotificationChannel.driving,
        ongoing: true,
        autoCancel: false,
        color: Colors.blue,
        payload: 'driving_started',
      ),
    );
  }

  Future<void> showDrivingStopped() async {
    await cancel(1001); // Cancel ongoing driving notification
    await show(
      const NotificationData(
        id: 1002,
        title: 'Driving Ended',
        body: 'Your driving session has ended.',
        channel: NotificationChannel.driving,
        color: Colors.green,
        payload: 'driving_stopped',
      ),
    );
  }
}

// Extension for break-related notifications
extension BreakNotifications on NotificationService {
  Future<void> showBreakReminder({
    required String startTime,
    required int participants,
  }) async {
    await show(
      NotificationData(
        id: 2001,
        title: 'Break Time Reminder',
        body: 'Scheduled break at $startTime with $participants participants',
        channel: NotificationChannel.breaks,
        color: Colors.orange,
        payload: 'break_reminder',
      ),
    );
  }
}
