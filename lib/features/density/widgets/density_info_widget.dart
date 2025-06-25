import 'package:flutter/material.dart';
import 'package:gigways/core/theme/app_colors.dart';

import '../notifiers/density_notifier.dart';

class DensityInfoWidget extends StatelessWidget {
  final DensityState densityState;
  final bool isLocationLoading;

  const DensityInfoWidget({
    super.key,
    required this.densityState,
    required this.isLocationLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocationLoading || densityState.isLoading) {
      return _buildLoadingCard();
    }

    if (densityState.error != null) {
      return _buildErrorCard();
    }

    if (densityState.grids.isEmpty) {
      return _buildEmptyCard();
    }

    return SizedBox.shrink();
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColorToken.golden.value),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Loading driver density data...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Loading Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    densityState.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tap "Use My Location" to view driver density in your area',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
