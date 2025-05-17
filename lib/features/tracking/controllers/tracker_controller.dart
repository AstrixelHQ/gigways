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
    ref.read(drivingDetectionServiceProvider).setDetectionEnabled(false);

    // Start actual tracking
    await ref.read(trackingNotifierProvider.notifier).startTracking();
  }

  // Stop tracking manually
  Future<void> stopTracking() async {
    // Stop tracking
    await ref.read(trackingNotifierProvider.notifier).stopTracking();

    // Re-enable driving detection after tracking stops
    ref.read(drivingDetectionServiceProvider).setDetectionEnabled(true);
  }

  // End shift with earnings
  Future<void> endShift({double? earnings, double? expenses}) async {
    await ref.read(trackingNotifierProvider.notifier).endShift(
          earnings: earnings,
          expenses: expenses,
        );

    // Re-enable driving detection
    ref.read(drivingDetectionServiceProvider).setDetectionEnabled(true);
  }

  // Handle notification actions
  void handleNotificationAction(String? payload, String actionId) async {
    if (payload == 'inactivity_detected' && actionId == 'stop') {
      // If user presses "End Tracking" on the inactivity notification
      await stopTracking();
    }
    // Other actions can be added here
  }
}
