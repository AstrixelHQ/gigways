import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:latlong2/latlong.dart';

import '../models/density_grid.dart';
import '../models/density_request.dart';

part 'density_repository.g.dart';

@riverpod
DensityRepository densityRepository(Ref ref) {
  return DensityRepository();
}

class DensityRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Calculate driver density for a given location
  Future<DensityResponse> calculateDriverDensity({
    required double lat,
    required double lng,
    int radiusMiles = 15, // Increased for 30-mile total coverage
  }) async {
    try {
      // Configure callable with extended timeout
      final callable = _functions.httpsCallable(
        'calculateDriverDensity',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final request = DensityRequest(
        lat: lat,
        lng: lng,
        radiusMiles: radiusMiles,
      );

      print('DEBUG: Calling Cloud Function with data: ${request.toJson()}');
      final result = await callable.call(request.toJson());
      print('DEBUG: Function response received');

      // Parse the response
      final data = result.data as Map<String, dynamic>;
      log(data.entries.map((e) => '${e.key}: ${e.value}').join(', '));

      final grids = (data['grids'] as List)
          .map<DensityGrid>((gridData) => DensityGrid.fromFirestore(Map<String, dynamic>.from(gridData)))
          .toList();

      return DensityResponse(
        grids: grids,
        cached: data['cached'] ?? false,
        executionTime: data['executionTime'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw DensityException(
        message: e.message ?? 'Failed to calculate driver density',
        code: e.code,
      );
    } catch (e) {
      print(e);
      throw DensityException(
        message: 'Unexpected error: $e',
        code: 'unknown',
      );
    }
  }

  /// Get cached density data for quick access
  Future<List<DensityGrid>?> getCachedDensity({
    required double lat,
    required double lng,
    int radiusMiles = 15, // Increased for consistency
  }) async {
    try {
      // Generate the same cache key used by the Cloud Function
      final cacheKey =
          'density_${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}_$radiusMiles';

      // In a real implementation, you might want to cache this locally
      // For now, we'll rely on the Cloud Function's caching
      return null;
    } catch (e) {
      // If caching fails, return null to force fresh fetch
      return null;
    }
  }

  /// Validate if coordinates are within US boundaries
  bool isValidUSLocation(double lat, double lng) {
    // Continental US boundaries (approximate)
    const double minLat = 24.0;
    const double maxLat = 49.0;
    const double minLng = -125.0;
    const double maxLng = -66.0;

    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth radius in meters

    final double lat1Rad = point1.latitudeInRad;
    final double lat2Rad = point2.latitudeInRad;
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (3.14159 / 180);
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Convert meters to miles
  double metersToMiles(double meters) {
    return meters * 0.000621371;
  }

  /// Convert miles to meters
  double milesToMeters(double miles) {
    return miles * 1609.34;
  }
}

class DensityException implements Exception {
  final String message;
  final String code;

  const DensityException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'DensityException($code): $message';
}
