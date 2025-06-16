import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/driver_density/models/density_models.dart';

class ForecastSelector extends StatelessWidget {
  const ForecastSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final ForecastPeriod selectedPeriod;
  final ValueChanged<ForecastPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.white.value.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ForecastPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColorToken.golden.value
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      period.displayName,
                      style: TextStyle(
                        color: isSelected 
                          ? AppColorToken.black.value
                          : AppColorToken.white.value,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'forecast',
                      style: TextStyle(
                        color: isSelected 
                          ? AppColorToken.black.value.withOpacity(0.7)
                          : AppColorToken.white.value.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}