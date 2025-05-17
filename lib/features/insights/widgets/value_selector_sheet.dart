import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';

/// Base class for value selector sheets
abstract class ValueSelectorSheet extends StatefulWidget {
  final double initialValue;

  const ValueSelectorSheet({
    Key? key,
    required this.initialValue,
  }) : super(key: key);
}

/// Miles selector with direct input and adjustment buttons
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
  late TextEditingController _textController;
  final double minValue = 0.0;
  final double maxValue = 1000.0;
  final double smallStep = 0.1;
  final double largeStep = 1.0;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    _textController =
        TextEditingController(text: selectedValue.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateValue(double value) {
    // Ensure the value is within bounds
    final newValue = value.clamp(minValue, maxValue);

    setState(() {
      selectedValue = newValue;
      _textController.text = newValue.toStringAsFixed(1);

      // Make sure cursor position is at the end
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    'Enter Miles',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, selectedValue);
                    },
                    child: Text(
                      'Done',
                      style: AppTextStyle.size(16)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColorToken.golden.value.withAlpha(50)),

            // Icon
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Icon(
                Icons.directions_car,
                color: AppColorToken.golden.value,
                size: 40,
              ),
            ),

            // Direct text input
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: AppTextStyle.size(28)
                            .bold
                            .withColor(AppColorToken.golden),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          suffixText: 'mi',
                          suffixStyle: AppTextStyle.size(20).medium.withColor(
                              AppColorToken.white..color.withAlpha(150)),
                        ),
                        inputFormatters: [
                          // Allow numbers with max 1 decimal place
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,1}')),
                          // Ensure it doesn't exceed max value
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            try {
                              final value = double.parse(newValue.text);
                              if (value > maxValue) {
                                return oldValue;
                              }
                            } catch (_) {}
                            return newValue;
                          }),
                        ],
                        onChanged: (value) {
                          if (value.isEmpty) return;
                          try {
                            _updateValue(double.parse(value));
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stepper buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Small decrement button (-0.1)
                  _buildStepperButton(
                    label: '-0.1',
                    onPressed: () {
                      _updateValue(selectedValue - smallStep);
                    },
                  ),

                  // Large decrement button (-1)
                  _buildStepperButton(
                    label: '-1',
                    onPressed: () {
                      _updateValue(selectedValue - largeStep);
                    },
                  ),

                  // Large increment button (+1)
                  _buildStepperButton(
                    label: '+1',
                    onPressed: () {
                      _updateValue(selectedValue + largeStep);
                    },
                  ),

                  // Small increment button (+0.1)
                  _buildStepperButton(
                    label: '+0.1',
                    onPressed: () {
                      _updateValue(selectedValue + smallStep);
                    },
                  ),
                ],
              ),
            ),

            // Quick select buttons
            Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quick Select',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white..value.withAlpha(150)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickSelectButton(5.0),
                      _buildQuickSelectButton(10.0),
                      _buildQuickSelectButton(15.0),
                      _buildQuickSelectButton(20.0),
                      _buildQuickSelectButton(30.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(double value) {
    return GestureDetector(
      onTap: () => _updateValue(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selectedValue == value
              ? AppColorToken.golden.value.withAlpha(80)
              : AppColorToken.black.value.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedValue == value
                ? AppColorToken.golden.value
                : AppColorToken.golden.value.withAlpha(50),
            width: selectedValue == value ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          '${value.toStringAsFixed(0)}',
          style: AppTextStyle.size(14).medium.withColor(
                selectedValue == value
                    ? AppColorToken.golden
                    : AppColorToken.white,
              ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(50),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
        ),
      ),
    );
  }
}

/// Hours selector with direct input and adjustment buttons
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
  late TextEditingController _textController;
  final double minValue = 0.0;
  final double maxValue = 24.0;
  final double smallStep = 0.25;
  final double largeStep = 1.0;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    _textController =
        TextEditingController(text: selectedValue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateValue(double value) {
    // Ensure the value is within bounds
    final newValue = value.clamp(minValue, maxValue);

    setState(() {
      selectedValue = newValue;
      _textController.text = newValue.toStringAsFixed(2);

      // Make sure cursor position is at the end
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    'Enter Hours',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, selectedValue);
                    },
                    child: Text(
                      'Done',
                      style: AppTextStyle.size(16)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColorToken.golden.value.withAlpha(50)),

            // Icon
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Icon(
                Icons.access_time,
                color: AppColorToken.golden.value,
                size: 40,
              ),
            ),

            // Direct text input
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: AppTextStyle.size(28)
                            .bold
                            .withColor(AppColorToken.golden),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          suffixText: 'hrs',
                          suffixStyle: AppTextStyle.size(20).medium.withColor(
                              AppColorToken.white..value.withAlpha(150)),
                        ),
                        inputFormatters: [
                          // Allow numbers with max 2 decimal places
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                          // Ensure it doesn't exceed max value
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            try {
                              final value = double.parse(newValue.text);
                              if (value > maxValue) {
                                return oldValue;
                              }
                            } catch (_) {}
                            return newValue;
                          }),
                        ],
                        onChanged: (value) {
                          if (value.isEmpty) return;
                          try {
                            _updateValue(double.parse(value));
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stepper buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Small decrement button (-0.25)
                  _buildStepperButton(
                    label: '-0.25',
                    onPressed: () {
                      _updateValue(selectedValue - smallStep);
                    },
                  ),

                  // Large decrement button (-1)
                  _buildStepperButton(
                    label: '-1',
                    onPressed: () {
                      _updateValue(selectedValue - largeStep);
                    },
                  ),

                  // Large increment button (+1)
                  _buildStepperButton(
                    label: '+1',
                    onPressed: () {
                      _updateValue(selectedValue + largeStep);
                    },
                  ),

                  // Small increment button (+0.25)
                  _buildStepperButton(
                    label: '+0.25',
                    onPressed: () {
                      _updateValue(selectedValue + smallStep);
                    },
                  ),
                ],
              ),
            ),

            // Quick select buttons
            Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quick Select',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white..value.withAlpha(150)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickSelectButton(1.0),
                      _buildQuickSelectButton(2.0),
                      _buildQuickSelectButton(3.0),
                      _buildQuickSelectButton(4.0),
                      _buildQuickSelectButton(8.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(double value) {
    return GestureDetector(
      onTap: () => _updateValue(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selectedValue == value
              ? AppColorToken.golden.value.withAlpha(80)
              : AppColorToken.black.value.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedValue == value
                ? AppColorToken.golden.value
                : AppColorToken.golden.value.withAlpha(50),
            width: selectedValue == value ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          '${value.toStringAsFixed(0)}',
          style: AppTextStyle.size(14).medium.withColor(
                selectedValue == value
                    ? AppColorToken.golden
                    : AppColorToken.white,
              ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(50),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
        ),
      ),
    );
  }
}
