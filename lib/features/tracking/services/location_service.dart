import 'dart:async';
import 'dart:math' show cos, sqrt, asin, sin, pi;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

part 'location_service.g.dart';

/// Service to handle location tracking and distance calculation
class LocationService {
  // Stream controller for location updates
  final _locationController = StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get locationStream => _locationController.stream;

  // Stream controller for activity updates
  final _activityController = StreamController<ActivityEvent>.broadcast();
  Stream<ActivityEvent> get activityStream => _activityController.stream;

  // Store current activity
  ActivityEvent? _currentActivity;
  ActivityEvent? get currentActivity => _currentActivity;

  // Store last location for distance calculation
  LocationPoint? _lastLocation;

  // Subscription for background location
  StreamSubscription<bg.Location>? _locationSubscription;
  // Subscription for activity recognition
  StreamSubscription<ActivityEvent>? _activitySubscription;

  // Flag to indicate if tracking is active
  bool _isTrackingActive = false;
  bool get isTrackingActive => _isTrackingActive;

  // Initialize the service
  Future<void> initialize() async {
    // Set up activity recognition
    final activityRecognition = ActivityRecognition();
    _activitySubscription = activityRecognition.activityStream().listen(
      (ActivityEvent event) {
        _currentActivity = event;
        _activityController.add(event);
      },
      onError: (error) {
        print('Activity Recognition Error: $error');
      },
    );

    // Configure background geolocation
    await bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0, // meters
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_ERROR,
    ));

    print('Location service initialized');
  }

  // Start tracking location
  Future<LocationPoint?> startTracking() async {
    if (_isTrackingActive) return _lastLocation;

    print('Starting location tracking');
    _isTrackingActive = true;

    // Set up listener for location updates
    // _locationSubscription = bg.BackgroundGeolocation.onLocation.listen(
    //   (bg.Location location) {
    //     final locationPoint = LocationPoint(
    //       latitude: location.coords.latitude,
    //       longitude: location.coords.longitude,
    //       timestamp: DateTime.now(),
    //     );

    //     _lastLocation = locationPoint;
    //     _locationController.add(locationPoint);
    //   },
    // );

    bg.BackgroundGeolocation.onLocation(
      (success) {
        final locationPoint = LocationPoint(
          latitude: success.coords.latitude,
          longitude: success.coords.longitude,
          timestamp: DateTime.now(),
        );

        _lastLocation = locationPoint;
        _locationController.add(locationPoint);
      },
    );

    // Start background geolocation
    await bg.BackgroundGeolocation.start();

    // Try to get current location
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        timeout: 10,
        maximumAge: 5000,
        desiredAccuracy: 10,
        persist: false,
      );

      _lastLocation = LocationPoint(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        timestamp: DateTime.now(),
      );

      return _lastLocation;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTrackingActive) return;

    print('Stopping location tracking');
    _isTrackingActive = false;

    // Cancel background geolocation
    await bg.BackgroundGeolocation.stop();
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(LocationPoint point1, LocationPoint point2) {
    const double earthRadius = 6371000; // in meters

    final double lat1 = point1.latitude * pi / 180;
    final double lon1 = point1.longitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double lon2 = point2.longitude * pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));

    // Return distance in meters
    return earthRadius * c;
  }

  // Calculate total distance for a list of location points
  static double calculateTotalDistance(List<LocationPoint> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i], points[i + 1]);
    }

    // Convert meters to miles
    return totalDistance / 1609.34;
  }

  // Dispose resources
  void dispose() {
    _locationController.close();
    _activityController.close();
    _locationSubscription?.cancel();
    _activitySubscription?.cancel();
    bg.BackgroundGeolocation.stop();
  }

  // Check if current activity is likely driving
  bool isDriving() {
    if (_currentActivity == null) return false;
    return _currentActivity!.type == ActivityType.IN_VEHICLE;
  }
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  final service = LocationService();

  // Initialize the service
  service.initialize();

  // Make sure to dispose when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
