import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driving_detection_service.g.dart';

class DrivingDetectionService {
  static final DrivingDetectionService _instance =
      DrivingDetectionService._internal();
  factory DrivingDetectionService() => _instance;
  DrivingDetectionService._internal();

  // Subscriptions for activity recognition
  StreamSubscription<ActivityEvent>? _activitySubscription;

  // Notification service - get the singleton instance
  late NotificationService _notificationService;

  // Track last detected driving state to avoid duplicate notifications
  bool _lastDrivingState = false;

  // Control flag to enable/disable automatic detection
  bool _isDetectionEnabled = true;

  // Buffer for driving detection (to wait for continuous detection)
  DateTime? _drivingStartTime;
  Timer? _drivingDetectionTimer;

  // Threshold for continuous driving detection in seconds
  static const int _drivingDetectionThreshold = 25; // 25 seconds

  // Initialize the detection service
  Future<void> initialize() async {
    // Get notification service instance
    _notificationService = NotificationService();

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

    _lastDrivingState = isDriving;
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

  // Show notification for driving detection
  void _notifyDrivingDetected() {
    if (!_isDetectionEnabled) return;

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
  }

  // Enable or disable automatic detection
  void setDetectionEnabled(bool enabled) {
    _isDetectionEnabled = enabled;

    // If disabling, clear any pending detection
    if (!enabled) {
      _cancelDrivingDetectionTimer();
      _drivingStartTime = null;

      // Cancel the driving notification if it exists
      _notificationService
          .cancel(101); // Same ID as used for driving notification
    }
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

  // Initialize the service
  service.initialize();

  // Clean up on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
