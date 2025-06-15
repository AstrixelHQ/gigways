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

  // Enhanced notification timing system
  static const Duration _firstNotificationInterval = Duration(minutes: 30);
  static const Duration _subsequentNotificationInterval = Duration(hours: 1);
  static const Duration _maxNotificationInterval = Duration(hours: 2);
  
  // Track notification history
  int _notificationCount = 0;
  bool _isFirstNotificationOfDay = true;
  DateTime? _lastNotificationDate;
  DateTime? _lastNotificationTime;
  
  // Enhanced notification types
  static const int _drivingDetectedId = 101;
  static const int _longDriveWarningId = 102;
  static const int _restBreakAlertId = 103;
  static const int _workStartReminderID = 104;
  static const int _workEndReminderID = 105;
  static const int _breakSuggestionId = 106;
  static const int _earningsUpdateId = 107;

  // Driving session tracking for rest notifications
  static const Duration _restNotificationThreshold = Duration(hours: 2);
  static const Duration _shortBreakThreshold = Duration(minutes: 10);
  static const Duration _sessionResetThreshold = Duration(minutes: 15);
  static const Duration _warningNotificationThreshold =
      Duration(minutes: 90); // 1.5 hours

  // SharedPreferences keys
  static const String _lastNotificationTimeKey =
      'last_driving_notification_time';
  static const String _notificationCountKey = 'notification_count_today';
  static const String _drivingSessionKey = 'current_driving_session';
  static const String _lastNotificationDateKey = 'last_notification_date';

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

  // Show enhanced warning notification at 1.5 hours
  Future<void> _showRestWarningNotification() async {
    _notificationService.show(
      NotificationData(
        title: 'Take a Break Soon',
        body:
            'You\'ve been driving for 1.5 hours. A short break will help you stay alert and safe.',
        channel: NotificationChannel.safety,
        id: _longDriveWarningId,
        payload: 'driving_warning',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 10),
      ),
    );
    debugPrint('Showed enhanced 1.5 hour warning notification');
  }

  // Show enhanced rest alert notification at 2 hours
  Future<void> _showRestAlertNotification() async {
    _notificationService.show(
      NotificationData(
        title: 'Rest Break Required',
        body:
            'You\'ve been driving for 2 hours. Take a 15-minute break for your safety and well-being.',
        channel: NotificationChannel.safety,
        id: _restBreakAlertId,
        payload: 'driving_rest_alert',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 15),
      ),
    );
    debugPrint('Showed enhanced 2 hour rest alert notification');
  }

  // Show enhanced notification for driving detection
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

    // Dynamic notification content based on count
    String title, body;
    if (_notificationCount == 1) {
      title = 'Driving Detected';
      body = 'We noticed you may be driving. Would you like to start tracking?';
    } else if (_notificationCount == 2) {
      title = 'Still Driving?';
      body = 'Tap to start tracking your work session and earnings.';
    } else {
      title = 'Driving Session Active';
      body = 'Track your work hours and maximize your earnings.';
    }

    _notificationService.show(
      NotificationData(
        title: title,
        body: body,
        channel: NotificationChannel.driving,
        id: _drivingDetectedId,
        payload: 'driving_detected',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 5),
      ),
    );

    debugPrint(
        'Enhanced driving notification #$_notificationCount shown - within schedule and interval requirements met');
  }

  // Check if current time is within user's scheduled working hours
  // NOTE: Schedule barriers removed as per requirements
  Future<bool> _isWithinWorkingHours() async {
    // Always return true - notifications allowed at any time
    return true;
  }

  // Enhanced notification timing logic
  // First notification: immediate
  // Second notification: 30 minutes later
  // Subsequent notifications: increasing intervals (1hr, 2hr, then 2hr max)
  Future<bool> _canShowNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTimeMs = prefs.getInt(_lastNotificationTimeKey);
      final savedNotificationCount = prefs.getInt(_notificationCountKey) ?? 0;
      final lastNotificationDateMs = prefs.getInt(_lastNotificationDateKey);
      final now = DateTime.now();

      // Check if this is a new day
      if (lastNotificationDateMs == null || 
          !_isSameDay(DateTime.fromMillisecondsSinceEpoch(lastNotificationDateMs), now)) {
        _isFirstNotificationOfDay = true;
        _notificationCount = 0;
        _lastNotificationDate = now;
        debugPrint('New day detected - resetting notification count');
      } else {
        _notificationCount = savedNotificationCount;
        _isFirstNotificationOfDay = false;
      }

      // First notification of the day - allow immediately
      if (lastNotificationTimeMs == null || _isFirstNotificationOfDay) {
        debugPrint('First notification of day - allowing immediately');
        return true;
      }

      final lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(lastNotificationTimeMs);
      final timeSinceLastNotification = now.difference(lastNotificationTime);
      
      // Dynamic interval based on notification count
      Duration requiredInterval;
      if (_notificationCount == 1) {
        requiredInterval = _firstNotificationInterval; // 30 minutes
      } else if (_notificationCount == 2) {
        requiredInterval = _subsequentNotificationInterval; // 1 hour  
      } else {
        requiredInterval = _maxNotificationInterval; // 2 hours max
      }

      final canNotify = timeSinceLastNotification >= requiredInterval;
      debugPrint(
          'Notification #${_notificationCount + 1} - Time since last: ${timeSinceLastNotification.inMinutes}min - Required: ${requiredInterval.inMinutes}min - Can notify: $canNotify');

      return canNotify;
    } catch (e) {
      debugPrint('Error checking notification interval: $e');
      return true; // On error, allow notification
    }
  }

  // Save the current time as last notification time and update count
  Future<void> _saveLastNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Update notification count
      _notificationCount++;
      
      // Save all notification state
      await prefs.setInt(_lastNotificationTimeKey, now.millisecondsSinceEpoch);
      await prefs.setInt(_notificationCountKey, _notificationCount);
      await prefs.setInt(_lastNotificationDateKey, now.millisecondsSinceEpoch);

      // Mark that we've shown the first notification of the day
      _isFirstNotificationOfDay = false;
      _lastNotificationDate = now;
      _lastNotificationTime = now;
      
      debugPrint('Saved notification #$_notificationCount at ${now.toString()}');
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

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
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
      _notificationService.cancel(_drivingDetectedId); // Driving detection notification
      _notificationService.cancel(_longDriveWarningId); // Warning notification
      _notificationService.cancel(_restBreakAlertId); // Rest alert notification
      _notificationService.cancel(_breakSuggestionId); // Break suggestion
      _notificationService.cancel(_workStartReminderID); // Work start reminder
      _notificationService.cancel(_workEndReminderID); // Work end reminder

      // Reset driving session
      _resetDrivingSession();
    }
  }

  // Manually reset driving session (useful for testing or user request)
  Future<void> resetDrivingSession() async {
    await _resetDrivingSession();
    // Cancel any active rest notifications
    _notificationService.cancel(_longDriveWarningId);
    _notificationService.cancel(_restBreakAlertId);
    _notificationService.cancel(_breakSuggestionId);
  }

  // Reset the notification timer (useful for testing or user request)
  Future<void> resetNotificationTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationTimeKey);
      await prefs.remove(_notificationCountKey);
      await prefs.remove(_lastNotificationDateKey);
      
      _notificationCount = 0;
      _isFirstNotificationOfDay = true;
      _lastNotificationDate = null;
      _lastNotificationTime = null;
      
      debugPrint(
          'Notification timer and count reset - next driving detection will show immediately');
    } catch (e) {
      debugPrint('Error resetting notification timer: $e');
    }
  }

  // Get the time remaining until next notification is allowed
  Future<Duration?> getTimeUntilNextNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTimeMs = prefs.getInt(_lastNotificationTimeKey);
      final savedNotificationCount = prefs.getInt(_notificationCountKey) ?? 0;
      final now = DateTime.now();

      // Check if this is a new day
      if (_lastNotificationDate == null ||
          !_isSameDay(_lastNotificationDate!, now)) {
        return Duration.zero; // Can notify immediately on new day
      }

      if (lastNotificationTimeMs == null || _isFirstNotificationOfDay) {
        return Duration.zero; // Can notify immediately
      }

      final lastNotificationTime =
          DateTime.fromMillisecondsSinceEpoch(lastNotificationTimeMs);
      final timeSinceLastNotification = now.difference(lastNotificationTime);

      // Determine required interval based on notification count
      Duration requiredInterval;
      if (savedNotificationCount == 1) {
        requiredInterval = _firstNotificationInterval;
      } else if (savedNotificationCount == 2) {
        requiredInterval = _subsequentNotificationInterval;
      } else {
        requiredInterval = _maxNotificationInterval;
      }

      if (timeSinceLastNotification >= requiredInterval) {
        return Duration.zero; // Can notify immediately
      }

      return requiredInterval - timeSinceLastNotification;
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
      'notificationCount': _notificationCount,
      'lastNotificationTime': _lastNotificationTime?.toString(),
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
    _notificationService.cancel(_workStartReminderID);
    _notificationService.cancel(_workEndReminderID);
    _notificationService.cancel(_breakSuggestionId);
    _notificationService.cancel(_earningsUpdateId);
  }

  // NEW ENHANCED NOTIFICATIONS
  
  /// Show work start reminder notification
  Future<void> showWorkStartReminder() async {
    final now = DateTime.now();
    final hour = now.hour;
    String timeContext;
    
    if (hour < 6) {
      timeContext = 'early morning';
    } else if (hour < 12) {
      timeContext = 'morning';
    } else if (hour < 18) {
      timeContext = 'afternoon';
    } else {
      timeContext = 'evening';
    }
    
    _notificationService.show(
      NotificationData(
        title: 'Ready to Start Your ${timeContext.split(' ').last.toUpperCase()} Shift?',
        body: 'Good $timeContext! Tap to begin tracking your work session.',
        channel: NotificationChannel.driving,
        id: _workStartReminderID,
        payload: 'work_start_reminder',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 10),
      ),
    );
    debugPrint('Showed work start reminder notification');
  }
  
  /// Show work end reminder notification
  Future<void> showWorkEndReminder(Duration workDuration) async {
    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;
    String durationText = '';
    
    if (hours > 0) {
      durationText = '${hours}h ${minutes}m';
    } else {
      durationText = '${minutes}m';
    }
    
    _notificationService.show(
      NotificationData(
        title: 'Great Work Session!',
        body: 'You\'ve been working for $durationText. Consider ending your shift to rest.',
        channel: NotificationChannel.driving,
        id: _workEndReminderID,
        payload: 'work_end_reminder',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 15),
      ),
    );
    debugPrint('Showed work end reminder notification');
  }
  
  /// Show intelligent break suggestion
  Future<void> showBreakSuggestion() async {
    final now = DateTime.now();
    final hour = now.hour;
    String breakSuggestion;
    
    if (hour >= 11 && hour <= 13) {
      breakSuggestion = 'Perfect time for a lunch break!';
    } else if (hour >= 15 && hour <= 17) {
      breakSuggestion = 'How about a quick snack break?';
    } else {
      breakSuggestion = 'Take a moment to stretch and hydrate.';
    }
    
    _notificationService.show(
      NotificationData(
        title: 'Break Time Suggestion',
        body: breakSuggestion,
        channel: NotificationChannel.breaks,
        id: _breakSuggestionId,
        payload: 'break_suggestion',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 10),
      ),
    );
    debugPrint('Showed break suggestion notification');
  }
  
  /// Show earnings update notification
  Future<void> showEarningsUpdate(double earnings, Duration workTime) async {
    final hours = workTime.inHours;
    final formattedEarnings = earnings.toStringAsFixed(2);
    
    _notificationService.show(
      NotificationData(
        title: 'Earnings Update',
        body: 'You\'ve earned \$${formattedEarnings} in ${hours}h of work today. Keep it up!',
        channel: NotificationChannel.system,
        id: _earningsUpdateId,
        payload: 'earnings_update',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 10),
      ),
    );
    debugPrint('Showed earnings update notification');
  }
  
  /// Show smart driving continuation notification
  Future<void> showSmartDrivingContinuation() async {
    final currentSession = _currentSession;
    if (currentSession == null) return;
    
    final totalMinutes = currentSession.totalDrivingTime.inMinutes;
    String message;
    
    if (totalMinutes < 30) {
      message = 'Just started? Track your short trips for better insights.';
    } else if (totalMinutes < 60) {
      message = 'Good progress! You\'ve been driving for ${totalMinutes}min.';
    } else {
      message = 'Long session active. Remember to take breaks when safe.';
    }
    
    _notificationService.show(
      NotificationData(
        title: 'Smart Tracking Active',
        body: message,
        channel: NotificationChannel.driving,
        id: _drivingDetectedId,
        payload: 'smart_driving_continuation',
        autoCancel: true,
        timeoutAfter: const Duration(minutes: 8),
      ),
    );
    debugPrint('Showed smart driving continuation notification');
  }

  // Dispose of resources
  void dispose() {
    _activitySubscription?.cancel();
    _cancelDrivingDetectionTimer();
  }
}

@Riverpod(keepAlive: true)
DrivingDetectionService drivingDetectionService(Ref ref) {
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
