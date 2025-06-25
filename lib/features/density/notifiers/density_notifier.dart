import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

import '../models/density_grid.dart';
import '../models/density_request.dart';
import '../repositories/density_repository.dart';

part 'density_notifier.freezed.dart';
part 'density_notifier.g.dart';

@freezed
sealed class DensityState with _$DensityState {
  const factory DensityState({
    @Default([]) List<DensityGrid> grids,
    @Default(false) bool isLoading,
    @Default(false) bool isCached,
    String? error,
    LatLng? currentLocation,
    @Default(5) int radiusMiles,
    int? executionTime,
    DateTime? lastUpdated,
  }) = _DensityState;
}

@riverpod
class DensityNotifier extends _$DensityNotifier {
  @override
  DensityState build() {
    return const DensityState();
  }

  /// Load driver density data for the given location
  Future<void> loadDensityData({
    required double lat,
    required double lng,
    int radiusMiles = 5,
  }) async {
    final repository = ref.read(densityRepositoryProvider);
    
    // Validate US location
    if (!repository.isValidUSLocation(lat, lng)) {
      state = state.copyWith(
        error: 'Location must be within the United States',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentLocation: LatLng(lat, lng),
      radiusMiles: radiusMiles,
    );

    try {
      final response = await repository.calculateDriverDensity(
        lat: lat,
        lng: lng,
        radiusMiles: radiusMiles,
      );

      state = state.copyWith(
        grids: response.grids,
        isLoading: false,
        isCached: response.cached,
        executionTime: response.executionTime,
        lastUpdated: DateTime.now(),
        error: null,
      );
    } on DensityException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        grids: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load density data: $e',
        grids: [],
      );
    }
  }

  /// Refresh density data for current location
  Future<void> refreshDensityData() async {
    final currentLocation = state.currentLocation;
    if (currentLocation == null) return;

    await loadDensityData(
      lat: currentLocation.latitude,
      lng: currentLocation.longitude,
      radiusMiles: state.radiusMiles,
    );
  }

  /// Update radius and reload data
  Future<void> updateRadius(int newRadius) async {
    final currentLocation = state.currentLocation;
    if (currentLocation == null) return;

    await loadDensityData(
      lat: currentLocation.latitude,
      lng: currentLocation.longitude,
      radiusMiles: newRadius,
    );
  }

  /// Clear all density data
  void clearData() {
    state = const DensityState();
  }

  /// Get grid by ID
  DensityGrid? getGridById(String gridId) {
    try {
      return state.grids.firstWhere((grid) => grid.gridId == gridId);
    } catch (e) {
      return null;
    }
  }

  /// Get grids by density level
  List<DensityGrid> getGridsByLevel(DensityLevel level) {
    return state.grids.where((grid) => grid.level == level).toList();
  }

  /// Get summary statistics
  DensitySummary getSummary() {
    if (state.grids.isEmpty) {
      return const DensitySummary(
        totalGrids: 0,
        totalPopulation: 0,
        totalEstimatedDrivers: 0,
        lowDensityGrids: 0,
        moderateDensityGrids: 0,
        highDensityGrids: 0,
      );
    }

    final totalPopulation = state.grids.fold<int>(
      0,
      (sum, grid) => sum + grid.population,
    );

    final totalEstimatedDrivers = state.grids.fold<int>(
      0,
      (sum, grid) => sum + grid.estimatedDrivers,
    );

    final levelCounts = <DensityLevel, int>{
      DensityLevel.low: 0,
      DensityLevel.moderate: 0,
      DensityLevel.high: 0,
    };

    for (final grid in state.grids) {
      levelCounts[grid.level] = (levelCounts[grid.level] ?? 0) + 1;
    }

    return DensitySummary(
      totalGrids: state.grids.length,
      totalPopulation: totalPopulation,
      totalEstimatedDrivers: totalEstimatedDrivers,
      lowDensityGrids: levelCounts[DensityLevel.low] ?? 0,
      moderateDensityGrids: levelCounts[DensityLevel.moderate] ?? 0,
      highDensityGrids: levelCounts[DensityLevel.high] ?? 0,
    );
  }
}

@freezed
sealed class DensitySummary with _$DensitySummary {
  const factory DensitySummary({
    required int totalGrids,
    required int totalPopulation,
    required int totalEstimatedDrivers,
    required int lowDensityGrids,
    required int moderateDensityGrids,
    required int highDensityGrids,
  }) = _DensitySummary;

  const DensitySummary._();

  double get averageDriversPerGrid => totalGrids > 0 ? totalEstimatedDrivers / totalGrids : 0;
  
  double get driverPercentage => totalPopulation > 0 ? (totalEstimatedDrivers / totalPopulation) * 100 : 0;
}