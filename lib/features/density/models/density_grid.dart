import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

part 'density_grid.freezed.dart';
part 'density_grid.g.dart';

@freezed
sealed class DensityGrid with _$DensityGrid {
  const DensityGrid._();
  const factory DensityGrid({
    required String gridId,
    @JsonKey(fromJson: _latLngListFromJson, toJson: _latLngListToJson)
    required List<LatLng> hexagonBounds,
    required int population,
    required int estimatedDrivers,
    required DensityLevel level,
    required String cityName,
    required String countyName,
    required String stateName,
    required DateTime lastUpdated,
  }) = _DensityGrid;

  factory DensityGrid.fromJson(Map<String, dynamic> json) =>
      _$DensityGridFromJson(json);

  factory DensityGrid.fromFirestore(Map<String, dynamic> data) {
    try {
      print('DEBUG: Parsing DensityGrid with data keys: ${data.keys.toList()}');
      return DensityGrid(
        gridId: data['gridId'] as String,
        hexagonBounds: (data['hexagonBounds'] as List)
            .map((point) =>
                LatLng(point['lat'] as double, point['lng'] as double))
            .toList(),
        population: data['population'] as int,
        estimatedDrivers: data['estimatedDrivers'] as int,
        level: DensityLevel.values.firstWhere(
          (e) => e.name == data['level'],
          orElse: () => DensityLevel.low,
        ),
        cityName: data['cityName'] as String,
        countyName: data['countyName'] as String,
        stateName: data['stateName'] as String,
        lastUpdated: _parseTimestamp(data['lastUpdated']),
      );
    } catch (e) {
      print('DEBUG: Error parsing DensityGrid: $e');
      print('DEBUG: Data structure: $data');
      throw Exception('Failed to parse DensityGrid from Firestore: $e');
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is Map) {
      // Handle Cloud Function format: {_seconds: xxx, _nanoseconds: xxx}
      final seconds = timestamp['_seconds'] as int;
      final nanoseconds = timestamp['_nanoseconds'] as int;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds / 1000000).round(),
      );
    } else {
      return DateTime.now(); // Fallback
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gridId': gridId,
      'hexagonBounds': hexagonBounds
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'population': population,
      'estimatedDrivers': estimatedDrivers,
      'level': level.name,
      'cityName': cityName,
      'countyName': countyName,
      'stateName': stateName,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

enum DensityLevel {
  low,
  moderate,
  high;

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

  String get description {
    switch (this) {
      case DensityLevel.low:
        return 'Few drivers in this area';
      case DensityLevel.moderate:
        return 'Moderate driver activity';
      case DensityLevel.high:
        return 'High driver concentration';
    }
  }

  // Color representations for map display
  int get colorValue {
    switch (this) {
      case DensityLevel.low:
        return 0xFF4CAF50; // Green
      case DensityLevel.moderate:
        return 0xFFFFC107; // Amber
      case DensityLevel.high:
        return 0xFFF44336; // Red
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

// JSON conversion functions for LatLng
List<LatLng> _latLngListFromJson(List<dynamic> json) {
  return json
      .map((point) => LatLng(
            point['lat'] as double,
            point['lng'] as double,
          ))
      .toList();
}

List<Map<String, dynamic>> _latLngListToJson(List<LatLng> latLngList) {
  return latLngList
      .map((point) => {
            'lat': point.latitude,
            'lng': point.longitude,
          })
      .toList();
}
