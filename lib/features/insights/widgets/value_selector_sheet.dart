import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';

/// Base class for value selector sheets
abstract class ValueSelectorSheet extends StatefulWidget {
  final double initialValue;
  
  const ValueSelectorSheet({
    Key? key,
    required this.initialValue,
  }) : super(key: key);
}

/// Miles selector with Cupertino wheel and quick adjustment buttons
class MilesSelectorSheet extends ValueSelectorSheet {
  const MilesSelectorSheet({
    Key? key,
    required double initialValue,
  }) : super(key: key, initialValue: initialValue);
  
  @override
  State<MilesSelectorSheet> createState() => _MilesSelectorSheetState();
  
  /// Static method to show the sheet and return selected value
  static Future<double?> show({
    required BuildContext context,
    required double initialValue,
  }) async {
    return await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => MilesSelectorSheet(initialValue: initialValue),
    );
  }
}

class _MilesSelectorSheetState extends State<MilesSelectorSheet> {
  late double selectedValue;
  
  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
      child: Column(
        children: [
          // Header with handle bar for better UX
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Miles',
                  style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, selectedValue);
                  },
                  child: Text(
                    'Done',
                    style: AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: AppColorToken.golden.value.withAlpha(50)),

          // Current value display
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon and description
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.directions_car,
                    color: AppColorToken.golden.value,
                    size: 40,
                  ),
                ),
                
                // Current value display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: selectedValue.toStringAsFixed(1),
                          style: AppTextStyle.size(42).bold.withColor(AppColorToken.golden),
                        ),
                        TextSpan(
                          text: ' mi',
                          style: AppTextStyle.size(20).medium.withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick adjust buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement button
                      _buildStepperButton(
                        icon: Icons.remove,
                        onPressed: () {
                          if (selectedValue > 0) {
                            setState(() {
                              selectedValue = (selectedValue <= 0.5) ? 0 : selectedValue - 0.5;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      // Increment button
                      _buildStepperButton(
                        icon: Icons.add,
                        onPressed: () {
                          setState(() {
                            selectedValue = (selectedValue >= 1000) ? 1000 : selectedValue + 0.5;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Guidance text
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'or scroll to select',
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(120)),
                  ),
                ),

                // The picker
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColorToken.golden.value.withAlpha(30),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: AppColorToken.golden.value.withAlpha(30),
                          width: 1,
                        ),
                      ),
                    ),
                    child: CupertinoPicker(
                      magnification: 1.2,
                      squeeze: 1.0,
                      useMagnifier: true,
                      itemExtent: 40,
                      looping: false,
                      backgroundColor: Colors.transparent,
                      scrollController: FixedExtentScrollController(
                        initialItem: (selectedValue * 2).toInt(),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedValue = index / 2;
                        });
                      },
                      children: List<Widget>.generate(
                        2001, // 0 to 1000 miles in 0.5 increments
                        (index) {
                          final value = index / 2;
                          return Center(
                            child: Text(
                              value.toStringAsFixed(1),
                              style: AppTextStyle.size(22).medium.withColor(AppColorToken.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hours selector with Cupertino wheel and quick adjustment buttons
class HoursSelectorSheet extends ValueSelectorSheet {
  const HoursSelectorSheet({
    Key? key,
    required double initialValue,
  }) : super(key: key, initialValue: initialValue);
  
  @override
  State<HoursSelectorSheet> createState() => _HoursSelectorSheetState();
  
  /// Static method to show the sheet and return selected value
  static Future<double?> show({
    required BuildContext context,
    required double initialValue,
  }) async {
    return await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => HoursSelectorSheet(initialValue: initialValue),
    );
  }
}

class _HoursSelectorSheetState extends State<HoursSelectorSheet> {
  late double selectedValue;
  
  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
      child: Column(
        children: [
          // Header with handle bar for better UX
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Hours',
                  style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, selectedValue);
                  },
                  child: Text(
                    'Done',
                    style: AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: AppColorToken.golden.value.withAlpha(50)),

          // Cupertino Picker
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon and description
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.access_time,
                    color: AppColorToken.golden.value,
                    size: 40,
                  ),
                ),
                
                // Current value display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: selectedValue.toStringAsFixed(2),
                          style: AppTextStyle.size(42).bold.withColor(AppColorToken.golden),
                        ),
                        TextSpan(
                          text: ' hrs',
                          style: AppTextStyle.size(20).medium.withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick adjust buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement button
                      _buildStepperButton(
                        icon: Icons.remove,
                        onPressed: () {
                          if (selectedValue > 0) {
                            setState(() {
                              selectedValue = (selectedValue <= 0.25) ? 0 : selectedValue - 0.25;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      // Increment button
                      _buildStepperButton(
                        icon: Icons.add,
                        onPressed: () {
                          setState(() {
                            selectedValue = (selectedValue >= 24) ? 24 : selectedValue + 0.25;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Guidance text
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'or scroll to select',
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(120)),
                  ),
                ),

                // The picker
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColorToken.golden.value.withAlpha(30),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: AppColorToken.golden.value.withAlpha(30),
                          width: 1,
                        ),
                      ),
                    ),
                    child: CupertinoPicker(
                      magnification: 1.2,
                      squeeze: 1.0,
                      useMagnifier: true,
                      itemExtent: 40,
                      looping: false,
                      backgroundColor: Colors.transparent,
                      scrollController: FixedExtentScrollController(
                        initialItem: (selectedValue * 4).toInt(),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedValue = index / 4; // For 0.25 hour increments
                        });
                      },
                      children: List<Widget>.generate(
                        97, // 0 to 24 hours in 0.25 increments
                        (index) {
                          final value = index / 4;
                          return Center(
                            child: Text(
                              value.toStringAsFixed(2),
                              style: AppTextStyle.size(22).medium.withColor(AppColorToken.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper method to create stepper buttons
Widget _buildStepperButton({
  required IconData icon, 
  required VoidCallback onPressed
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(80),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(50),
        ),
      ),
      child: Icon(
        icon,
        color: AppColorToken.golden.value,
        size: 24,
      ),
    ),
  );
}