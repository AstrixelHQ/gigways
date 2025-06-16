import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/driver_density/models/density_models.dart';
import 'package:intl/intl.dart';

class DensityStatsCard extends StatelessWidget {
  const DensityStatsCard({
    super.key,
    required this.stats,
  });

  final DensityStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.white.value.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups,
                color: AppColorToken.golden.value,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Drivers',
                style: TextStyle(
                  color: AppColorToken.white.value,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Updated ${_formatTime(stats.lastUpdated)}',
                style: TextStyle(
                  color: AppColorToken.white.value.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: stats.cityName,
                  value: NumberFormat('#,###').format(stats.cityDrivers),
                  icon: Icons.location_city,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: stats.stateName,
                  value: NumberFormat('#,###').format(stats.stateDrivers),
                  icon: Icons.map,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Nationwide',
                  value: NumberFormat('#,###').format(stats.nationalDrivers),
                  icon: Icons.public,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColorToken.golden.value,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColorToken.white.value,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColorToken.white.value.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}