import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/utils/time_formatter.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

class InsightsSummaryCard extends StatelessWidget {
  final TrackingInsights? insights;

  const InsightsSummaryCard({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    // Default values if insights are null
    final miles = insights?.totalMiles.toInt() ?? 0;
    final hours = insights?.hours ?? 0.0;
    final earnings = insights?.totalEarnings ?? 0.0;
    final expenses = insights?.totalExpenses ?? 0.0;
    final sessionCount = insights?.sessionCount ?? 0;

    // Calculate net earnings
    final netEarnings = earnings - expenses;

    // Get formatted time
    final formattedTime = TimeFormatter.formatDurationCompact(
      (hours * 3600).round(),
    );

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
        children: [
          // Top row: Net Earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Earnings',
                style: AppTextStyle.size(14)
                    .regular
                    .withColor(AppColorToken.white..color.withAlpha(70)),
              ),
              4.verticalSpace,
              Text(
                '\$${netEarnings.toStringAsFixed(2)}',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
              ),
            ],
          ),
          16.verticalSpace,

          // Earnings & Expenses row
          Row(
            children: [
              // Earnings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings',
                      style: AppTextStyle.size(12)
                          .regular
                          .withColor(AppColorToken.white..color.withAlpha(70)),
                    ),
                    4.verticalSpace,
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 16,
                        ),
                        6.horizontalSpace,
                        Text(
                          '\$${earnings.toStringAsFixed(2)}',
                          style: AppTextStyle.size(16)
                              .semiBold
                              .withColor(AppColorToken.golden),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expenses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenses',
                      style: AppTextStyle.size(12)
                          .regular
                          .withColor(AppColorToken.white..color.withAlpha(70)),
                    ),
                    4.verticalSpace,
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: Colors.red,
                          size: 16,
                        ),
                        6.horizontalSpace,
                        Text(
                          '\$${expenses.toStringAsFixed(2)}',
                          style: AppTextStyle.size(16)
                              .semiBold
                              .withColor(AppColorToken.golden),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          const Divider(height: 1, color: Colors.white24),
          16.verticalSpace,

          // Bottom row: Grid of 3 stats
          Row(
            children: [
              // Miles
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_car_outlined,
                  value: '$miles',
                  label: 'Miles',
                  suffix: 'mi',
                ),
              ),
              // Hours
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  value: formattedTime,
                  label: 'Hours',
                ),
              ),
              // Trips
              Expanded(
                child: _buildStatItem(
                  icon: Icons.route,
                  value: '$sessionCount',
                  label: 'Trips',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    String? suffix,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorToken.black.value.withAlpha(50),
          ),
          child: Icon(
            icon,
            color: AppColorToken.golden.value,
            size: 24,
          ),
        ),
        8.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyle.size(18).bold.withColor(AppColorToken.white),
            ),
            if (suffix != null) ...[
              4.horizontalSpace,
              Text(
                suffix,
                style: AppTextStyle.size(14)
                    .regular
                    .withColor(AppColorToken.white..color.withAlpha(100)),
              ),
            ],
          ],
        ),
        4.verticalSpace,
        Text(
          label,
          style: AppTextStyle.size(12)
              .regular
              .withColor(AppColorToken.white..color.withAlpha(70)),
        ),
      ],
    );
  }
}
