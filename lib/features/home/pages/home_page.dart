import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
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

  // Mock data for example purposes
  final DateTime shiftStartTime =
      DateTime.now().subtract(const Duration(hours: 1));
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
                          'John Doe',
                          style: AppTextStyle.size(24)
                              .bold
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorToken.golden.value,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: AppColorToken.golden.value,
                        ),
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,

                // Tracker Status Card
                _buildTrackerStatusCard(),
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

  Widget _buildTrackerStatusCard() {
    final currentData = insightsData[selectedInsightPeriod]!;

    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isTrackerEnabled
                  ? AppColorToken.golden.value
                  : Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isTrackerEnabled ? Icons.location_on : Icons.location_off,
                      color: isTrackerEnabled
                          ? AppColorToken.black.value
                          : AppColorToken.white.value,
                      size: 20,
                    ),
                    8.horizontalSpace,
                    Text(
                      isTrackerEnabled ? 'Tracker Active' : 'Tracker Inactive',
                      style: AppTextStyle.size(16).medium.withColor(
                            isTrackerEnabled
                                ? AppColorToken.black
                                : AppColorToken.white,
                          ),
                    ),
                  ],
                ),
                Switch(
                  value: isTrackerEnabled,
                  onChanged: (value) {
                    setState(() {
                      isTrackerEnabled = value;
                    });
                  },
                  activeColor: AppColorToken.black.value,
                  inactiveThumbColor: AppColorToken.white.value,
                  activeTrackColor: AppColorToken.black.value.withAlpha(150),
                  inactiveTrackColor: AppColorToken.white.value.withAlpha(50),
                )
              ],
            ),
          ),

          // Tracker Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status message
                Text(
                  isTrackerEnabled
                      ? 'End Shift: Turn off Tracker!'
                      : 'Start tracking your hours and miles',
                  style: AppTextStyle.size(16).bold.withColor(isTrackerEnabled
                      ? AppColorToken.golden
                      : AppColorToken.white),
                ),
                16.verticalSpace,

                // Hours and miles
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: AppColorToken.golden.value,
                      size: 20,
                    ),
                    8.horizontalSpace,
                    Text(
                      '${currentData['hours'].toStringAsFixed(2)} hr',
                      style: AppTextStyle.size(16)
                          .medium
                          .withColor(AppColorToken.white),
                    ),
                    24.horizontalSpace,
                    Icon(
                      Icons.directions_car,
                      color: AppColorToken.golden.value,
                      size: 20,
                    ),
                    8.horizontalSpace,
                    Text(
                      '${currentData['miles']} mi',
                      style: AppTextStyle.size(16)
                          .medium
                          .withColor(AppColorToken.white),
                    ),
                  ],
                ),
                16.verticalSpace,

                // Start and end time
                if (isTrackerEnabled)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeCard(
                          label: 'Started',
                          time: shiftStartTime,
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: _buildTimeCard(
                          label: 'Est. End',
                          time: shiftStartTime.add(const Duration(hours: 8)),
                        ),
                      ),
                    ],
                  ),

                // CTA Button for tracking
                if (!isTrackerEnabled) ...[
                  16.verticalSpace,
                  AppButton(
                    text: 'Start Tracking',
                    onPressed: () {
                      setState(() {
                        isTrackerEnabled = true;
                      });
                    },
                  ),
                ],

                16.verticalSpace,

                // Status line
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColorToken.golden.value.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Georgia:',
                        style: AppTextStyle.size(14)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyle.size(14)
                              .medium
                              .withColor(AppColorToken.white),
                          children: [
                            TextSpan(
                              text: '4,000',
                              style: TextStyle(
                                color: AppColorToken.golden.value,
                              ),
                            ),
                            const TextSpan(text: ' / '),
                            const TextSpan(text: '70,000'),
                            const TextSpan(text: ' driving right now!'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({required String label, required DateTime time}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.size(12)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(70)),
          ),
          4.verticalSpace,
          Text(
            DateFormat('h:mm a').format(time),
            style: AppTextStyle.size(16).bold.withColor(AppColorToken.white),
          ),
        ],
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
