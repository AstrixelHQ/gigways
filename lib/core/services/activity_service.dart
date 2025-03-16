import 'dart:async';
import 'package:flutter/material.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:permission_handler/permission_handler.dart';

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
        print("Detected activity: ${event.type}");
        if (event.type == ActivityType.IN_VEHICLE) {
          print("User is driving!");
        }
      },
      onError: (error) {
        print("Activity Recognition error: $error");
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
      stopOnTerminate: false, // Continue tracking if the app is killed.
      startOnBoot: true, // Restart tracking on device boot.
      debug: false, // Set to true for debugging.
      logLevel: bg.Config.LOG_LEVEL_OFF,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
      print('[BackgroundGeolocation] enabled: ${state.enabled}');
    });
  }

  /// Requests location permission by showing a bottom sheet as per platform guidelines.
  /// Returns `true` if permission is granted, otherwise `false`.
  Future<bool> requestLocationPermission(BuildContext context) async {
    // Show bottom sheet to explain why we need location permission.
    bool userAccepted = await _showLocationPermissionSheet(context);
    if (!userAccepted) {
      return false;
    }

    // Request foreground location permission.
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      print("Foreground location permission not granted.");
      return false;
    }

    // For continuous background tracking, request background location permission.
    PermissionStatus backgroundStatus =
        await Permission.locationAlways.request();
    if (!backgroundStatus.isGranted) {
      print("Background location permission not granted.");
      return false;
    }
    return true;
  }

  /// Displays a bottom sheet explaining the need for location permission.
  /// Returns a [Future<bool>] that resolves to true if the user chooses to allow, false otherwise.
  Future<bool> _showLocationPermissionSheet(BuildContext context) async {
    return (await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext bc) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Location Permission Required",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "This app needs location access to detect your activity even when running in the background. "
                    "Please allow location access so that we can provide the best experience.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(bc, true);
                    },
                    child: Text("Allow Permission"),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(bc, false);
                    },
                    child: Text("Cancel"),
                  ),
                ],
              ),
            );
          },
        )) ??
        false;
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
    // Uncomment the following line if you wish to stop background tracking when disposing.
    bg.BackgroundGeolocation.stop();
  }
}
