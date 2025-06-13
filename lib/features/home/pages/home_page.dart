import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/home/widgets/animated_tracker_card.dart';
import 'package:gigways/features/home/widgets/insight_section.dart';
import 'package:gigways/features/tracking/controllers/tracker_controller.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:gigways/routers/app_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String path = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(authNotifierProvider).userData;
    final trackingState = ref.watch(trackingNotifierProvider);

    // Active tracking session
    final activeSession = trackingState.activeSession;
    final isTrackerEnabled = trackingState.status == TrackingStatus.active;

    // Create tracker data from session
    final trackerData = _buildTrackerData(activeSession);

    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.verticalSpace,

                // Header with Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(70)),
                        ),
                        4.verticalSpace,
                        Text(
                          userData?.fullName ?? 'User',
                          style: AppTextStyle.size(24)
                              .bold
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => UpdateProfileRoute().push(context),
                      child: GradientAvatar(
                        name: userData?.fullName ?? 'User',
                        imageUrl: userData?.profileImageUrl,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,

                // Tracker Card
                TrackerCard(
                  isTrackerEnabled: isTrackerEnabled,
                  trackerData: trackerData,
                  drivingNow: trackingState.drivingNow,
                  totalDrivers: trackingState.totalDrivers,
                  onTrackerToggled: (enabled) {
                    if (enabled) {
                      ref
                          .read(trackerControllerProvider.notifier)
                          .startTracking();
                    } else {
                      ref
                          .read(trackerControllerProvider.notifier)
                          .stopTracking();
                    }
                  },
                  onShiftEnded: (earnings, expenses) {
                    ref.read(trackerControllerProvider.notifier).endShift(
                          earnings: earnings,
                          expenses: expenses,
                        );
                  },
                  onForceEndShift: () {
                    ref.read(trackerControllerProvider.notifier).forceEndShift();
                  },
                ),
                24.verticalSpace,

                InsightSection(),
                24.verticalSpace,

                // News and Ads Section
                _buildNewsAndAdsSection(),
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Convert TrackingSession to TrackerData
  TrackerData _buildTrackerData(TrackingSession? session) {
    if (session == null) {
      return TrackerData(
        hours: 0.0,
        miles: 0,
      );
    }

    return TrackerData(
      hours: session.durationInSeconds / 3600,
      miles: session.miles.round(),
      startTime: session.startTime,
      endTime: session.endTime,
      earnings: session.earnings,
      expenses: session.expenses,
    );
  }

  Widget _buildNewsAndAdsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'News & Updates',
          style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
        ),
        16.verticalSpace,
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColorToken.black.value.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColorToken.golden.value.withAlpha(30),
            ),
          ),
          child: Stack(
            children: [
              // You could use an actual image here
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: AppColorToken.black.value.withAlpha(120),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorToken.black.value,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SPONSORED',
                        style: AppTextStyle.size(10).bold.withColor(
                            AppColorToken.white..color.withAlpha(70)),
                      ),
                    ),
                    const Spacer(),

                    // Ad content
                    Text(
                      'Maximize Your Earnings',
                      style: AppTextStyle.size(20)
                          .bold
                          .withColor(AppColorToken.white),
                    ),
                    8.verticalSpace,
                    Text(
                      'Learn how to optimize your routes and increase your hourly pay.',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                    16.verticalSpace,

                    // CTA button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorToken.golden.value,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Learn More',
                        style: AppTextStyle.size(14)
                            .medium
                            .withColor(AppColorToken.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
