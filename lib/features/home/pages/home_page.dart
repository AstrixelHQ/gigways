import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/home/widgets/animated_tracker_card.dart';
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
    final trackingNotifier = ref.read(trackingNotifierProvider.notifier);

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
                ),
                24.verticalSpace,

                // My Insights Section - Modified to be clickable and navigate to Insights page
                _buildInsightsSection(context, trackingState, trackingNotifier),
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
      hours: session.durationInSeconds / 3600, // Convert seconds to hours
      miles: session.miles.round(),
      startTime: session.startTime,
      endTime: session.endTime,
      earnings: session.earnings,
      expenses: session.expenses,
    );
  }

  // Modified Insights Section with navigation to the Insights page
  Widget _buildInsightsSection(BuildContext context,
      TrackingState trackingState, TrackingNotifier trackingNotifier) {
    final insights = trackingState.selectedInsights;
    final selectedPeriod = trackingState.selectedInsightPeriod;

    // Default values if insights are not available
    final miles = insights?.totalMiles.round() ?? 0;
    final hours = insights?.hours.toStringAsFixed(1) ?? '0.0';
    final earnings = insights?.totalEarnings ?? 0.0;
    final expenses = insights?.totalExpenses ?? 0.0;

    return GestureDetector(
      onTap: () => InsightsRoute().push(context), // Navigate to insights page
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter and arrow to indicate navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Insights',
                  style: AppTextStyle.size(18)
                      .bold
                      .withColor(AppColorToken.golden),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColorToken.black.value,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColorToken.golden.value.withAlpha(30),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColorToken.golden.value,
                          ),
                          style: AppTextStyle.size(14)
                              .medium
                              .withColor(AppColorToken.white),
                          dropdownColor: AppColorToken.black.value,
                          isDense: true,
                          items: ['Today', 'Weekly', 'Monthly', 'Yearly']
                              .map((String period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              trackingNotifier.setInsightPeriod(value);
                            }
                          },
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    // Add arrow icon to indicate navigation
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColorToken.golden.value,
                    ),
                  ],
                ),
              ],
            ),
            16.verticalSpace,

            // Insights grid - 2 rows, 2 columns
            Row(
              children: [
                // Miles
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.directions_car,
                    title: 'Miles',
                    value: '$miles',
                    suffix: 'mi',
                  ),
                ),
                8.horizontalSpace,
                // Hours
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.access_time_filled,
                    title: 'Hours',
                    value: hours,
                    suffix: 'hrs',
                  ),
                ),
              ],
            ),
            8.verticalSpace,
            Row(
              children: [
                // Earnings
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    value: '\$${earnings.toStringAsFixed(2)}',
                    valueColor: AppColorToken.success.value,
                  ),
                ),
                8.horizontalSpace,
                // Expenses
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.receipt_long,
                    title: 'Expenses',
                    value: '\$${expenses.toStringAsFixed(2)}',
                    valueColor: AppColorToken.error.value,
                  ),
                ),
              ],
            ),

            // Add "See all insights" button/text
            16.verticalSpace,
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all insights',
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                    6.horizontalSpace,
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColorToken.golden.value,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    String? suffix,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColorToken.golden.value,
                size: 16,
              ),
              8.horizontalSpace,
              Text(
                title,
                style: AppTextStyle.size(12)
                    .medium
                    .withColor(AppColorToken.white..color.withAlpha(70)),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              Text(
                value,
                style: AppTextStyle.size(18).bold.withColor(
                      valueColor != null
                          ? valueColor.toToken()
                          : AppColorToken.white,
                    ),
              ),
              if (suffix != null) ...[
                4.horizontalSpace,
                Text(
                  suffix,
                  style: AppTextStyle.size(12)
                      .medium
                      .withColor(AppColorToken.white..color.withAlpha(70)),
                ),
              ],
            ],
          ),
        ],
      ),
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
