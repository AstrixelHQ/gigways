import 'package:flutter/material.dart';
import 'package:gigways/core/theme/app_colors.dart';

import '../models/density_grid.dart';

class DensityBottomSheet extends StatelessWidget {
  final DensityGrid grid;

  const DensityBottomSheet({
    super.key,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Density Level
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(grid.level.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${grid.level.displayName} Density Area',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    grid.level.description,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location Information
                  _buildInfoSection(
                    'Location',
                    [
                      _buildInfoRow('City', grid.cityName),
                      _buildInfoRow('County', grid.countyName),
                      _buildInfoRow('State', grid.stateName),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Driver Statistics
                  _buildInfoSection(
                    'Driver Statistics',
                    [
                      _buildInfoRow(
                        'Estimated Drivers',
                        '${grid.estimatedDrivers}',
                        highlight: true,
                      ),
                      _buildInfoRow(
                          'Population', '${_formatNumber(grid.population)}'),
                      _buildInfoRow(
                        'Driver Percentage',
                        '${((grid.estimatedDrivers / grid.population) * 100).toStringAsFixed(2)}%',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Market Insights
                  _buildInfoSection(
                    'Market Insights',
                    [
                      _buildInfoRow(
                        'Competition Level',
                        _getCompetitionLevel(grid.estimatedDrivers),
                        highlight: true,
                      ),
                      _buildInfoRow(
                        'Best Time to Drive',
                        _getBestTimeToDrive(grid.level),
                      ),
                      _buildInfoRow(
                        'Area Type',
                        _getAreaType(grid.cityName),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Technical Details
                  _buildInfoSection(
                    'Technical Details',
                    [
                      _buildInfoRow('Grid ID', grid.gridId),
                      _buildInfoRow(
                          'Last Updated', _formatDateTime(grid.lastUpdated)),
                      _buildInfoRow(
                          'Coverage Area', '~5 miles radius per hexagon'),
                      _buildInfoRow('Total Coverage', '30 miles from center'),
                      _buildInfoRow('Grid Center', '${grid.hexagonBounds.isNotEmpty ? "${grid.hexagonBounds[0].latitude.toStringAsFixed(4)}, ${grid.hexagonBounds[0].longitude.toStringAsFixed(4)}" : "N/A"}'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Density Level Explanation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColorToken.golden.value.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorToken.golden.value.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColorToken.golden.value,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'How We Calculate Density',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Driver density is estimated based on local population data from the U.S. Census Bureau and location-based factors. We use consistent calculations to ensure reliable results.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Low: <15 drivers\n• Moderate: 15-34 drivers\n• High: ≥35 drivers',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getCompetitionLevel(int estimatedDrivers) {
    if (estimatedDrivers < 15) {
      return 'Low Competition';
    } else if (estimatedDrivers < 35) {
      return 'Moderate Competition';
    } else {
      return 'High Competition';
    }
  }

  String _getBestTimeToDrive(DensityLevel level) {
    switch (level) {
      case DensityLevel.low:
        return 'Peak hours & weekends';
      case DensityLevel.moderate:
        return 'Rush hours recommended';
      case DensityLevel.high:
        return 'Consider nearby areas';
    }
  }

  String _getAreaType(String cityName) {
    final cityLower = cityName.toLowerCase();

    // Check for urban indicators
    if (cityLower.contains('downtown') ||
        cityLower.contains('financial') ||
        cityLower.contains('central')) {
      return 'Urban/Business District';
    }

    // Check for residential indicators
    if (cityLower.contains('heights') ||
        cityLower.contains('hills') ||
        cityLower.contains('residential')) {
      return 'Residential Area';
    }

    // Check for commercial indicators
    if (cityLower.contains('mall') ||
        cityLower.contains('center') ||
        cityLower.contains('plaza')) {
      return 'Commercial Area';
    }

    return 'Mixed Use Area';
  }
}
