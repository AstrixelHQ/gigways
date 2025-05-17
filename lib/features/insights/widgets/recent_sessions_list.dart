import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/utils/time_formatter.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:intl/intl.dart';

class RecentSessionsList extends StatelessWidget {
  final List<TrackingSession> sessions;

  const RecentSessionsList({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // If there are no sessions, show a placeholder
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...sessions.map((session) => _buildSessionCard(session)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.route_outlined,
            size: 48,
            color: AppColorToken.white.value.withAlpha(100),
          ),
          16.verticalSpace,
          Text(
            'No recent sessions',
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
          8.verticalSpace,
          Text(
            'Start tracking your trips to see them here',
            style: AppTextStyle.size(14).regular.withColor(
                  AppColorToken.white..color.withAlpha(70),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrackingSession session) {
    final startTime = DateFormat('h:mm a').format(session.startTime);
    final endTime = session.endTime != null
        ? DateFormat('h:mm a').format(session.endTime!)
        : 'In Progress';
    
    final durationText = session.durationInSeconds > 0
        ? TimeFormatter.formatDurationCompact(session.durationInSeconds)
        : 'In Progress';
        
    final earnings = session.earnings ?? 0.0;
    final expenses = session.expenses ?? 0.0;
    final netEarnings = earnings - expenses;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with time and earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time range
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColorToken.golden.value,
                    size: 16,
                  ),
                  8.horizontalSpace,
                  Text(
                    '$startTime - $endTime',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                ],
              ),
              // Earnings
              Text(
                '\$${netEarnings.toStringAsFixed(2)}',
                style: AppTextStyle.size(16)
                    .bold
                    .withColor(AppColorToken.golden),
              ),
            ],
          ),
          12.verticalSpace,
          
          // Stats row
          Row(
            children: [
              // Duration
              _buildStatChip(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: durationText,
              ),
              12.horizontalSpace,
              // Miles
              _buildStatChip(
                icon: Icons.directions_car_outlined,
                label: 'Miles',
                value: '${session.miles.round()} mi',
              ),
              const Spacer(),
              // View details button
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to session details
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColorToken.golden.value.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: AppTextStyle.size(12)
                            .medium
                            .withColor(AppColorToken.golden),
                      ),
                      4.horizontalSpace,
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColorToken.golden.value,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColorToken.white.value.withAlpha(180),
          ),
          6.horizontalSpace,
          Text(
            '$label: $value',
            style: AppTextStyle.size(12)
                .regular
                .withColor(AppColorToken.white),
          ),
        ],
      ),
    );
  }
}