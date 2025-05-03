import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

class DrivingDetectionService {
  static final DrivingDetectionService _instance =
      DrivingDetectionService._internal();
  factory DrivingDetectionService() => _instance;
  DrivingDetectionService._internal();

  // Subscriptions for activity recognition
  StreamSubscription<ActivityEvent>? _activitySubscription;

  // Track last detected driving state to avoid duplicate notifications
  bool _lastDrivingState = false;

  // Control flag to enable/disable automatic detection
  bool _isDetectionEnabled = true;

  // Initialize the detection service
  Future<void> initialize() async {
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

    // Only process if detection is enabled and state changed
    if (_isDetectionEnabled && isDriving != _lastDrivingState) {
      _lastDrivingState = isDriving;

      if (isDriving) {
      } else {}
    }
  }

  // Enable or disable automatic detection
  void setDetectionEnabled(bool enabled) {
    _isDetectionEnabled = enabled;
  }

  // Dispose of resources
  void dispose() {
    _activitySubscription?.cancel();
  }
}
