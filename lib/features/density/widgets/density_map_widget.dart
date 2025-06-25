import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:latlong2/latlong.dart';

import '../models/density_grid.dart';
import '../notifiers/density_notifier.dart';
import 'density_bottom_sheet.dart';

class DensityMapWidget extends StatefulWidget {
  final DensityState densityState;
  final bool isLocationLoading;
  final bool centerOnGrids;

  const DensityMapWidget({
    super.key,
    required this.densityState,
    required this.isLocationLoading,
    this.centerOnGrids = false,
  });

  @override
  State<DensityMapWidget> createState() => _DensityMapWidgetState();
}

class _DensityMapWidgetState extends State<DensityMapWidget> {
  final MapController _mapController = MapController();
  final LayerHitNotifier<DensityGrid> _polygonHitNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    // Listen to polygon hit events
    _polygonHitNotifier.addListener(_onPolygonHit);
    print('DEBUG: LayerHitNotifier listener added');
  }

  @override
  void dispose() {
    _polygonHitNotifier.removeListener(_onPolygonHit);
    _polygonHitNotifier.dispose();
    super.dispose();
  }

  void _onPolygonHit() {
    final LayerHitResult<DensityGrid>? hitResult = _polygonHitNotifier.value;
    if (hitResult != null && hitResult.hitValues.isNotEmpty) {
      print(
          'DEBUG: Polygon hit detected with ${hitResult.hitValues.length} grids');
      _showGridDetails(hitResult.hitValues.first);
    }
  }

  @override
  void didUpdateWidget(DensityMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If new grids are loaded, center the map on them
    if (widget.densityState.grids.isNotEmpty &&
        oldWidget.densityState.grids.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnGrids();
      });
    }
  }

  void _centerMapOnGrids() {
    if (widget.densityState.grids.isEmpty) return;

    // Calculate center of all grids
    double totalLat = 0;
    double totalLng = 0;
    int pointCount = 0;

    for (final grid in widget.densityState.grids) {
      for (final point in grid.hexagonBounds) {
        totalLat += point.latitude;
        totalLng += point.longitude;
        pointCount++;
      }
    }

    final center = LatLng(totalLat / pointCount, totalLng / pointCount);
    print('DEBUG: Moving map to center: $center');

    _mapController.move(center, 11.0);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate center from density grids if available, otherwise use current location
    LatLng center;
    if (widget.densityState.grids.isNotEmpty) {
      // Calculate center of all grids
      double totalLat = 0;
      double totalLng = 0;
      int pointCount = 0;

      for (final grid in widget.densityState.grids) {
        for (final point in grid.hexagonBounds) {
          totalLat += point.latitude;
          totalLng += point.longitude;
          pointCount++;
        }
      }

      center = LatLng(totalLat / pointCount, totalLng / pointCount);
      print('DEBUG: Calculated map center from grids: $center');
    } else {
      center = widget.densityState.currentLocation ??
          const LatLng(37.7749, -122.4194);
      print('DEBUG: Using default/current location center: $center');
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            print('DEBUG: Map tap detected, checking hit notifier...');
            final LayerHitResult<DensityGrid>? hitResult =
                _polygonHitNotifier.value;
            print(
                'DEBUG: Hit result: ${hitResult?.hitValues.length ?? 0} values');
            if (hitResult != null && hitResult.hitValues.isNotEmpty) {
              print(
                  'DEBUG: Showing grid details for ${hitResult.hitValues.first.gridId}');
              _showGridDetails(hitResult.hitValues.first);
            } else {
              print('DEBUG: No hit result or empty hit values');
            }
          },
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 11.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gigways.app',
                maxNativeZoom: 11,
              ),

              // Density Grid Polygons
              if (widget.densityState.grids.isNotEmpty) ...[
                PolygonLayer<DensityGrid>(
                  hitNotifier: _polygonHitNotifier,
                  polygons: widget.densityState.grids.map((grid) {
                    print('DEBUG: Creating polygon for grid ${grid.gridId}');
                    return _createGridPolygon(grid);
                  }).toList(),
                  polygonCulling: true,
                  simplificationTolerance: 0.0,
                  drawLabelsLast: true,
                ),
              ] else
                Container(), // Empty container when no grids

              // Current Location Marker
              if (widget.densityState.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.densityState.currentLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColorToken.darkGrey.value,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColorToken.black.value.withAlpha(50),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Loading Overlay
        if (widget.isLocationLoading || widget.densityState.isLoading)
          Container(
            color: AppColorToken.black.value.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading density data...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Error Display
        if (widget.densityState.error != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.densityState.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Legend
        if (widget.densityState.grids.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Density Levels',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(DensityLevel.high),
                    _buildLegendItem(DensityLevel.moderate),
                    _buildLegendItem(DensityLevel.low),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Polygon<DensityGrid> _createGridPolygon(DensityGrid grid) {
    final color = Color(grid.level.colorValue);
    print('DEBUG: Creating polygon for grid ${grid.gridId} with hit value');
    print('DEBUG: Grid bounds: ${grid.hexagonBounds.length} points');

    return Polygon<DensityGrid>(
      points: grid.hexagonBounds,
      hitValue: grid, // Set the grid as the hit value for tap detection
      color: color.withAlpha(
        (grid.level.opacity * 255).toInt(),
      ),
      borderColor: color,
      borderStrokeWidth: 4.0,
      pattern: StrokePattern.dotted(
        patternFit: PatternFit.extendFinalDash,
        spacingFactor: 0.5,
      ),
      rotateLabel: true,
      label: '${grid.estimatedDrivers}',
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(DensityLevel level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(level.colorValue).withOpacity(level.opacity),
              border: Border.all(color: Color(level.colorValue)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            level.displayName,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showGridDetails(DensityGrid grid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DensityBottomSheet(grid: grid),
    );
  }
}
