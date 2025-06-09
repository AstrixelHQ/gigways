import 'dart:async';
import 'package:flutter/material.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:gigways/core/services/driving_detection_service.dart';

class ActivityService with WidgetsBindingObserver {
  // Singleton instance
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  // Activity Recognition instance and its data
  final ActivityRecognition _activityRecognition = ActivityRecognition();

  StreamSubscription<ActivityEvent>? _activitySubscription;
  ActivityEvent? currentActivity;

  // Latest location from background geolocation
  bg.Location? currentLocation;

  // App lifecycle state
  AppLifecycleState? currentLifecycleState;

  // Dependencies
  final DrivingDetectionService _drivingDetectionService = DrivingDetectionService();

  // Flag to control background operation
  bool _isRunningInBackground = false;

  /// Call this function to start activity and background location tracking.
  /// Make sure to request location permission before starting the service.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _startActivityRecognition();
    await _initializeBackgroundGeolocation();
    
    // Initialize the driving detection service
    await _drivingDetectionService.initialize();
  }

  /// Starts listening to the activity recognition stream.
  Future<void> _startActivityRecognition() async {
    _activitySubscription =
        _activityRecognition.activityStream(runForegroundService: true).listen(
      (ActivityEvent event) {
        currentActivity = event;
        
        // Forward the event to the driving detection service 
        // which will handle notification after continuous detection
      },
      onError: (error) {
        debugPrint("Activity Recognition error: $error");
      },
    );
  }

  /// Configures and starts background geolocation.
  Future<void> _initializeBackgroundGeolocation() async {
    // Listen for location updates.
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      currentLocation = location;
      
      // Only log location updates if app is in debug mode
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        debugPrint('[LocationUpdate] - ${location.coords.latitude}, ${location.coords.longitude}');
      }
    }, (bg.LocationError error) {
      debugPrint('[LocationError] ERROR: $error');
    });

    // Configure the plugin for continuous background tracking with battery optimizations
    bg.BackgroundGeolocation.ready(bg.Config(
      // Only get high accuracy when actually tracking
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_MEDIUM,
      distanceFilter: 50.0, // meters
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false, // Set to false in production
      logLevel: bg.Config.LOG_LEVEL_ERROR,
      
      // Battery optimizations
      preventSuspend: false,
      heartbeatInterval: 60, // seconds
      
      // Android specific
      notification: bg.Notification(
        title: "GigWays",
        text: "Location services are active", // Generic message
        channelName: "Location Services",
        priority: bg.Config.NOTIFICATION_PRIORITY_LOW,
      ),
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });

    // Listen for app moving to background/foreground
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      // The motion-change API detects when device movement starts/stops
      final isMoving = location.isMoving;
      
      // If the device starts moving in the background, check if we should start tracking
      if (isMoving && _isRunningInBackground) {
        debugPrint("[Motion] Device is moving in background");
      }
    });
  }

  // Listen to app lifecycle state changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    currentLifecycleState = state;
    
    // Track when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isRunningInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      _isRunningInBackground = false;
    }
  }

  /// Stop activity recognition and location tracking
  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    _activitySubscription?.cancel();
    bg.BackgroundGeolocation.stop();
  }

  /// Dispose resources when the service is no longer needed.
  void dispose() {
    stop();
    _drivingDetectionService.dispose();
  }
}