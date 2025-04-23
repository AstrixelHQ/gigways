import 'package:gigways/core/services/driving_detection_service.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tracker_controller.g.dart';

@Riverpod(keepAlive: true)
class TrackerController extends _$TrackerController {
  @override
  void build() {
    // This doesn't need state, it's just a controller
    return;
  }

  // Start tracking manually
  Future<void> startTracking() async {
    // Disable driving detection notifications while tracking is active
    DrivingDetectionService().setDetectionEnabled(false);

    // Start actual tracking
    await ref.read(trackingNotifierProvider.notifier).startTracking();
  }

  // Stop tracking manually
  Future<void> stopTracking() async {
    // Stop tracking
    await ref.read(trackingNotifierProvider.notifier).stopTracking();

    // Re-enable driving detection after tracking stops
    DrivingDetectionService().setDetectionEnabled(true);
  }

  // End shift with earnings
  Future<void> endShift({double? earnings, double? expenses}) async {
    await ref.read(trackingNotifierProvider.notifier).endShift(
          earnings: earnings,
          expenses: expenses,
        );

    // Re-enable driving detection
    DrivingDetectionService().setDetectionEnabled(true);
  }
}
