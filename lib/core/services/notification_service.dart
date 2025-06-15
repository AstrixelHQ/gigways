import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

enum NotificationChannel {
  driving(
    id: 'driving_status',
    name: 'Driving & Work Status',
    description: 'Smart notifications for driving detection and work session tracking',
    importance: Importance.high,
  ),
  breaks(
    id: 'break_time',
    name: 'Break & Rest Reminders',
    description: 'Intelligent break suggestions and safety reminders',
    importance: Importance.high,
  ),
  schedule(
    id: 'schedule',
    name: 'Schedule & Shift Updates',
    description: 'Work schedule notifications and shift reminders',
    importance: Importance.defaultImportance,
  ),
  system(
    id: 'system',
    name: 'System & Earnings',
    description: 'System updates, earnings notifications, and app insights',
    importance: Importance.low,
  ),
  safety(
    id: 'safety_alerts',
    name: 'Safety Alerts',
    description: 'Important safety notifications for long driving sessions',
    importance: Importance.max,
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

  FlutterLocalNotificationsPlugin get plugin => _notifications;

  // Stream controller for notification taps
  final _notificationTapController = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _notificationTapController.stream;

  // Static reference to instance for background handler
  static NotificationService? _staticInstance;

  int _notificationId = 1000; // Start at 1000 for dynamic IDs

  // Initialize notification service
  Future<void> initialize() async {
    debugPrint('Initializing notification service...');
    // Set static instance
    _staticInstance = this;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'actionable',
          actions: [
            DarwinNotificationAction.plain(
              'stop',
              'Stop Tracking',
              options: {DarwinNotificationActionOption.destructive},
            ),
            DarwinNotificationAction.plain(
              'continue',
              'Continue',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      // Use the top-level function for background response
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    debugPrint('Notification service initialized');
  }

  // Static method to handle background notification taps
  static void handleBackgroundResponse(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
    // We can only add to the stream when the instance exists
    _staticInstance?._notificationTapController.add(response.payload);
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
    debugPrint('Notification tapped: ${response.payload}');
    _notificationTapController.add(response.payload);
  }

  Future<void> show(NotificationData notification) async {
    try {
      final id = notification.id ?? _getNextNotificationId();

      debugPrint('Showing notification: ${notification.title}');

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

        // Allow notification to show when app is in foreground
        channelShowBadge: true,
        showWhen: true,

        // For driving detection - make it more noticeable
        vibrationPattern: notification.channel == NotificationChannel.driving
            ? Int64List.fromList([0, 1000, 500, 1000])
            : null,

        // For ongoing notifications, show a timestamp
        usesChronometer: notification.ongoing,
        chronometerCountDown: false,

        // Actions for notifications
        actions: notification.payload == 'inactivity_detected'
            ? [
                const AndroidNotificationAction('stop', 'End Tracking'),
                const AndroidNotificationAction('continue', 'Continue'),
              ]
            : null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier:
            notification.payload == 'inactivity_detected' ? 'actionable' : null,
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
      debugPrint('Failed to show notification: $e');
    }
  }

  // Cancel a specific notification
  Future<void> cancel(int id) async {
    debugPrint('Cancelling notification: $id');
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    debugPrint('Cancelling all notifications');
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
