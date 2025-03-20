import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationInSeconds;
  final double miles;
  final double? earnings;
  final double? expenses;
  final List<LocationPoint> locations;
  final bool isActive;

  TrackingSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.durationInSeconds,
    required this.miles,
    this.earnings,
    this.expenses,
    required this.locations,
    required this.isActive,
  });

  factory TrackingSession.start({
    required String userId,
    required DateTime startTime,
    required LocationPoint initialLocation,
  }) {
    return TrackingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      startTime: startTime,
      endTime: null,
      durationInSeconds: 0,
      miles: 0,
      earnings: null,
      expenses: null,
      locations: [initialLocation],
      isActive: true,
    );
  }

  TrackingSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationInSeconds,
    double? miles,
    double? earnings,
    double? expenses,
    List<LocationPoint>? locations,
    bool? isActive,
  }) {
    return TrackingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      miles: miles ?? this.miles,
      earnings: earnings ?? this.earnings,
      expenses: expenses ?? this.expenses,
      locations: locations ?? this.locations,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationInSeconds': durationInSeconds,
      'miles': miles,
      'earnings': earnings,
      'expenses': expenses,
      'locations': locations.map((loc) => loc.toMap()).toList(),
      'isActive': isActive,
    };
  }

  factory TrackingSession.fromMap(Map<String, dynamic> map) {
    return TrackingSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      durationInSeconds: map['durationInSeconds']?.toInt() ?? 0,
      miles: map['miles']?.toDouble() ?? 0.0,
      earnings: map['earnings']?.toDouble(),
      expenses: map['expenses']?.toDouble(),
      locations: List<LocationPoint>.from(
        (map['locations'] ?? []).map(
          (x) => LocationPoint.fromMap(x),
        ),
      ),
      isActive: map['isActive'] ?? false,
    );
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  // Create from background_geolocation Location
  factory LocationPoint.fromBgLocation(dynamic location) {
    return LocationPoint(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      timestamp: DateTime.now(),
    );
  }
}

// Model for summarizing tracking data over different time periods
class TrackingInsights {
  final double totalMiles;
  final int totalDurationInSeconds;
  final double totalEarnings;
  final double totalExpenses;
  final int sessionCount;

  TrackingInsights({
    required this.totalMiles,
    required this.totalDurationInSeconds,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.sessionCount,
  });

  // Factory method to create insights from a list of sessions
  factory TrackingInsights.fromSessions(List<TrackingSession> sessions) {
    double totalMiles = 0;
    int totalDurationInSeconds = 0;
    double totalEarnings = 0;
    double totalExpenses = 0;

    for (final session in sessions) {
      totalMiles += session.miles;
      totalDurationInSeconds += session.durationInSeconds;
      if (session.earnings != null) totalEarnings += session.earnings!;
      if (session.expenses != null) totalExpenses += session.expenses!;
    }

    return TrackingInsights(
      totalMiles: totalMiles,
      totalDurationInSeconds: totalDurationInSeconds,
      totalEarnings: totalEarnings,
      totalExpenses: totalExpenses,
      sessionCount: sessions.length,
    );
  }

  // Get hours from seconds
  double get hours => totalDurationInSeconds / 3600;
}
