import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/insights/widgets/dual_wheel_selector.dart';

/// Base class for value selector sheets
abstract class ImprovedValueSelector extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;

  const ImprovedValueSelector({
    Key? key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
  }) : super(key: key);
}

/// Miles selector with dual wheels (whole numbers and decimal)
class ImprovedMilesSelector extends ImprovedValueSelector {
  const ImprovedMilesSelector({
    Key? key,
    required double initialValue,
    double minValue = 0.0,
    double maxValue = 999.9,
  }) : super(
          key: key,
          initialValue: initialValue,
          minValue: minValue,
          maxValue: maxValue,
        );

  @override
  State<ImprovedMilesSelector> createState() => _ImprovedMilesSelectorState();

  /// Static method to show the sheet and return selected value
  static Future<double?> show({
    required BuildContext context,
    required double initialValue,
    double minValue = 0.0,
    double maxValue = 999.9,
  }) async {
    return await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImprovedMilesSelector(
        initialValue: initialValue,
        minValue: minValue,
        maxValue: maxValue,
      ),
    );
  }
}

class _ImprovedMilesSelectorState extends State<ImprovedMilesSelector> {
  late double _selectedValue;
  late DualWheelSelector _wheelSelector;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar for better UX
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorToken.white.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Miles',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColorToken.golden.value.withAlpha(50)),

            // Miles value display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColorToken.golden.value,
                    size: 24,
                  ),
                  8.horizontalSpace,
                  Text(
                    '${_selectedValue.toStringAsFixed(1)} mi',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),

            // Dual wheel selector
            _wheelSelector = DualWheelSelector(
              initialValue: _selectedValue,
              minValue: widget.minValue,
              maxValue: widget.maxValue,
              suffix: 'mi',
              isHoursMode: false,
              onValueChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
              },
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedValue);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorToken.golden.value,
                    foregroundColor: AppColorToken.black.value,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: AppTextStyle.size(16)
                        .bold
                        .withColor(AppColorToken.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hours selector with dual wheels (hours and minutes)
class ImprovedHoursSelector extends ImprovedValueSelector {
  const ImprovedHoursSelector({
    Key? key,
    required double initialValue,
    double minValue = 0.0,
    double maxValue = 24.0,
  }) : super(
          key: key,
          initialValue: initialValue,
          minValue: minValue,
          maxValue: maxValue,
        );

  @override
  State<ImprovedHoursSelector> createState() => _ImprovedHoursSelectorState();

  /// Static method to show the sheet and return selected value
  static Future<double?> show({
    required BuildContext context,
    required double initialValue,
    double minValue = 0.0,
    double maxValue = 24.0,
  }) async {
    return await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImprovedHoursSelector(
        initialValue: initialValue,
        minValue: minValue,
        maxValue: maxValue,
      ),
    );
  }
}

class _ImprovedHoursSelectorState extends State<ImprovedHoursSelector> {
  late double _selectedValue;
  late DualWheelSelector _wheelSelector;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar for better UX
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorToken.white.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Hours',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColorToken.golden.value.withAlpha(50)),

            // Hours value display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColorToken.golden.value,
                    size: 24,
                  ),
                  8.horizontalSpace,
                  Text(
                    _formatHoursMinutes(_selectedValue),
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),

            // Dual wheel selector for hours and minutes
            _wheelSelector = DualWheelSelector(
              initialValue: _selectedValue,
              minValue: widget.minValue,
              maxValue: widget.maxValue,
              suffix: 'hrs',
              isHoursMode: true,
              onValueChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
              },
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedValue);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorToken.golden.value,
                    foregroundColor: AppColorToken.black.value,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: AppTextStyle.size(16)
                        .bold
                        .withColor(AppColorToken.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format hours and minutes display (e.g., "2h 30m")
  String _formatHoursMinutes(double hours) {
    final hoursInt = hours.floor();
    final minutes = ((hours - hoursInt) * 60).round();

    if (minutes == 0) {
      return '${hoursInt}h 0m';
    } else {
      return '${hoursInt}h ${minutes}m';
    }
  }
}
