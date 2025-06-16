import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/driver_density/models/density_models.dart';
import 'package:gigways/features/driver_density/widgets/density_grid_overlay.dart';
import 'package:gigways/features/driver_density/widgets/density_stats_card.dart';
import 'package:gigways/features/driver_density/widgets/forecast_selector.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

class DriverDensityPage extends HookConsumerWidget {
  const DriverDensityPage({super.key});

  static const String path = '/density';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useMemoized(() => MapController());
    final selectedForecast = useState(ForecastPeriod.fifteenMinutes);

    // Mock user location (San Francisco)
    final userLocation = const LatLng(37.7749, -122.4194);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Density',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColorToken.black.value,
        foregroundColor: AppColorToken.white.value,
        elevation: 0,
      ),
      backgroundColor: AppColorToken.black.value,
      body: Column(
        children: [
          // Stats Card
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: DensityStatsCard(
          //     stats: DensityStats(
          //       cityDrivers: 1200,
          //       stateDrivers: 15000,
          //       nationalDrivers: 250000,
          //       cityName: 'San Francisco',
          //       stateName: 'California',
          //       lastUpdated: DateTime.now(),
          //     ),
          //   ),
          // ),

          // Forecast Selector
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: ForecastSelector(
          //     selectedPeriod: selectedForecast.value,
          //     onPeriodChanged: (period) {
          //       selectedForecast.value = period;
          //     },
          //   ),
          // ),

          const SizedBox(height: 16),

          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorToken.golden.value.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: userLocation,
                    initialZoom: 12.0,
                    minZoom: 8.0,
                    maxZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Base tile layer
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gigways.app',
                    ),

                    // Density grid overlay
                    DensityGridOverlay(
                      userLocation: userLocation,
                      selectedForecast: selectedForecast.value,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColorToken.white.value.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Low', Colors.green, 'Good opportunity'),
                _buildLegendItem('Moderate', Colors.orange, 'Average density'),
                _buildLegendItem('High', Colors.red, 'Saturated area'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String description) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColorToken.white.value,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            color: AppColorToken.white.value.withOpacity(0.7),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
