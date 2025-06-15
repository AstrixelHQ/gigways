import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'driving_detection_service.g.dart';

/// Represents a driving session with accumulated driving time and breaks
class DrivingSession {
  final DateTime sessionStartTime;
  final Duration accumulatedDrivingTime;
  final DateTime? currentDrivingStartTime;
  final DateTime? lastStopTime;
  final bool hasShownWarning;
  final bool hasShownRestAlert;

  DrivingSession({
    required this.sessionStartTime,
    required this.accumulatedDrivingTime,
    this.currentDrivingStartTime,
    this.lastStopTime,
    this.hasShownWarning = false,
    this.hasShownRestAlert = false,
  });

  /// Copy session with updated values
  DrivingSession copyWith({
    DateTime? sessionStartTime,
    Duration? accumulatedDrivingTime,
    DateTime? currentDrivingStartTime,
    DateTime? lastStopTime,
    bool? hasShownWarning,
    bool? hasShownRestAlert,
  }) {
    return DrivingSession(
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      accumulatedDrivingTime:
          accumulatedDrivingTime ?? this.accumulatedDrivingTime,
      currentDrivingStartTime: currentDrivingStartTime,
      lastStopTime: lastStopTime,
      hasShownWarning: hasShownWarning ?? this.hasShownWarning,
      hasShownRestAlert: hasShownRestAlert ?? this.hasShownRestAlert,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'sessionStartTime': sessionStartTime.millisecondsSinceEpoch,
      'accumulatedDrivingTime': accumulatedDrivingTime.inMilliseconds,
      'currentDrivingStartTime':
          currentDrivingStartTime?.millisecondsSinceEpoch,
      'lastStopTime': lastStopTime?.millisecondsSinceEpoch,
      'hasShownWarning': hasShownWarning,
      'hasShownRestAlert': hasShownRestAlert,
    };
  }

  /// Create from JSON
  factory DrivingSession.fromJson(Map<String, dynamic> json) {
    return DrivingSession(
      sessionStartTime:
          DateTime.fromMillisecondsSinceEpoch(json['sessionStartTime']),
      accumulatedDrivingTime:
          Duration(milliseconds: json['accumulatedDrivingTime']),
      currentDrivingStartTime: json['currentDrivingStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['currentDrivingStartTime'])
          : null,
      lastStopTime: json['lastStopTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastStopTime'])
          : null,
      hasShownWarning: json['hasShownWarning'] ?? false,
      hasShownRestAlert: json['hasShownRestAlert'] ?? false,
    );
  }

  /// Get total driving time including current session
  Duration get totalDrivingTime {
    Duration total = accumulatedDrivingTime;
    if (currentDrivingStartTime != null) {
      total += DateTime.now().difference(currentDrivingStartTime!);
    }
    return total;
  }

  /// Check if currently driving
  bool get isCurrentlyDriving => currentDrivingStartTime != null;

  @override
  String toString() {
    return 'DrivingSession(accumulated: ${accumulatedDrivingTime.inMinutes}min, '
        'total: ${totalDrivingTime.inMinutes}min, currentlyDriving: $isCurrentlyDriving)';
  }
}

class DrivingDetectionService {
  static final DrivingDetectionService _instance =
      DrivingDetectionService._internal();
  factory DrivingDetectionService() => _instance;
  DrivingDetectionService._internal();

  // Subscriptions for activity recognition
  StreamSubscription<ActivityEvent>? _activitySubscription;

  // Notification service - get the singleton instance
  late NotificationService _notificationService;

  // Ref for accessing providers
  Ref? _ref;

  // Track last detected driving state to avoid duplicate notifications
  bool _lastDrivingState = false;

  // Control flag to enable/disable automatic detection
  bool _isDetectionEnabled = true;

  // Buffer for driving detection (to wait for continuous detection)
  DateTime? _drivingStartTime;
  Timer? _drivingDetectionTimer;

  // Threshold for continuous driving detection in seconds
  static const int _drivingDetectionThreshold =
      10; // 10 seconds - faster detection

  // Time interval between notifications (30 minutes after first notification)
  static const Duration _notificationInterval = Duration(minutes: 30);

  // Track if this is the first notification of the day
  bool _isFirstNotificationOfDay = true;
  DateTime? _lastNotificationDate;

  // Driving session tracking for rest notifications
  static const Duration _restNotificationThreshold = Duration(hours: 2);
  static const Duration _shortBreakThreshold = Duration(minutes: 10);
  static const Duration _sessionResetThreshold = Duration(minutes: 15);
  static const Duration _warningNotificationThreshold =
      Duration(minutes: 90); // 1.5 hours

  // SharedPreferences keys
  static const String _lastNotificationTimeKey =
      'last_driving_notification_time';
  static const String _drivingSessionKey = 'current_driving_session';

  // Current driving session tracking
  DrivingSession? _currentSession;

  // Initialize the detection service
  Future<void> initialize() async {
    // Get notification service instance
    _notificationService = NotificationService();

    // Load existing driving session if any
    await _loadDrivingSession();

    // Start activity recognition
    final activityRecognition = ActivityRecognition();

    _activitySubscription = activityRecognition.activityStream().listen(
      (ActivityEvent event) {
        _handleActivityChange(event);
      },
      onError: (error) {
        debugPrint('Activity Recognition Error: $error');
      },
    );

    debugPrint('Driving detection service initialized');
  }

  // Handle activity changes
  void _handleActivityChange(ActivityEvent event) {
    final bool isDriving = event.type == ActivityType.IN_VEHICLE;

    // Check if detection is enabled
    if (!_isDetectionEnabled) {
      _cancelDrivingDetectionTimer();
      return;
    }

    // Handle driving session tracking
    _handleDrivingSessionChange(isDriving);

    // Handle driving detection notifications (original logic)
    _handleDrivingDetectionChange(isDriving);

    _lastDrivingState = isDriving;
  }

  // Handle driving session tracking for rest notifications
  void _handleDrivingSessionChange(bool isDriving) async {
    if (!await _isWithinWorkingHours()) {
      // Reset session if outside working hours
      if (_currentSession != null) {
        await _resetDrivingSession();
      }
      return;
    }

    final now = DateTime.now();

    if (isDriving && !_lastDrivingState) {
      // Started driving
      await _handleDrivingStarted(now);
    } else if (!isDriving && _lastDrivingState) {
      // Stopped driving
      await _handleDrivingStopped(now);
    } else if (isDriving && _currentSession != null) {
      // Continue driving - check for rest notifications
      await _checkForRestNotifications();
    }
  }

  // Handle driving detection notifications (original logic)
  void _handleDrivingDetectionChange(bool isDriving) {
    // If we're detecting a transition to driving
    if (isDriving && !_lastDrivingState) {
      // Start timing the driving detection if not already started
      if (_drivingStartTime == null) {
        _drivingStartTime = DateTime.now();
        _startDrivingDetectionTimer();
      }
    }
    // If we're no longer driving
    else if (!isDriving && _lastDrivingState) {
      _cancelDrivingDetectionTimer();
      _drivingStartTime = null;
    }
  }

  // Start a timer to check if driving has been continuous for the threshold
  void _startDrivingDetectionTimer() {
    _cancelDrivingDetectionTimer();

    _drivingDetectionTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      // If driving has been detected for the threshold duration
      if (_drivingStartTime != null &&
          DateTime.now().difference(_drivingStartTime!).inSeconds >=
              _drivingDetectionThreshold) {
        _notifyDrivingDetected();
        _cancelDrivingDetectionTimer();
      }
    });
  }

  // Cancel the driving detection timer
  void _cancelDrivingDetectionTimer() {
    _drivingDetectionTimer?.cancel();
    _drivingDetectionTimer = null;
  }

  // Handle when driving starts
  Future<void> _handleDrivingStarted(DateTime now) async {
    if (_currentSession == null) {
      // Start new session
      _currentSession = DrivingSession(
        sessionStartTime: now,
        accumulatedDrivingTime: Duration.zero,
        currentDrivingStartTime: now,
      );
      debugPrint(
          'Started new driving session at ${_formatTime(now.hour, now.minute)}');
    } else {
      // Resume driving in existing session
      Duration? breakDuration;
      if (_currentSession!.lastStopTime != null) {
        breakDuration = now.difference(_currentSession!.lastStopTime!);
      }

      if (breakDuration != null && breakDuration > _sessionResetThreshold) {
        // Long break - reset session
        _currentSession = DrivingSession(
          sessionStartTime: now,
          accumulatedDrivingTime: Duration.zero,
          currentDrivingStartTime: now,
        );
        debugPrint(
            'Long break detected (${breakDuration.inMinutes}min) - started new session');
      } else {
        // Short break - resume session
        _currentSession = _currentSession!.copyWith(
          currentDrivingStartTime: now,
          lastStopTime: null,
        );
        debugPrint(
            'Resumed driving after ${breakDuration?.inMinutes ?? 0}min break');
      }
    }

    await _saveDrivingSession();
  }

  // Handle when driving stops
  Future<void> _handleDrivingStopped(DateTime now) async {
    if (_currentSession?.currentDrivingStartTime != null) {
      // Calculate driving time for this segment
      final segmentDuration =
          now.difference(_currentSession!.currentDrivingStartTime!);

      // Add to accumulated time
      _currentSession = _currentSession!.copyWith(
        accumulatedDrivingTime:
            _currentSession!.accumulatedDrivingTime + segmentDuration,
        currentDrivingStartTime: null,
        lastStopTime: now,
      );

      debugPrint(
          'Stopped driving after ${segmentDuration.inMinutes}min - total session: ${_currentSession!.accumulatedDrivingTime.inMinutes}min');
      await _saveDrivingSession();
    }
  }

  // Check if rest notifications should be sent
  Future<void> _checkForRestNotifications() async {
    if (_currentSession == null) return;

    final totalDrivingTime = _currentSession!.totalDrivingTime;

    // Check for 1.5 hour warning
    if (totalDrivingTime >= _warningNotificationThreshold &&
        !_currentSession!.hasShownWarning) {
      await _showRestWarningNotification();
      _currentSession = _currentSession!.copyWith(hasShownWarning: true);
      await _saveDrivingSession();
    }

    // Check for 2 hour rest alert
    if (totalDrivingTime >= _restNotificationThreshold &&
        !_currentSession!.hasShownRestAlert) {
      await _showRestAlertNotification();
      _currentSession = _currentSession!.copyWith(hasShownRestAlert: true);
      await _saveDrivingSession();
    }
  }

  // Show warning notification at 1.5 hours
  Future<void> _showRestWarningNotification() async {
    _notificationService.show(
      NotificationData(
        title: 'Long Drive Alert',
        body:
            'You\'ve been driving for 1.5 hours. Consider taking a break soon.',
        channel: NotificationChannel.driving,
        id: 102,
        payload: 'driving_warning',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 10),
      ),
    );
    debugPrint('Showed 1.5 hour warning notification');
  }

  // Show rest alert notification at 2 hours
  Future<void> _showRestAlertNotification() async {
    _notificationService.show(
      NotificationData(
        title: 'Take a Rest Break',
        body:
            'You\'ve been driving for 2 hours. Please take a 15-minute break for safety.',
        channel: NotificationChannel.driving,
        id: 103,
        payload: 'driving_rest_alert',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 15),
      ),
    );
    debugPrint('Showed 2 hour rest alert notification');
  }

  // Show notification for driving detection
  Future<void> _notifyDrivingDetected() async {
    if (!_isDetectionEnabled || _ref == null) return;

    // Check if user is within scheduled work hours
    final isWithinSchedule = await _isWithinWorkingHours();
    if (!isWithinSchedule) {
      debugPrint(
          'Driving detected outside of scheduled work hours - notification suppressed');
      return;
    }

    // Check if enough time has passed since last notification
    final canNotify = await _canShowNotification();
    if (!canNotify) {
      debugPrint(
          'Not enough time passed since last driving notification - notification suppressed');
      return;
    }

    // Save the current time as last notification time
    await _saveLastNotificationTime();

    _notificationService.show(
      NotificationData(
        title: 'Driving Detected',
        body:
            'We noticed you may be driving. Would you like to start tracking?',
        channel: NotificationChannel.driving,
        id: 101, // Fixed ID for driving detection notification
        payload: 'driving_detected',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 5),
      ),
    );

    debugPrint(
        'Driving notification shown - within schedule and interval requirements met');
  }

  // Check if current time is within user's scheduled working hours
  // NOTE: Schedule barriers removed as per requirements
  Future<bool> _isWithinWorkingHours() async {
    // Always return true - notifications allowed at any time
    return true;
  }

  // Check if enough time has passed since last notification
  // New logic: First notification immediately, then 30min intervals
  Future<bool> _canShowNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTimeMs = prefs.getInt(_lastNotificationTimeKey);
      final now = DateTime.now();

      // Check if this is a new day
      if (_lastNotificationDate == null ||
          _lastNotificationDate!.day != now.day ||
          _lastNotificationDate!.month != now.month ||
          _lastNotificationDate!.year != now.year) {
        _isFirstNotificationOfDay = true;
        _lastNotificationDate = now;
      }

      if (lastNotificationTimeMs == null || _isFirstNotificationOfDay) {
        debugPrint('First notification of day - allowing immediately');
        return true; // First notification of day, allow immediately
      }

      final lastNotificationTime =
          DateTime.fromMillisecondsSinceEpoch(lastNotificationTimeMs);
      final timeSinceLastNotification = now.difference(lastNotificationTime);

      final canNotify = timeSinceLastNotification >= _notificationInterval;
      debugPrint(
          'Time since last notification: ${timeSinceLastNotification.inMinutes}min - Can notify: $canNotify (30min interval)');

      return canNotify;
    } catch (e) {
      debugPrint('Error checking notification interval: $e');
      return true; // On error, allow notification
    }
  }

  // Save the current time as last notification time
  Future<void> _saveLastNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt(_lastNotificationTimeKey, now.millisecondsSinceEpoch);

      // Mark that we've shown the first notification of the day
      _isFirstNotificationOfDay = false;
      _lastNotificationDate = now;
    } catch (e) {
      debugPrint('Error saving last notification time: $e');
    }
  }

  // Get current day name from weekday number
  String _getCurrentDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Format time for debugging
  String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  // Enable or disable automatic detection
  void setDetectionEnabled(bool enabled) {
    _isDetectionEnabled = enabled;

    // If disabling, clear any pending detection
    if (!enabled) {
      _cancelDrivingDetectionTimer();
      _drivingStartTime = null;

      // Cancel driving notifications if they exist
      _notificationService.cancel(101); // Driving detection notification
      _notificationService.cancel(102); // Warning notification
      _notificationService.cancel(103); // Rest alert notification

      // Reset driving session
      _resetDrivingSession();
    }
  }

  // Manually reset driving session (useful for testing or user request)
  Future<void> resetDrivingSession() async {
    await _resetDrivingSession();
    // Cancel any active rest notifications
    _notificationService.cancel(102);
    _notificationService.cancel(103);
  }

  // Reset the notification timer (useful for testing or user request)
  Future<void> resetNotificationTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationTimeKey);
      debugPrint(
          'Notification timer reset - next driving detection will show immediately if within schedule');
    } catch (e) {
      debugPrint('Error resetting notification timer: $e');
    }
  }

  // Get the time remaining until next notification is allowed
  Future<Duration?> getTimeUntilNextNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTimeMs = prefs.getInt(_lastNotificationTimeKey);
      final now = DateTime.now();

      // Check if this is a new day
      if (_lastNotificationDate == null ||
          _lastNotificationDate!.day != now.day ||
          _lastNotificationDate!.month != now.month ||
          _lastNotificationDate!.year != now.year) {
        return Duration.zero; // Can notify immediately on new day
      }

      if (lastNotificationTimeMs == null || _isFirstNotificationOfDay) {
        return Duration.zero; // Can notify immediately
      }

      final lastNotificationTime =
          DateTime.fromMillisecondsSinceEpoch(lastNotificationTimeMs);
      final timeSinceLastNotification = now.difference(lastNotificationTime);

      if (timeSinceLastNotification >= _notificationInterval) {
        return Duration.zero; // Can notify immediately
      }

      return _notificationInterval - timeSinceLastNotification;
    } catch (e) {
      debugPrint('Error getting time until next notification: $e');
      return Duration.zero;
    }
  }

  // Load driving session from persistence
  Future<void> _loadDrivingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_drivingSessionKey);

      if (sessionJson != null) {
        final Map<String, dynamic> sessionData =
            Map<String, dynamic>.from(await compute(_parseJson, sessionJson));
        _currentSession = DrivingSession.fromJson(sessionData);

        // Check if session is from today and within reasonable time
        final now = DateTime.now();
        final sessionAge = now.difference(_currentSession!.sessionStartTime);

        if (sessionAge.inHours > 24 || !await _isWithinWorkingHours()) {
          // Session is too old or outside work hours - reset
          await _resetDrivingSession();
        } else {
          debugPrint('Loaded existing driving session: $_currentSession');
        }
      }
    } catch (e) {
      debugPrint('Error loading driving session: $e');
      _currentSession = null;
    }
  }

  // Save driving session to persistence
  Future<void> _saveDrivingSession() async {
    try {
      if (_currentSession == null) return;

      final prefs = await SharedPreferences.getInstance();
      final sessionJson = await compute(_encodeJson, _currentSession!.toJson());
      await prefs.setString(_drivingSessionKey, sessionJson);
    } catch (e) {
      debugPrint('Error saving driving session: $e');
    }
  }

  // Reset driving session
  Future<void> _resetDrivingSession() async {
    try {
      _currentSession = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_drivingSessionKey);
      debugPrint('Reset driving session');
    } catch (e) {
      debugPrint('Error resetting driving session: $e');
    }
  }

  // Helper functions for compute isolates
  static Map<String, dynamic> _parseJson(String jsonString) {
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  }

  static String _encodeJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  // Get current driving session info (for debugging)
  Map<String, dynamic> getDrivingSessionInfo() {
    if (_currentSession == null) {
      return {'hasSession': false};
    }

    return {
      'hasSession': true,
      'sessionStartTime': _currentSession!.sessionStartTime.toString(),
      'accumulatedDrivingTime':
          _currentSession!.accumulatedDrivingTime.inMinutes,
      'totalDrivingTime': _currentSession!.totalDrivingTime.inMinutes,
      'isCurrentlyDriving': _currentSession!.isCurrentlyDriving,
      'hasShownWarning': _currentSession!.hasShownWarning,
      'hasShownRestAlert': _currentSession!.hasShownRestAlert,
      'lastStopTime': _currentSession!.lastStopTime?.toString(),
    };
  }

  // Check current notification eligibility status (for debugging)
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final isWithinSchedule = await _isWithinWorkingHours();
    final canNotify = await _canShowNotification();
    final timeUntilNext = await getTimeUntilNextNotification();

    return {
      'detectionEnabled': _isDetectionEnabled,
      'withinSchedule': isWithinSchedule,
      'canNotifyByTime': canNotify,
      'timeUntilNextNotification': timeUntilNext,
      'canShowNotification':
          isWithinSchedule && canNotify && _isDetectionEnabled,
      'drivingSession': getDrivingSessionInfo(),
      'isFirstNotificationOfDay': _isFirstNotificationOfDay,
    };
  }

  // TEST METHODS - For testing notifications without actual driving

  /// Simulate driving detection for testing purposes
  /// This will trigger the notification flow without requiring actual IN_VEHICLE activity
  Future<void> simulateDrivingDetected() async {
    debugPrint('🧪 TESTING: Simulating driving detection...');

    // Skip the detection timer and directly trigger notification
    await _notifyDrivingDetected();
  }

  /// Force trigger notification even if conditions aren't met (for testing)
  Future<void> forceNotification(
      {String? customTitle, String? customBody}) async {
    debugPrint('🧪 TESTING: Force triggering notification...');

    _notificationService.show(
      NotificationData(
        title: customTitle ?? 'TEST: Driving Detected',
        body: customBody ??
            'This is a test notification to verify the notification system is working.',
        channel: NotificationChannel.driving,
        id: 199, // Different ID for test notifications
        payload: 'test_driving_detected',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 5),
      ),
    );
  }

  /// Simulate different activity types for testing
  void simulateActivityChange(ActivityType activityType) {
    debugPrint('🧪 TESTING: Simulating activity change to $activityType');

    final fakeEvent = ActivityEvent(activityType, 100);

    _handleActivityChange(fakeEvent);
  }

  /// Reset all testing states
  Future<void> resetTestingState() async {
    debugPrint('🧪 TESTING: Resetting all testing states...');

    await resetNotificationTimer();
    await resetDrivingSession();

    _isFirstNotificationOfDay = true;
    _lastNotificationDate = null;

    // Cancel any test notifications
    _notificationService.cancel(199);
  }

  // Dispose of resources
  void dispose() {
    _activitySubscription?.cancel();
    _cancelDrivingDetectionTimer();
  }
}

@Riverpod(keepAlive: true)
DrivingDetectionService drivingDetectionService(
    DrivingDetectionServiceRef ref) {
  final service = DrivingDetectionService();

  // Set the ref for accessing user data
  service._ref = ref;

  // Initialize the service with ref for accessing user data
  service.initialize();

  // Clean up on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
