import 'dart:math';
import 'dart:async';
import 'package:location/location.dart';
import 'package:vector_math/vector_math.dart';

class MotionDetector {
  // Constants for algorithm tuning
  static const int _samplingPeriodSeconds = 10;
  static const int _minSamplesForAnalysis = 5;
  static const double _minDrivingSpeedMps = 5.0; // Adjust as needed
  static const double _maxWalkingSpeedMps = 2.0; // Not used in this example
  static const double _suddenSpeedChangeThreshold = 5.0; // m/s²
  static const double _consistentDirectionThreshold = 20.0; // degrees

  // Confidence score settings
  static const int _maxConfidence = 10;
  static const int _confidenceThreshold = 5;
  int _drivingConfidence = 0;

  final List<LocationData> _locationSamples = [];
  Timer? _samplingTimer;
  bool _isCurrentlyDriving = false;

  // Stream controller to broadcast driving state changes
  final _drivingStateController = StreamController<bool>.broadcast();
  Stream<bool> get drivingStateStream => _drivingStateController.stream;

  // Initialize location service
  final Location _location = Location();

  Future<void> startDetection() async {
    print('📱 Starting motion detection...');

    // Request permission and initialize location updates
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location service not enabled, requesting...');
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('❌ Failed to enable location service');
        throw Exception('Location service not enabled');
      }
    }
    print('✅ Location service enabled');

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      print('⚠️ Location permission denied, requesting...');
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        print('❌ Location permission not granted');
        throw Exception('Location permission not granted');
      }
    }
    print('✅ Location permission granted');

    // Configure location settings for driving detection
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1 second
      distanceFilter: 5, // 5 meters
    );
    print(
        '✅ Location settings configured: High accuracy, 1s interval, 5m filter');

    // Start collecting location samples
    _location.onLocationChanged.listen(_handleLocationUpdate);
    _startSamplingTimer();
    print('🚀 Motion detection system initialized and running');
  }

  void _handleLocationUpdate(LocationData locationData) {
    _locationSamples.add(locationData);
    print(
        '📍 New location: ${locationData.latitude}, ${locationData.longitude}');
    print('   Speed: ${locationData.speed?.toStringAsFixed(2)} m/s');
    print('   Heading: ${locationData.heading?.toStringAsFixed(2)}°');

    // Keep only recent samples (a sliding window)
    if (_locationSamples.length > _minSamplesForAnalysis * 2) {
      _locationSamples.removeAt(0);
      print('📊 Maintaining sample window: ${_locationSamples.length} samples');
    }
  }

  void _startSamplingTimer() {
    _samplingTimer?.cancel();
    _samplingTimer = Timer.periodic(
      Duration(seconds: _samplingPeriodSeconds),
      (_) {
        print('\n🔄 Starting motion analysis cycle...');
        _analyzeMotion();
      },
    );
    print(
        '⏱️ Sampling timer started: $_samplingPeriodSeconds second intervals');
  }

  void _analyzeMotion() {
    if (_locationSamples.length < _minSamplesForAnalysis) {
      print(
          '⚠️ Not enough samples for analysis. Current: ${_locationSamples.length}, Required: $_minSamplesForAnalysis');
      return;
    }

    print('📊 Analyzing ${_locationSamples.length} location samples...');
    final metrics = _calculateMotionMetrics();

    print('\n📈 Motion Metrics:');
    print('   Median Speed: ${metrics.medianSpeed.toStringAsFixed(2)} m/s');
    print(
        '   Max Acceleration: ${metrics.maxAcceleration.toStringAsFixed(2)} m/s²');
    print(
        '   Average Bearing Change: ${metrics.averageBearingChange.toStringAsFixed(2)}°');

    // Evaluate conditions
    bool speedHigh = metrics.medianSpeed > _minDrivingSpeedMps;
    bool accelerationHigh =
        metrics.maxAcceleration > _suddenSpeedChangeThreshold;
    bool directionStable =
        metrics.averageBearingChange < _consistentDirectionThreshold;

    print('\n🧮 Condition Evaluation:');
    print('   Speed high (median > $_minDrivingSpeedMps): $speedHigh');
    print(
        '   Sudden acceleration (max > $_suddenSpeedChangeThreshold): $accelerationHigh');
    print(
        '   Direction stable (avg bearing change < $_consistentDirectionThreshold): $directionStable');

    // Use a simple scoring mechanism (2 out of 3 indicators required)
    int score = 0;
    if (speedHigh) score++;
    if (accelerationHigh) score++;
    if (directionStable) score++;

    // Adjust the confidence score
    if (score >= 2) {
      _drivingConfidence = min(_drivingConfidence + 1, _maxConfidence);
    } else {
      _drivingConfidence = max(_drivingConfidence - 1, 0);
    }

    print('   Driving confidence score: $_drivingConfidence/$_maxConfidence');

    // Decide driving state based on confidence threshold
    bool newDrivingState = _drivingConfidence >= _confidenceThreshold;
    if (newDrivingState != _isCurrentlyDriving) {
      _isCurrentlyDriving = newDrivingState;
      _drivingStateController.add(newDrivingState);
      print(
          '\n🚗 DRIVING STATE CHANGED: ${newDrivingState ? "DRIVING" : "NOT DRIVING"}');
    } else {
      print(
          '\n✨ Current state maintained: ${_isCurrentlyDriving ? "DRIVING" : "NOT DRIVING"}');
    }
  }

  MotionMetrics _calculateMotionMetrics() {
    List<double> speeds = [];
    List<double> accelerations = [];
    List<double> bearings = [];

    print('\n🔢 Calculating motion metrics...');

    for (int i = 1; i < _locationSamples.length; i++) {
      final current = _locationSamples[i];
      final previous = _locationSamples[i - 1];

      // Calculate distance using Haversine formula
      final distance = _calculateDistance(
        previous.latitude!,
        previous.longitude!,
        current.latitude!,
        current.longitude!,
      );

      // Calculate time difference in seconds (assuming time is in microseconds)
      final timeDiffSeconds = (current.time! - previous.time!) / 1000000;
      if (timeDiffSeconds <= 0) continue;

      // Speed in m/s
      final speed = distance / timeDiffSeconds;
      speeds.add(speed);

      print('   Sample ${i}: Distance: ${distance.toStringAsFixed(2)}m, '
          'Speed: ${speed.toStringAsFixed(2)} m/s');

      // Calculate acceleration if possible
      if (i > 1) {
        final previousSpeed = speeds[speeds.length - 2];
        final acceleration = (speed - previousSpeed) / timeDiffSeconds;
        accelerations.add(acceleration.abs());
        print('   Acceleration: ${acceleration.toStringAsFixed(2)} m/s²');
      }

      // Calculate bearing changes if headings are available
      if (current.heading != null && previous.heading != null) {
        final bearingDiff = (current.heading! - previous.heading!).abs();
        final normalizedBearing =
            bearingDiff <= 180 ? bearingDiff : 360 - bearingDiff;
        bearings.add(normalizedBearing);
        print('   Bearing change: ${normalizedBearing.toStringAsFixed(2)}°');
      }
    }

    return MotionMetrics(
      medianSpeed: speeds.isEmpty ? 0 : _median(speeds),
      maxAcceleration: accelerations.isEmpty ? 0 : accelerations.reduce(max),
      averageBearingChange: bearings.isEmpty
          ? 0
          : bearings.reduce((a, b) => a + b) / bearings.length,
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    double lat1Rad = radians(lat1);
    double lat2Rad = radians(lat2);
    double deltaLat = radians(lat2 - lat1);
    double deltaLon = radians(lon2 - lon1);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    List<double> sorted = List.from(values)..sort();
    int mid = sorted.length ~/ 2;
    return (sorted.length % 2 == 1)
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  void dispose() {
    print('🛑 Disposing motion detector...');
    _samplingTimer?.cancel();
    _drivingStateController.close();
    print('✅ Motion detector disposed');
  }
}

class MotionMetrics {
  final double medianSpeed;
  final double maxAcceleration;
  final double averageBearingChange;

  MotionMetrics({
    required this.medianSpeed,
    required this.maxAcceleration,
    required this.averageBearingChange,
  });
}
