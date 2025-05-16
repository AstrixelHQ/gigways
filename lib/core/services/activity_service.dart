import 'dart:async';
import 'package:flutter/material.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class ActivityService with WidgetsBindingObserver {
  // Singleton instance (optional)
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

  /// Call this function to start activity and background location tracking.
  /// Make sure to request location permission before starting the service.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _startActivityRecognition();
    await _initializeBackgroundGeolocation();
  }

  /// Starts listening to the activity recognition stream.
  void _startActivityRecognition() {
    // _activitySubscription = _activityRecognition.activityStream.listen(
    //   (ActivityEvent event) {
    //     currentActivity = event;
    //     print("Detected activity: ${event.type}");
    //     if (event.type == ActivityType.in_vehicle) {
    //       print("User is driving!");
    //     }
    //   },
    //   onError: (error) {
    //     print("Activity Recognition error: $error");
    //   },
    // );

    _activitySubscription =
        _activityRecognition.activityStream(runForegroundService: true).listen(
      (ActivityEvent event) {
        currentActivity = event;
        // Only log if it's a significant state change
        if (event.type == ActivityType.IN_VEHICLE) {
          debugPrint("Driving activity detected");
        }
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
      print('[BackgroundGeolocation] - Location: $location');
    }, (bg.LocationError error) {
      print('[BackgroundGeolocation] ERROR: $error');
    });

    // Optionally, listen for motion changes.
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[BackgroundGeolocation] - Motion changed: $location');
    });

    // Configure the plugin for continuous background tracking.
    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 50.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_ERROR,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });
  }

  // Listen to app lifecycle state changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    currentLifecycleState = state;
    print("AppLifecycleState changed to: $state");
  }

  /// Dispose resources when the service is no longer needed.
  /// Optionally stops background tracking if desired.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activitySubscription?.cancel();
    bg.BackgroundGeolocation.stop();
  }
}
