import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:location/location.dart';

import '../notifiers/density_notifier.dart';
import '../widgets/density_map_widget.dart';
import '../widgets/density_info_widget.dart';

class DensityPage extends HookConsumerWidget {
  static const String path = '/density';
  static const String name = 'DensityPage';

  const DensityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final densityState = ref.watch(densityNotifierProvider);
    final densityNotifier = ref.read(densityNotifierProvider.notifier);
    final locationController = useMemoized(() => Location());
    final isLocationLoading = useState<bool>(false);
    final _centerMapOnGrids = useState<bool>(false);

    // Auto-load user location on first load
    useEffect(() {
      _loadUserLocation(locationController, densityNotifier, isLocationLoading);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Density'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _refreshLocation(
                locationController, densityNotifier, isLocationLoading),
            icon: Icon(
              Icons.my_location,
              color: AppColorToken.golden.value,
            ),
            tooltip: 'Use My Location',
          ),
          IconButton(
            onPressed: () => densityNotifier.refreshDensityData(),
            icon: Icon(
              Icons.refresh,
              color: AppColorToken.golden.value,
            ),
            tooltip: 'Refresh Data',
          ),
          if (densityState.grids.isNotEmpty)
            IconButton(
              onPressed: () => _centerMapOnGrids.value = !_centerMapOnGrids.value,
              icon: Icon(
                Icons.center_focus_strong,
                color: AppColorToken.golden.value,
              ),
              tooltip: 'Center on Grids',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info Panel
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: DensityInfoWidget(
              densityState: densityState,
              isLocationLoading: isLocationLoading.value,
            ),
          ),

          // Map Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: DensityMapWidget(
                densityState: densityState,
                isLocationLoading: isLocationLoading.value,
                centerOnGrids: _centerMapOnGrids.value,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _loadUserLocation(
    Location locationController,
    DensityNotifier densityNotifier,
    ValueNotifier<bool> isLocationLoading,
  ) async {
    if (isLocationLoading.value) return;

    isLocationLoading.value = true;
    try {
      // Check if location service is enabled
      bool serviceEnabled = await locationController.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationController.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      // Check permissions
      PermissionStatus permissionGranted =
          await locationController.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await locationController.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      // Get current location
      final locationData = await locationController.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        await densityNotifier.loadDensityData(
          lat: locationData.latitude!,
          lng: locationData.longitude!,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Load default location (San Francisco) if location fails
      await densityNotifier.loadDensityData(
        lat: 37.7749,
        lng: -122.4194,
      );
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> _refreshLocation(
    Location locationController,
    DensityNotifier densityNotifier,
    ValueNotifier<bool> isLocationLoading,
  ) async {
    await _loadUserLocation(
        locationController, densityNotifier, isLocationLoading);
  }
}
