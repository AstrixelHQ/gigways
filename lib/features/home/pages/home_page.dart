import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/home/widgets/animated_tracker_card.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const String path = '/home';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isTrackerEnabled = false;
  String selectedInsightPeriod = 'Today';
  final List<String> insightPeriods = ['Today', 'Weekly', 'Monthly', 'Yearly'];
  TrackerData trackerData = TrackerData(
    hours: 0.0,
    miles: 0,
  );

  // Mock data for insights
  final Map<String, Map<String, dynamic>> insightsData = {
    'Today': {
      'miles': 30,
      'hours': 1.0,
      'earnings': 25.50,
      'expenses': 5.75,
    },
    'Weekly': {
      'miles': 210,
      'hours': 38.5,
      'earnings': 750.80,
      'expenses': 120.45,
    },
    'Monthly': {
      'miles': 850,
      'hours': 160.0,
      'earnings': 3250.45,
      'expenses': 485.75,
    },
    'Yearly': {
      'miles': 10500,
      'hours': 1920.0,
      'earnings': 38500.75,
      'expenses': 5840.25,
    },
  };

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(authNotifierProvider).userData;
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
                  drivingNow: 4000,
                  totalDrivers: 70000,
                  onTrackerToggled: _handleTrackerToggle,
                  onShiftEnded: _handleShiftEnded,
                ),
                24.verticalSpace,

                // My Insights Section
                _buildInsightsSection(),
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

  void _handleTrackerToggle(bool enabled) {
    setState(() {
      isTrackerEnabled = enabled;

      // If starting the tracker, initialize shift data
      if (enabled) {
        trackerData = TrackerData(
          hours: 0.0,
          miles: 0,
          startTime: DateTime.now(),
        );

        // Start a timer to update tracker data in a real app
        _simulateTracking();
      } else {
        // When ending shift, update end time
        trackerData = trackerData.copyWith(
          endTime: DateTime.now(),
        );
      }
    });
  }

  // This would be replaced with real tracking logic in a production app
  void _simulateTracking() {
    if (isTrackerEnabled) {
      // In a real app, you'd use a proper timer or stream
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && isTrackerEnabled) {
          setState(() {
            // Simulate progress
            trackerData = TrackerData(
              hours: 1.5,
              miles: 30,
              startTime: trackerData.startTime,
            );
          });
        }
      });
    }
  }

  void _handleShiftEnded(double earnings, double expenses) {
    // In a real app, you would save this to a database
    print('Shift ended with earnings: \$$earnings and expenses: \$$expenses');

    // Update insights data with new earnings and expenses
    setState(() {
      final currentData = insightsData[selectedInsightPeriod]!;
      currentData['earnings'] = (currentData['earnings'] as double) + earnings;
      currentData['expenses'] = (currentData['expenses'] as double) + expenses;

      // Reset tracker data
      trackerData = TrackerData(
        hours: 0.0,
        miles: 0,
      );
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shift data saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInsightsSection() {
    final currentData = insightsData[selectedInsightPeriod]!;

    return Container(
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
          // Header with filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Insights',
                style:
                    AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(30),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedInsightPeriod,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppColorToken.golden.value,
                    ),
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                    dropdownColor: AppColorToken.black.value,
                    isDense: true,
                    items: insightPeriods.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          selectedInsightPeriod = value;
                        });
                      }
                    },
                  ),
                ),
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
                  value: '${currentData['miles']}',
                  suffix: 'mi',
                ),
              ),
              8.horizontalSpace,
              // Hours
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.access_time_filled,
                  title: 'Hours',
                  value: '${currentData['hours'].toStringAsFixed(1)}',
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
                  value: '\$${currentData['earnings'].toStringAsFixed(2)}',
                  valueColor: AppColorToken.success.value,
                ),
              ),
              8.horizontalSpace,
              // Expenses
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.receipt_long,
                  title: 'Expenses',
                  value: '\$${currentData['expenses'].toStringAsFixed(2)}',
                  valueColor: AppColorToken.error.value,
                ),
              ),
            ],
          ),
        ],
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
