import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:gigways/core/services/debug_log_service.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'driving_detection_service.g.dart';

// Removed DrivingSession class - now using UI tracker integration

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
  static const int _longDriveWarningId =
      105; // Changed from 102 to avoid conflict
  static const int _restBreakAlertId =
      106; // Changed from 103 to avoid conflict
  static const int _workStartReminderID =
      107; // Changed from 104 to avoid conflict
  static const int _workEndReminderID = 108;
  static const int _breakSuggestionId = 109;
  static const int _earningsUpdateId = 110;

  // Timer for checking tracking-based notifications
  Timer? _trackingCheckTimer;

  // Tracker-based rest notifications
  static const Duration _restNotificationThreshold = Duration(hours: 2);
  static const Duration _warningNotificationThreshold =
      Duration(minutes: 90); // 1.5 hours
  static const Duration _repeatNotificationInterval =
      Duration(hours: 2); // Repeat every 2 hours

  // Track when notifications were last sent
  DateTime? _lastWarningTime;
  DateTime? _lastRestAlertTime;
  DateTime? _lastDrivingNotificationTime;
  int _restAlertCount = 0; // Track how many 2-hour alerts sent

  // SharedPreferences keys
  static const String _lastNotificationTimeKey =
      'last_driving_notification_time';
  static const String _notificationCountKey = 'notification_count_today';
  static const String _lastNotificationDateKey = 'last_notification_date';
  static const String _lastWarningTimeKey = 'last_warning_time';
  static const String _lastRestAlertTimeKey = 'last_rest_alert_time';
  static const String _restAlertCountKey = 'rest_alert_count';

  // Reference to tracking notifier for UI timer integration
  TrackingNotifier? _trackingNotifier;

  // Debug logging service
  late DebugLogService _debugLogger;

  // Initialize the detection service
  Future<void> initialize() async {
    // Get notification service instance
    _notificationService = NotificationService();

    // Get debug logger instance
    _debugLogger = DebugLogService();

    await _debugLogger.info(
      'Initializing driving detection service',
      category: LogCategory.notification,
      metadata: {
        'detectionEnabled': _isDetectionEnabled,
        'firstNotificationInterval': _firstNotificationInterval.inMinutes,
        'maxNotificationInterval': _maxNotificationInterval.inMinutes,
        'restThreshold': _restNotificationThreshold.inMinutes,
        'warningThreshold': _warningNotificationThreshold.inMinutes,
      },
    );

    // Load saved notification state
    await _loadNotificationState();

    // Start activity recognition
    final activityRecognition = ActivityRecognition();

    _activitySubscription = activityRecognition.activityStream().listen(
      (ActivityEvent event) {
        _handleActivityChange(event);
      },
      onError: (error) async {
        await _debugLogger.error(
          'Activity recognition error',
          category: LogCategory.activity,
          details: error.toString(),
          error: error,
        );
      },
    );

    // Start timer to check tracking-based notifications every minute
    _startTrackingCheckTimer();

    await _debugLogger.info(
      'Driving detection service initialized successfully',
      category: LogCategory.notification,
      metadata: {
        'hasTrackingNotifier': _trackingNotifier != null,
        'notificationCount': _notificationCount,
        'isFirstNotificationOfDay': _isFirstNotificationOfDay,
      },
    );
  }

  // Handle activity changes
  void _handleActivityChange(ActivityEvent event) {
    final bool isDriving = event.type == ActivityType.IN_VEHICLE;
    final bool stateChanged = isDriving != _lastDrivingState;

    _debugLogger.debug(
      'Activity change detected',
      category: LogCategory.activity,
      metadata: {
        'activityType': event.type.name,
        'isDriving': isDriving,
        'stateChanged': stateChanged,
        'confidence': event.confidence,
        'detectionEnabled': _isDetectionEnabled,
        'isCurrentlyTracking': _isCurrentlyTracking(),
      },
    );

    // Check if detection is enabled
    if (!_isDetectionEnabled) {
      _debugLogger.debug(
        'Activity change ignored - detection disabled',
        category: LogCategory.notification,
      );
      _cancelDrivingDetectionTimer();
      return;
    }

    // Handle driving detection notifications (only when not tracking)
    if (_trackingNotifier == null || !_isCurrentlyTracking()) {
      _handleDrivingDetectionChange(isDriving);
    } else {
      _debugLogger.debug(
        'Activity change ignored - currently tracking via UI',
        category: LogCategory.notification,
        metadata: {
          'trackingDuration': _getCurrentTrackingDuration()?.inMinutes
        },
      );
    }

    _lastDrivingState = isDriving;
  }

  // Start timer to check tracking-based notifications
  void _startTrackingCheckTimer() {
    _trackingCheckTimer?.cancel();
    _trackingCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTrackingBasedNotifications();
    });
  }

  // Check if currently tracking via UI tracker
  bool _isCurrentlyTracking() {
    if (_ref == null) return false;
    final trackingState = _ref!.read(trackingNotifierProvider);
    return trackingState.status == TrackingStatus.active &&
        trackingState.activeSession != null;
  }

  // Get current tracking duration from UI tracker
  Duration? _getCurrentTrackingDuration() {
    if (_ref == null) return null;
    final trackingState = _ref!.read(trackingNotifierProvider);
    if (trackingState.status != TrackingStatus.active ||
        trackingState.activeSession == null) {
      return null;
    }
    return Duration(seconds: trackingState.activeSession!.durationInSeconds);
  }

  // Check for tracker-based rest notifications
  void _checkTrackingBasedNotifications() {
    if (!_isDetectionEnabled) {
      _debugLogger.debug(
        'Tracking notification check skipped - detection disabled',
        category: LogCategory.notification,
      );
      return;
    }

    final trackingDuration = _getCurrentTrackingDuration();
    if (trackingDuration == null) {
      // Not tracking, reset notification times
      _debugLogger.debug(
        'Not tracking - resetting notification state',
        category: LogCategory.notification,
      );
      _resetNotificationState();
      return;
    }

    _debugLogger.debug(
      'Checking tracking-based notifications',
      category: LogCategory.notification,
      metadata: {
        'trackingDuration': trackingDuration.inMinutes,
        'lastWarningTime': _lastWarningTime?.toIso8601String(),
        'lastRestAlertTime': _lastRestAlertTime?.toIso8601String(),
        'lastDrivingNotificationTime':
            _lastDrivingNotificationTime?.toIso8601String(),
        'restAlertCount': _restAlertCount,
      },
    );

    final now = DateTime.now();

    // Check for 90-minute warning (but only send every 2 hours)
    if (trackingDuration >= _warningNotificationThreshold) {
      if (_lastWarningTime == null ||
          now.difference(_lastWarningTime!) >= _repeatNotificationInterval) {
        _debugLogger.info(
          'Triggering 90-minute warning notification',
          category: LogCategory.notification,
          metadata: {
            'trackingDuration': trackingDuration.inMinutes,
            'timeSinceLastWarning': _lastWarningTime != null
                ? now.difference(_lastWarningTime!).inMinutes
                : null,
          },
        );
        _showTrackingWarningNotification(trackingDuration);
        _lastWarningTime = now;
        _saveNotificationState();
      } else {
        _debugLogger.debug(
          '90-minute warning suppressed - too soon since last warning',
          category: LogCategory.notification,
          metadata: {
            'timeSinceLastWarning': now.difference(_lastWarningTime!).inMinutes,
            'requiredInterval': _repeatNotificationInterval.inMinutes,
          },
        );
      }
    }

    // Check for 2-hour rest alert (repeat every 2 hours)
    if (trackingDuration >= _restNotificationThreshold) {
      if (_lastRestAlertTime == null ||
          now.difference(_lastRestAlertTime!) >= _repeatNotificationInterval) {
        _debugLogger.warning(
          'Triggering 2-hour rest alert notification',
          category: LogCategory.notification,
          metadata: {
            'trackingDuration': trackingDuration.inMinutes,
            'restAlertCount': _restAlertCount + 1,
            'timeSinceLastAlert': _lastRestAlertTime != null
                ? now.difference(_lastRestAlertTime!).inMinutes
                : null,
          },
        );
        _showTrackingRestAlert(trackingDuration);
        _lastRestAlertTime = now;
        _restAlertCount++;
        _saveNotificationState();
      } else {
        _debugLogger.debug(
          '2-hour rest alert suppressed - too soon since last alert',
          category: LogCategory.notification,
          metadata: {
            'timeSinceLastAlert': now.difference(_lastRestAlertTime!).inMinutes,
            'requiredInterval': _repeatNotificationInterval.inMinutes,
          },
        );
      }
    }

    // Send driving detected notification every 2 hours when tracking
    if (_lastDrivingNotificationTime == null ||
        now.difference(_lastDrivingNotificationTime!) >=
            _repeatNotificationInterval) {
      _debugLogger.info(
        'Triggering tracking continuation notification',
        category: LogCategory.notification,
        metadata: {
          'trackingDuration': trackingDuration.inMinutes,
          'timeSinceLastDrivingNotification':
              _lastDrivingNotificationTime != null
                  ? now.difference(_lastDrivingNotificationTime!).inMinutes
                  : null,
        },
      );
      _showTrackingContinuationNotification(trackingDuration);
      _lastDrivingNotificationTime = now;
      _saveNotificationState();
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

  // Reset notification state when not tracking
  void _resetNotificationState() {
    if (_lastWarningTime != null ||
        _lastRestAlertTime != null ||
        _lastDrivingNotificationTime != null) {
      _lastWarningTime = null;
      _lastRestAlertTime = null;
      _lastDrivingNotificationTime = null;
      _restAlertCount = 0;
      _saveNotificationState();
      debugPrint('Reset notification state - not tracking');
    }
  }

  // Show tracking-based warning notification
  void _showTrackingWarningNotification(Duration trackingDuration) {
    final hours = trackingDuration.inHours;
    final minutes = trackingDuration.inMinutes % 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    final notificationData = NotificationData(
      title: 'Take a Break Soon',
      body:
          'You\'ve been tracking for $durationText. Consider taking a break for your safety.',
      channel: NotificationChannel.safety,
      id: _longDriveWarningId,
      payload: 'tracking_warning',
      autoCancel: true,
      timeoutAfter: const Duration(minutes: 10),
    );

    _debugLogger.info(
      'Showing tracking warning notification',
      category: LogCategory.notification,
      details:
          'User has been tracking for $durationText - showing 90-minute warning',
      metadata: {
        'notificationId': _longDriveWarningId,
        'trackingDurationMinutes': trackingDuration.inMinutes,
        'notificationTitle': notificationData.title,
        'notificationBody': notificationData.body,
        'channel': notificationData.channel.name,
        'payload': notificationData.payload,
      },
    );

    _notificationService.show(notificationData);
  }

  // Show tracking-based rest alert
  void _showTrackingRestAlert(Duration trackingDuration) {
    final hours = trackingDuration.inHours;
    final minutes = trackingDuration.inMinutes % 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    final alertNumber = _restAlertCount + 1;

    final notificationData = NotificationData(
      title: 'Rest Break Required',
      body:
          'You\'ve been tracking for $durationText. Take a 15-minute break for your well-being. (Alert #$alertNumber)',
      channel: NotificationChannel.safety,
      id: _restBreakAlertId,
      payload: 'tracking_rest_alert',
      autoCancel: true,
      timeoutAfter: const Duration(minutes: 15),
    );

    _debugLogger.warning(
      'Showing critical rest alert notification',
      category: LogCategory.notification,
      details:
          'User has been tracking for $durationText - showing 2-hour rest alert #$alertNumber',
      metadata: {
        'notificationId': _restBreakAlertId,
        'trackingDurationMinutes': trackingDuration.inMinutes,
        'alertNumber': alertNumber,
        'totalRestAlerts': _restAlertCount + 1,
        'notificationTitle': notificationData.title,
        'notificationBody': notificationData.body,
        'channel': notificationData.channel.name,
        'payload': notificationData.payload,
        'timeoutMinutes': 15,
      },
    );

    _notificationService.show(notificationData);
  }

  // Show continuation notification while tracking
  void _showTrackingContinuationNotification(Duration trackingDuration) {
    final hours = trackingDuration.inHours;
    final durationText = hours > 0
        ? '${hours}h tracking'
        : '${trackingDuration.inMinutes}m tracking';

    final notificationData = NotificationData(
      title: 'Tracking Active',
      body:
          'Great work! You\'ve been tracking for $durationText. Stay safe and keep earning.',
      channel: NotificationChannel.driving,
      id: _drivingDetectedId,
      payload: 'tracking_continuation',
      autoCancel: true,
      timeoutAfter: const Duration(minutes: 8),
    );

    _debugLogger.info(
      'Showing tracking continuation notification',
      category: LogCategory.notification,
      details: 'Encouraging user who has been tracking for $durationText',
      metadata: {
        'notificationId': _drivingDetectedId,
        'trackingDurationMinutes': trackingDuration.inMinutes,
        'notificationTitle': notificationData.title,
        'notificationBody': notificationData.body,
        'channel': notificationData.channel.name,
        'payload': notificationData.payload,
      },
    );

    _notificationService.show(notificationData);
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
    if (!_isDetectionEnabled || _ref == null) {
      await _debugLogger.debug(
        'Driving detection notification skipped',
        category: LogCategory.notification,
        metadata: {
          'detectionEnabled': _isDetectionEnabled,
          'hasRef': _ref != null,
        },
      );
      return;
    }

    // Check if user is within scheduled work hours
    final isWithinSchedule = await _isWithinWorkingHours();
    if (!isWithinSchedule) {
      await _debugLogger.info(
        'Driving detected outside work hours - notification suppressed',
        category: LogCategory.notification,
        metadata: {'withinSchedule': isWithinSchedule},
      );
      return;
    }

    // Check if enough time has passed since last notification
    final canNotify = await _canShowNotification();
    final timeUntilNext = await getTimeUntilNextNotification();

    if (!canNotify) {
      await _debugLogger.debug(
        'Driving notification suppressed - too soon since last notification',
        category: LogCategory.notification,
        metadata: {
          'canNotify': canNotify,
          'timeUntilNextMinutes': timeUntilNext?.inMinutes,
          'notificationCount': _notificationCount,
          'isFirstOfDay': _isFirstNotificationOfDay,
        },
      );
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

    final notificationData = NotificationData(
      title: title,
      body: body,
      channel: NotificationChannel.driving,
      id: _drivingDetectedId,
      payload: 'driving_detected',
      autoCancel: true,
      timeoutAfter: const Duration(minutes: 5),
    );

    await _debugLogger.info(
      'Showing driving detection notification',
      category: LogCategory.notification,
      details:
          'Activity-based driving detection triggered notification #$_notificationCount',
      metadata: {
        'notificationId': _drivingDetectedId,
        'notificationCount': _notificationCount,
        'isFirstOfDay': _isFirstNotificationOfDay,
        'withinSchedule': isWithinSchedule,
        'canNotify': canNotify,
        'title': title,
        'body': body,
        'channel': notificationData.channel.name,
        'payload': notificationData.payload,
        'timeoutMinutes': 5,
      },
    );

    _notificationService.show(notificationData);
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
          !_isSameDay(
              DateTime.fromMillisecondsSinceEpoch(lastNotificationDateMs),
              now)) {
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

      final lastNotificationTime =
          DateTime.fromMillisecondsSinceEpoch(lastNotificationTimeMs);
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

      debugPrint(
          'Saved notification #$_notificationCount at ${now.toString()}');
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
      _trackingCheckTimer?.cancel();
      _drivingStartTime = null;

      // Cancel driving notifications if they exist
      _notificationService.cancel(_drivingDetectedId);
      _notificationService.cancel(_longDriveWarningId);
      _notificationService.cancel(_restBreakAlertId);
      _notificationService.cancel(_breakSuggestionId);
      _notificationService.cancel(_workStartReminderID);
      _notificationService.cancel(_workEndReminderID);

      // Reset notification state
      _resetNotificationState();
    } else {
      // Re-enable tracking check timer
      _startTrackingCheckTimer();
    }
  }

  // Manually reset all notification state (useful for testing or user request)
  Future<void> resetNotificationState() async {
    _resetNotificationState();
    await _clearNotificationState();
    // Cancel any active rest notifications
    _notificationService.cancel(_longDriveWarningId);
    _notificationService.cancel(_restBreakAlertId);
    _notificationService.cancel(_breakSuggestionId);
    debugPrint('Manually reset all notification state');
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

  // Load notification state from persistence
  Future<void> _loadNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastWarningMs = prefs.getInt(_lastWarningTimeKey);
      if (lastWarningMs != null) {
        _lastWarningTime = DateTime.fromMillisecondsSinceEpoch(lastWarningMs);
      }

      final lastRestAlertMs = prefs.getInt(_lastRestAlertTimeKey);
      if (lastRestAlertMs != null) {
        _lastRestAlertTime =
            DateTime.fromMillisecondsSinceEpoch(lastRestAlertMs);
      }

      _restAlertCount = prefs.getInt(_restAlertCountKey) ?? 0;

      // Check if it's a new day - reset notification state
      final lastNotificationDateMs = prefs.getInt(_lastNotificationDateKey);
      final now = DateTime.now();

      if (lastNotificationDateMs == null ||
          !_isSameDay(
              DateTime.fromMillisecondsSinceEpoch(lastNotificationDateMs),
              now)) {
        _resetNotificationState();
        debugPrint('New day detected - reset notification state');
      }

      debugPrint(
          'Loaded notification state - Warning: $_lastWarningTime, RestAlert: $_lastRestAlertTime, Count: $_restAlertCount');
    } catch (e) {
      debugPrint('Error loading notification state: $e');
    }
  }

  // Save notification state to persistence
  Future<void> _saveNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      if (_lastWarningTime != null) {
        await prefs.setInt(
            _lastWarningTimeKey, _lastWarningTime!.millisecondsSinceEpoch);
      }

      if (_lastRestAlertTime != null) {
        await prefs.setInt(
            _lastRestAlertTimeKey, _lastRestAlertTime!.millisecondsSinceEpoch);
      }

      await prefs.setInt(_restAlertCountKey, _restAlertCount);
      await prefs.setInt(_lastNotificationDateKey, now.millisecondsSinceEpoch);

      debugPrint('Saved notification state');
    } catch (e) {
      debugPrint('Error saving notification state: $e');
    }
  }

  // Clear all saved notification state
  Future<void> _clearNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastWarningTimeKey);
      await prefs.remove(_lastRestAlertTimeKey);
      await prefs.remove(_restAlertCountKey);
      debugPrint('Cleared notification state');
    } catch (e) {
      debugPrint('Error clearing notification state: $e');
    }
  }

  // Helper function removed - no longer needed for tracker-based approach

  // Get current tracking info (for debugging)
  Map<String, dynamic> getTrackingInfo() {
    final isTracking = _isCurrentlyTracking();
    final trackingDuration = _getCurrentTrackingDuration();

    return {
      'isTracking': isTracking,
      'trackingDuration': trackingDuration?.inMinutes,
      'lastWarningTime': _lastWarningTime?.toString(),
      'lastRestAlertTime': _lastRestAlertTime?.toString(),
      'restAlertCount': _restAlertCount,
      'lastDrivingNotificationTime': _lastDrivingNotificationTime?.toString(),
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
      'trackingInfo': getTrackingInfo(),
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
        title: customTitle ?? 'TEST: Tracker-Based System',
        body: customBody ??
            'Testing the new tracker-integrated notification system. Rest alerts now rely on UI timer.',
        channel: NotificationChannel.driving,
        id: 199, // Different ID for test notifications
        payload: 'test_tracker_integration',
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
    await resetNotificationState();

    _isFirstNotificationOfDay = true;
    _lastNotificationDate = null;

    // Cancel any test notifications
    _notificationService.cancel(199);
    _notificationService.cancel(_workStartReminderID);
    _notificationService.cancel(_workEndReminderID);
    _notificationService.cancel(_breakSuggestionId);
    _notificationService.cancel(_earningsUpdateId);
  }

  /// Test method to simulate 2-hour tracking and trigger rest alert
  Future<void> testRestNotifications() async {
    debugPrint('🧪 TESTING: Simulating rest notifications...');

    // Simulate 90-minute warning
    _showTrackingWarningNotification(const Duration(minutes: 95));

    // Wait a bit, then simulate 2-hour alert
    await Future.delayed(const Duration(seconds: 3));
    _showTrackingRestAlert(const Duration(hours: 2, minutes: 5));

    // Simulate continuation notification
    await Future.delayed(const Duration(seconds: 3));
    _showTrackingContinuationNotification(
        const Duration(hours: 2, minutes: 30));
  }

  /// Test method to check current tracking integration
  Future<void> testTrackingIntegration() async {
    debugPrint('🧪 TESTING: Testing tracking integration...');

    final isTracking = _isCurrentlyTracking();
    final duration = _getCurrentTrackingDuration();

    debugPrint('🧪 Is Currently Tracking: $isTracking');
    debugPrint(
        '🧪 Current Tracking Duration: ${duration?.inMinutes ?? 0} minutes');

    if (isTracking && duration != null) {
      debugPrint('🧪 Triggering tracker-based notification check...');
      _checkTrackingBasedNotifications();
    } else {
      debugPrint('🧪 Not tracking - would show driving detection instead');
      await simulateDrivingDetected();
    }
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
        title:
            'Ready to Start Your ${timeContext.split(' ').last.toUpperCase()} Shift?',
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
        body:
            'You\'ve been working for $durationText. Consider ending your shift to rest.',
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
        body:
            'You\'ve earned \$${formattedEarnings} in ${hours}h of work today. Keep it up!',
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
    final trackingDuration = _getCurrentTrackingDuration();
    if (trackingDuration == null) {
      await _debugLogger.debug(
        'Cannot show smart driving continuation - not tracking',
        category: LogCategory.notification,
      );
      return;
    }

    final totalMinutes = trackingDuration.inMinutes;
    String message;

    if (totalMinutes < 30) {
      message = 'Just started? Track your short trips for better insights.';
    } else if (totalMinutes < 60) {
      message = 'Good progress! You\'ve been driving for ${totalMinutes}min.';
    } else {
      message = 'Long session active. Remember to take breaks when safe.';
    }

    final notificationData = NotificationData(
      title: 'Smart Tracking Active',
      body: message,
      channel: NotificationChannel.driving,
      id: _drivingDetectedId,
      payload: 'smart_driving_continuation',
      autoCancel: true,
      timeoutAfter: const Duration(minutes: 8),
    );

    await _debugLogger.info(
      'Showing smart driving continuation notification',
      category: LogCategory.notification,
      details:
          'User has been tracking for ${totalMinutes}min - showing smart continuation message',
      metadata: {
        'notificationId': _drivingDetectedId,
        'trackingDurationMinutes': totalMinutes,
        'message': message,
        'notificationTitle': notificationData.title,
        'notificationBody': notificationData.body,
        'channel': notificationData.channel.name,
        'payload': notificationData.payload,
      },
    );

    _notificationService.show(notificationData);
  }

  // Dispose of resources
  void dispose() {
    _activitySubscription?.cancel();
    _cancelDrivingDetectionTimer();
    _trackingCheckTimer?.cancel();
  }
}

@Riverpod(keepAlive: true)
DrivingDetectionService drivingDetectionService(Ref ref) {
  final service = DrivingDetectionService();

  // Set the ref for accessing user data and tracking notifier
  service._ref = ref;

  // Get tracking notifier reference for UI timer integration
  service._trackingNotifier = ref.read(trackingNotifierProvider.notifier);

  // Initialize debug logger
  service._debugLogger = ref.read(debugLogServiceProvider);

  // Initialize the service with ref for accessing user data
  service.initialize();

  // Clean up on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
