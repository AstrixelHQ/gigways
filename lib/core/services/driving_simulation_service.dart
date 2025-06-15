import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/services/driving_detection_service.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:gigways/core/services/real_location_simulation_service.dart';
import 'package:gigways/features/tracking/services/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driving_simulation_service.g.dart';

/// Real-world driving route with waypoints
class DrivingRoute {
  final String name;
  final List<LatLng> waypoints;
  final Duration estimatedDuration;
  final double totalDistanceKm;
  final String description;

  DrivingRoute({
    required this.name,
    required this.waypoints,
    required this.estimatedDuration,
    required this.totalDistanceKm,
    required this.description,
  });
}

/// Coordinate class for lat/lng
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

/// Driving simulation parameters
class SimulationParams {
  final DrivingRoute route;
  final double speedMultiplier; // 1.0 = real time, 2.0 = 2x speed
  final bool includeTrafficDelays;
  final bool includeStops;
  final bool simulatePhoneUsage;
  final double accuracyVariation; // GPS accuracy variation in meters
  final bool useRealGPS; // NEW: Actually move phone's GPS location

  SimulationParams({
    required this.route,
    this.speedMultiplier = 1.0,
    this.includeTrafficDelays = true,
    this.includeStops = true,
    this.simulatePhoneUsage = false,
    this.accuracyVariation = 5.0,
    this.useRealGPS = false, // Default to virtual simulation
  });
}

/// Current simulation state
class SimulationState {
  final bool isRunning;
  final LatLng? currentLocation;
  final double currentSpeedKmh;
  final ActivityType currentActivity;
  final Duration elapsed;
  final double progressPercent;
  final int currentWaypointIndex;
  final String status;
  final double totalDistanceTraveled;

  SimulationState({
    this.isRunning = false,
    this.currentLocation,
    this.currentSpeedKmh = 0.0,
    this.currentActivity = ActivityType.STILL,
    this.elapsed = Duration.zero,
    this.progressPercent = 0.0,
    this.currentWaypointIndex = 0,
    this.status = 'Stopped',
    this.totalDistanceTraveled = 0.0,
  });

  SimulationState copyWith({
    bool? isRunning,
    LatLng? currentLocation,
    double? currentSpeedKmh,
    ActivityType? currentActivity,
    Duration? elapsed,
    double? progressPercent,
    int? currentWaypointIndex,
    String? status,
    double? totalDistanceTraveled,
  }) {
    return SimulationState(
      isRunning: isRunning ?? this.isRunning,
      currentLocation: currentLocation ?? this.currentLocation,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentActivity: currentActivity ?? this.currentActivity,
      elapsed: elapsed ?? this.elapsed,
      progressPercent: progressPercent ?? this.progressPercent,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      status: status ?? this.status,
      totalDistanceTraveled: totalDistanceTraveled ?? this.totalDistanceTraveled,
    );
  }
}

class DrivingSimulationService {
  static final DrivingSimulationService _instance = DrivingSimulationService._internal();
  factory DrivingSimulationService() => _instance;
  DrivingSimulationService._internal();

  // Simulation state
  SimulationState _state = SimulationState();
  SimulationParams? _params;
  Timer? _simulationTimer;
  final Random _random = Random();

  // Services
  DrivingDetectionService? _drivingDetectionService;
  NotificationService? _notificationService;
  LocationService? _locationService;
  RealLocationSimulationService? _realLocationService;

  // Stream controllers
  final _stateController = StreamController<SimulationState>.broadcast();
  Stream<SimulationState> get stateStream => _stateController.stream;
  SimulationState get currentState => _state;

  // Simulation tracking
  DateTime? _simulationStartTime;
  int _currentRouteIndex = 0;
  double _progressOnCurrentSegment = 0.0;

  /// Initialize the simulation service
  Future<void> initialize() async {
    _notificationService = NotificationService();
    debugPrint('🚗 Driving Simulation Service initialized');
  }

  /// Set service dependencies
  void setServices({
    DrivingDetectionService? drivingDetectionService,
    LocationService? locationService,
    RealLocationSimulationService? realLocationService,
  }) {
    _drivingDetectionService = drivingDetectionService;
    _locationService = locationService;
    _realLocationService = realLocationService;
  }

  /// Start driving simulation
  Future<void> startSimulation(SimulationParams params) async {
    if (_state.isRunning) {
      debugPrint('⚠️ Simulation already running');
      return;
    }

    _params = params;
    _simulationStartTime = DateTime.now();
    _currentRouteIndex = 0;
    _progressOnCurrentSegment = 0.0;

    _state = _state.copyWith(
      isRunning: true,
      currentLocation: params.route.waypoints.first,
      currentActivity: ActivityType.IN_VEHICLE,
      status: 'Starting journey: ${params.route.name}',
      progressPercent: 0.0,
      currentWaypointIndex: 0,
      totalDistanceTraveled: 0.0,
    );

    _updateState();

    // Start simulation timer - update every 500ms for smooth movement
    _simulationTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      _updateSimulation();
    });

    // Notify driving detection service immediately
    _drivingDetectionService?.simulateActivityChange(ActivityType.IN_VEHICLE);

    // Start real GPS simulation if enabled
    if (params.useRealGPS && _realLocationService != null) {
      final success = await _realLocationService!.startRouteSimulation(
        waypoints: params.route.waypoints,
        speedKmh: 50.0, // Base speed, will be adjusted dynamically
        statusCallback: (status) {
          debugPrint('🍎 Real GPS: $status');
        },
      );
      
      if (!success) {
        debugPrint('⚠️ Failed to start real GPS simulation, falling back to virtual');
      }
    }

    debugPrint('🚗 Started simulation: ${params.route.name} ${params.useRealGPS ? "(Real GPS)" : "(Virtual)"}');
  }

  /// Stop driving simulation
  Future<void> stopSimulation() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    // Stop real GPS simulation if running
    if (_params?.useRealGPS == true) {
      await _realLocationService?.stopSimulation();
    }

    _state = _state.copyWith(
      isRunning: false,
      currentSpeedKmh: 0.0,
      currentActivity: ActivityType.STILL,
      status: 'Simulation stopped',
    );

    _updateState();

    // Notify driving detection service
    _drivingDetectionService?.simulateActivityChange(ActivityType.STILL);

    debugPrint('🛑 Stopped driving simulation');
  }

  /// Pause/resume simulation
  Future<void> togglePause() async {
    if (!_state.isRunning) return;

    if (_simulationTimer?.isActive == true) {
      _simulationTimer?.cancel();
      _state = _state.copyWith(
        currentSpeedKmh: 0.0,
        currentActivity: ActivityType.STILL,
        status: 'Paused - ${_params?.route.name}',
      );
      _drivingDetectionService?.simulateActivityChange(ActivityType.STILL);
    } else {
      _simulationTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
        _updateSimulation();
      });
      _state = _state.copyWith(
        currentActivity: ActivityType.IN_VEHICLE,
        status: 'Resumed - ${_params?.route.name}',
      );
      _drivingDetectionService?.simulateActivityChange(ActivityType.IN_VEHICLE);
    }

    _updateState();
  }

  /// Update simulation state
  void _updateSimulation() {
    if (_params == null || !_state.isRunning) return;

    final route = _params!.route;
    final elapsed = DateTime.now().difference(_simulationStartTime!);
    
    // Calculate progress through route
    final totalDurationMs = route.estimatedDuration.inMilliseconds / _params!.speedMultiplier;
    final progressPercent = (elapsed.inMilliseconds / totalDurationMs * 100).clamp(0.0, 100.0);

    if (progressPercent >= 100.0) {
      // Journey complete
      _completeJourney();
      return;
    }

    // Calculate current position
    final currentPosition = _calculateCurrentPosition(progressPercent / 100.0);
    final currentSpeed = _calculateCurrentSpeed(progressPercent / 100.0);

    // Update state
    _state = _state.copyWith(
      currentLocation: currentPosition,
      currentSpeedKmh: currentSpeed,
      elapsed: elapsed,
      progressPercent: progressPercent,
      status: _generateStatusMessage(progressPercent, currentSpeed),
      totalDistanceTraveled: (route.totalDistanceKm * progressPercent / 100.0),
    );

    _updateState();

    // Send location update to services
    _sendLocationUpdate(currentPosition, currentSpeed);
  }

  /// Calculate current position along route
  LatLng _calculateCurrentPosition(double progress) {
    final route = _params!.route;
    final waypoints = route.waypoints;
    
    if (waypoints.length < 2) return waypoints.first;

    // Find which segment we're on
    final segmentProgress = progress * (waypoints.length - 1);
    final segmentIndex = segmentProgress.floor().clamp(0, waypoints.length - 2);
    final segmentLocalProgress = segmentProgress - segmentIndex;

    final start = waypoints[segmentIndex];
    final end = waypoints[segmentIndex + 1];

    // Interpolate between waypoints with some GPS noise
    final lat = start.latitude + (end.latitude - start.latitude) * segmentLocalProgress;
    final lng = start.longitude + (end.longitude - start.longitude) * segmentLocalProgress;

    // Add GPS accuracy variation
    final latNoise = (_random.nextDouble() - 0.5) * _params!.accuracyVariation * 0.00001;
    final lngNoise = (_random.nextDouble() - 0.5) * _params!.accuracyVariation * 0.00001;

    _state = _state.copyWith(currentWaypointIndex: segmentIndex);

    return LatLng(lat + latNoise, lng + lngNoise);
  }

  /// Calculate realistic speed based on position and conditions
  double _calculateCurrentSpeed(double progress) {
    // Base speeds for different parts of journey
    final baseSpeed = 45.0 + _random.nextDouble() * 20.0; // 45-65 km/h average
    
    // Simulate traffic conditions
    double speedMultiplier = 1.0;
    
    if (_params!.includeTrafficDelays) {
      // Randomly slow down for traffic (10% chance every update)
      if (_random.nextDouble() < 0.1) {
        speedMultiplier = 0.3 + _random.nextDouble() * 0.4; // 30-70% speed
      }
    }

    if (_params!.includeStops) {
      // Simulate stops at traffic lights/intersections (5% chance)
      if (_random.nextDouble() < 0.05) {
        return 0.0; // Complete stop
      }
    }

    // Vary speed naturally
    final naturalVariation = 0.8 + _random.nextDouble() * 0.4; // ±20% variation
    
    return (baseSpeed * speedMultiplier * naturalVariation).clamp(0.0, 80.0);
  }

  /// Generate status message
  String _generateStatusMessage(double progress, double speed) {
    final route = _params!.route;
    
    if (speed == 0.0) {
      return 'Stopped - ${route.name}';
    } else if (speed < 20.0) {
      return 'Heavy traffic - ${route.name}';
    } else if (speed > 60.0) {
      return 'Highway driving - ${route.name}';
    } else {
      return 'City driving - ${route.name}';
    }
  }

  /// Complete the journey
  void _completeJourney() {
    _simulationTimer?.cancel();
    
    _state = _state.copyWith(
      isRunning: false,
      currentSpeedKmh: 0.0,
      currentActivity: ActivityType.STILL,
      progressPercent: 100.0,
      status: 'Journey completed: ${_params!.route.name}',
      totalDistanceTraveled: _params!.route.totalDistanceKm,
    );

    _updateState();
    _drivingDetectionService?.simulateActivityChange(ActivityType.STILL);

    // Show completion notification
    _notificationService?.show(
      NotificationData(
        title: '🏁 Journey Completed',
        body: 'Simulation of ${_params!.route.name} finished successfully!',
        channel: NotificationChannel.system,
        autoCancel: true,
        timeoutAfter: Duration(minutes: 2),
      ),
    );

    debugPrint('🏁 Journey completed: ${_params!.route.name}');
  }

  /// Send location update to tracking services
  void _sendLocationUpdate(LatLng position, double speed) {
    // Update real GPS location if enabled
    if (_params?.useRealGPS == true && _realLocationService != null) {
      _realLocationService!.changeSpeed(speed);
      // Real location updates are handled by the RealLocationSimulationService
    }

    // Create a mock location event for background geolocation (for virtual simulation)
    final mockLocation = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': speed / 3.6, // Convert km/h to m/s
      'heading': _random.nextDouble() * 360,
      'accuracy': _params!.accuracyVariation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // You can emit this to location service if needed
    debugPrint('📍 ${_params?.useRealGPS == true ? "Real GPS" : "Virtual"}: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} - Speed: ${speed.toStringAsFixed(1)} km/h');
  }

  /// Update state and notify listeners
  void _updateState() {
    _stateController.add(_state);
  }

  /// Get predefined realistic routes
  static List<DrivingRoute> getPredefinedRoutes() {
    return [
      // Short city route
      DrivingRoute(
        name: 'City Center Loop',
        waypoints: [
          LatLng(37.7749, -122.4194), // San Francisco
          LatLng(37.7849, -122.4094),
          LatLng(37.7949, -122.4094),
          LatLng(37.7949, -122.4294),
          LatLng(37.7749, -122.4194),
        ],
        estimatedDuration: Duration(minutes: 15),
        totalDistanceKm: 12.5,
        description: 'Quick city loop with traffic lights and urban driving',
      ),
      
      // Medium suburban route
      DrivingRoute(
        name: 'Suburb to Downtown',
        waypoints: [
          LatLng(37.7849, -122.4594), // Suburb
          LatLng(37.7749, -122.4494),
          LatLng(37.7649, -122.4394),
          LatLng(37.7549, -122.4294), 
          LatLng(37.7449, -122.4194), // Downtown
        ],
        estimatedDuration: Duration(minutes: 25),
        totalDistanceKm: 18.7,
        description: 'Typical commute from residential area to city center',
      ),
      
      // Long highway route
      DrivingRoute(
        name: 'Highway Road Trip',
        waypoints: [
          LatLng(37.7749, -122.4194), // San Francisco
          LatLng(37.6749, -122.3194),
          LatLng(37.5749, -122.2194),
          LatLng(37.4749, -122.1194),
          LatLng(37.3749, -122.0194), // San Jose area
        ],
        estimatedDuration: Duration(minutes: 45),
        totalDistanceKm: 65.3,
        description: 'Long highway drive with high speeds and minimal stops',
      ),
      
      // Delivery route with multiple stops
      DrivingRoute(
        name: 'Delivery Route',
        waypoints: [
          LatLng(37.7749, -122.4194), // Start
          LatLng(37.7849, -122.4094), // Stop 1
          LatLng(37.7949, -122.4194), // Stop 2
          LatLng(37.7849, -122.4294), // Stop 3
          LatLng(37.7649, -122.4094), // Stop 4
          LatLng(37.7749, -122.4194), // Return
        ],
        estimatedDuration: Duration(minutes: 35),
        totalDistanceKm: 28.2,
        description: 'Multiple stops with frequent start/stop driving',
      ),
    ];
  }

  /// Quick test methods
  Future<void> quickTestNotification() async {
    await _drivingDetectionService?.forceNotification(
      customTitle: '🧪 Quick Test',
      customBody: 'Testing notification system from simulation service',
    );
  }

  Future<void> quickTestDrivingDetection() async {
    await _drivingDetectionService?.simulateDrivingDetected();
  }

  /// Quick real GPS tests
  Future<void> teleportToSanFrancisco() async {
    await _realLocationService?.teleportTo(LatLng(37.7749, -122.4194));
  }

  Future<void> teleportToGoldenGate() async {
    await _realLocationService?.teleportTo(LatLng(37.8199, -122.4783));
  }

  Future<void> simulateQuickDrive() async {
    await _realLocationService?.simulateMovement(
      from: LatLng(37.7749, -122.4194), // SF Downtown
      to: LatLng(37.7849, -122.4094),   // Chinatown
      speedKmh: 30.0,
    );
  }

  /// Dispose resources
  void dispose() {
    _simulationTimer?.cancel();
    _stateController.close();
  }
}

@Riverpod(keepAlive: true)
DrivingSimulationService drivingSimulationService(Ref ref) {
  final service = DrivingSimulationService();
  service.initialize();
  
  // Set up service dependencies
  service.setServices(
    drivingDetectionService: ref.read(drivingDetectionServiceProvider),
    realLocationService: ref.read(realLocationSimulationServiceProvider),
  );
  
  ref.onDispose(() => service.dispose());
  return service;
}