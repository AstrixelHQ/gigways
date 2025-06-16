import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

class DensityGrid {
  final String id;
  final LatLng center;
  final LatLng topLeft;
  final LatLng bottomRight;
  final int driverCount;
  final DateTime lastUpdated;
  final DensityLevel level;

  const DensityGrid({
    required this.id,
    required this.center,
    required this.topLeft,
    required this.bottomRight,
    required this.driverCount,
    required this.lastUpdated,
    this.level = DensityLevel.low,
  });
}

class DensityForecast {
  final String gridId;
  final int predictedDriverCount;
  final DateTime forecastTime;
  final ForecastPeriod period;
  final double confidence;

  const DensityForecast({
    required this.gridId,
    required this.predictedDriverCount,
    required this.forecastTime,
    required this.period,
    required this.confidence,
  });
}

class DriverLocationData {
  final String driverId;
  final LatLng location;
  final DateTime timestamp;
  final bool isActive;
  final String? gridId;

  const DriverLocationData({
    required this.driverId,
    required this.location,
    required this.timestamp,
    required this.isActive,
    this.gridId,
  });
}

class DensityStats {
  final int cityDrivers;
  final int stateDrivers;
  final int nationalDrivers;
  final String cityName;
  final String stateName;
  final DateTime lastUpdated;

  const DensityStats({
    required this.cityDrivers,
    required this.stateDrivers,
    required this.nationalDrivers,
    required this.cityName,
    required this.stateName,
    required this.lastUpdated,
  });
}

enum DensityLevel {
  @JsonValue('low')
  low,
  @JsonValue('moderate')
  moderate,
  @JsonValue('high')
  high,
}

enum ForecastPeriod {
  @JsonValue('15min')
  fifteenMinutes,
  @JsonValue('30min')
  thirtyMinutes,
  @JsonValue('1hour')
  oneHour,
}

extension DensityLevelExtension on DensityLevel {
  String get displayName {
    switch (this) {
      case DensityLevel.low:
        return 'Low';
      case DensityLevel.moderate:
        return 'Moderate';
      case DensityLevel.high:
        return 'High';
    }
  }

  double get opacity {
    switch (this) {
      case DensityLevel.low:
        return 0.3;
      case DensityLevel.moderate:
        return 0.5;
      case DensityLevel.high:
        return 0.7;
    }
  }
}

extension ForecastPeriodExtension on ForecastPeriod {
  String get displayName {
    switch (this) {
      case ForecastPeriod.fifteenMinutes:
        return '15 min';
      case ForecastPeriod.thirtyMinutes:
        return '30 min';
      case ForecastPeriod.oneHour:
        return '1 hour';
    }
  }

  Duration get duration {
    switch (this) {
      case ForecastPeriod.fifteenMinutes:
        return const Duration(minutes: 15);
      case ForecastPeriod.thirtyMinutes:
        return const Duration(minutes: 30);
      case ForecastPeriod.oneHour:
        return const Duration(hours: 1);
    }
  }
}
