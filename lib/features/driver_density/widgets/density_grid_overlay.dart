import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gigways/features/driver_density/models/density_models.dart';
import 'package:gigways/features/driver_density/widgets/grid_detail_sheet.dart';
import 'package:latlong2/latlong.dart';

class DensityGridOverlay extends StatelessWidget {
  const DensityGridOverlay({
    super.key,
    required this.userLocation,
    required this.selectedForecast,
  });

  final LatLng userLocation;
  final ForecastPeriod selectedForecast;

  @override
  Widget build(BuildContext context) {
    final grids = _generateMockGrids();

    return GestureDetector(
      onTapDown: (details) {
        // For now, just show the first grid details as an example
        // In a real implementation, we'd convert tap position to coordinates
        if (grids.isNotEmpty) {
          _showGridDetails(context, grids.first);
        }
      },
      child: PolygonLayer(
        polygons:
            grids.map((grid) => _buildGridPolygon(context, grid)).toList(),
      ),
    );
  }

  Polygon _buildGridPolygon(BuildContext context, DensityGrid grid) {
    Color color;
    switch (grid.level) {
      case DensityLevel.low:
        color = Colors.green;
        break;
      case DensityLevel.moderate:
        color = Colors.orange;
        break;
      case DensityLevel.high:
        color = Colors.red;
        break;
    }

    return Polygon(
      points: [
        grid.topLeft,
        LatLng(grid.topLeft.latitude, grid.bottomRight.longitude),
        grid.bottomRight,
        LatLng(grid.bottomRight.latitude, grid.topLeft.longitude),
      ],
      color: color.withValues(alpha: grid.level.opacity),
      borderColor: color,
      borderStrokeWidth: 2.0,
    );
  }

  void _showGridDetails(BuildContext context, DensityGrid grid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GridDetailSheet(
        grid: grid,
        selectedForecast: selectedForecast,
      ),
    );
  }

  List<DensityGrid> _generateMockGrids() {
    final List<DensityGrid> grids = [];
    final gridSize = 0.02; // ~2.2 km grid size

    // Generate 5x5 grid around user location
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        final centerLat = userLocation.latitude + (i * gridSize);
        final centerLng = userLocation.longitude + (j * gridSize);
        final center = LatLng(centerLat, centerLng);

        final topLeft = LatLng(
          centerLat + gridSize / 2,
          centerLng - gridSize / 2,
        );
        final bottomRight = LatLng(
          centerLat - gridSize / 2,
          centerLng + gridSize / 2,
        );

        // Mock driver count based on distance from user
        final distance =
            const Distance().as(LengthUnit.Kilometer, userLocation, center);
        int driverCount;
        DensityLevel level;

        if (distance < 5) {
          driverCount = 15 + (i * j).abs() * 3;
          level = DensityLevel.high;
        } else if (distance < 10) {
          driverCount = 8 + (i * j).abs() * 2;
          level = DensityLevel.moderate;
        } else {
          driverCount = 3 + (i * j).abs();
          level = DensityLevel.low;
        }

        grids.add(DensityGrid(
          id: 'grid_${i}_$j',
          center: center,
          topLeft: topLeft,
          bottomRight: bottomRight,
          driverCount: driverCount,
          level: level,
          lastUpdated: DateTime.now().subtract(
            Duration(minutes: (i.abs() + j.abs()) * 2),
          ),
        ));
      }
    }

    return grids;
  }

  DensityGrid? _findGridAtPoint(LatLng point, List<DensityGrid> grids) {
    for (final grid in grids) {
      if (_isPointInGrid(point, grid)) {
        return grid;
      }
    }
    return null;
  }

  bool _isPointInGrid(LatLng point, DensityGrid grid) {
    return point.latitude <= grid.topLeft.latitude &&
        point.latitude >= grid.bottomRight.latitude &&
        point.longitude >= grid.topLeft.longitude &&
        point.longitude <= grid.bottomRight.longitude;
  }
}
