import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/driver_density/models/density_models.dart';
import 'package:intl/intl.dart';

class GridDetailSheet extends StatelessWidget {
  const GridDetailSheet({
    super.key,
    required this.grid,
    required this.selectedForecast,
  });

  final DensityGrid grid;
  final ForecastPeriod selectedForecast;

  @override
  Widget build(BuildContext context) {
    final forecast = _generateMockForecast();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppColorToken.golden.value.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColorToken.white.value.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getDensityColor(grid.level),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Grid Details',
                style: TextStyle(
                  color: AppColorToken.white.value,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Current Status
          _buildSection(
            title: 'Current Status',
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Active Drivers',
                    '${grid.driverCount}',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Density Level',
                    grid.level.displayName,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Forecast
          _buildSection(
            title: '${selectedForecast.displayName} Forecast',
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Predicted Drivers',
                    '${forecast.predictedDriverCount}',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Confidence',
                    '${(forecast.confidence * 100).toInt()}%',
                    Icons.analytics,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Location Info
          _buildSection(
            title: 'Location',
            child: Column(
              children: [
                _buildLocationRow('Lat', grid.center.latitude.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _buildLocationRow('Lng', grid.center.longitude.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _buildLocationRow('Updated', _formatTime(grid.lastUpdated)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToGrid(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorToken.golden.value,
                foregroundColor: AppColorToken.black.value,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Navigate to This Area',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColorToken.golden.value,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
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

  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColorToken.white.value.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColorToken.white.value,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getDensityColor(DensityLevel level) {
    switch (level) {
      case DensityLevel.low:
        return Colors.green;
      case DensityLevel.moderate:
        return Colors.orange;
      case DensityLevel.high:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  DensityForecast _generateMockForecast() {
    // Mock forecast based on current data and selected period
    final baseDrivers = grid.driverCount;
    int predictedDrivers;
    double confidence;

    switch (selectedForecast) {
      case ForecastPeriod.fifteenMinutes:
        predictedDrivers = baseDrivers + (-2 + (baseDrivers % 5));
        confidence = 0.9;
        break;
      case ForecastPeriod.thirtyMinutes:
        predictedDrivers = baseDrivers + (-3 + (baseDrivers % 7));
        confidence = 0.8;
        break;
      case ForecastPeriod.oneHour:
        predictedDrivers = baseDrivers + (-5 + (baseDrivers % 10));
        confidence = 0.7;
        break;
    }

    // Ensure positive driver count
    predictedDrivers = predictedDrivers.clamp(0, double.infinity).round();

    return DensityForecast(
      gridId: grid.id,
      predictedDriverCount: predictedDrivers,
      forecastTime: DateTime.now().add(selectedForecast.duration),
      period: selectedForecast,
      confidence: confidence,
    );
  }

  void _navigateToGrid(BuildContext context) {
    // TODO: Implement navigation to grid location
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${grid.center.latitude.toStringAsFixed(4)}, ${grid.center.longitude.toStringAsFixed(4)}'),
        backgroundColor: AppColorToken.golden.value,
      ),
    );
  }
}