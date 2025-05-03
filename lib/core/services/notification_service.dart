import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

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

@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService();
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

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(initializationSettings);

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
