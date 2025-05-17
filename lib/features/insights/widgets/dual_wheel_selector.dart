import 'package:flutter/cupertino.dart';
import 'package:gigways/core/theme/themes.dart';

class DualWheelSelector extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;
  final ValueChanged<double> onValueChanged;
  final String suffix;
  final bool isHoursMode;

  const DualWheelSelector({
    Key? key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onValueChanged,
    required this.suffix,
    this.isHoursMode = false,
  }) : super(key: key);

  @override
  State<DualWheelSelector> createState() => _DualWheelSelectorState();
}

class _DualWheelSelectorState extends State<DualWheelSelector> {
  late int _wholeNumberValue;
  late int _decimalValue;

  // For hours mode (time selection)
  late int _hours;
  late int _minutes;

  // Controllers for the pickers to programmatically scroll them
  late FixedExtentScrollController _firstWheelController;
  late FixedExtentScrollController _secondWheelController;

  @override
  void initState() {
    super.initState();
    if (widget.isHoursMode) {
      // Initialize time values
      _hours = widget.initialValue.floor();
      // Convert decimal part to minutes (e.g., 0.5 hours = 30 minutes)
      _minutes = ((widget.initialValue - _hours) * 60).round();
      // Round minutes to nearest 5
      _minutes = (_minutes / 5).round() * 5;
      if (_minutes == 60) {
        _hours += 1;
        _minutes = 0;
      }

      // Initialize controllers
      _firstWheelController = FixedExtentScrollController(initialItem: _hours);
      _secondWheelController =
          FixedExtentScrollController(initialItem: _minutes ~/ 5);
    } else {
      // Initialize number values (for miles)
      _wholeNumberValue = widget.initialValue.floor();
      _decimalValue = ((widget.initialValue - _wholeNumberValue) * 10).round();

      // Initialize controllers
      _firstWheelController =
          FixedExtentScrollController(initialItem: _wholeNumberValue);
      _secondWheelController =
          FixedExtentScrollController(initialItem: _decimalValue);
    }
  }

  @override
  void dispose() {
    _firstWheelController.dispose();
    _secondWheelController.dispose();
    super.dispose();
  }

  void _updateValue() {
    if (widget.isHoursMode) {
      // Convert hours and minutes to decimal hours
      final value = _hours + (_minutes / 60);
      widget.onValueChanged(value);
    } else {
      // Combine whole number and decimal for miles
      final value = _wholeNumberValue + (_decimalValue / 10);
      widget.onValueChanged(value);
    }
  }

  // Method to programmatically update the wheels based on a selected value
  void updateToValue(double value) {
    if (widget.isHoursMode) {
      final newHours = value.floor();
      final newMinutes = ((value - newHours) * 60).round();
      final roundedMinutes = (newMinutes / 5).round() * 5;

      setState(() {
        _hours = newHours;
        _minutes = roundedMinutes;
      });

      // Animate the wheels to the new position
      _firstWheelController.animateToItem(
        newHours,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _secondWheelController.animateToItem(
        roundedMinutes ~/ 5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final newWholeNumber = value.floor();
      final newDecimal = ((value - newWholeNumber) * 10).round();

      setState(() {
        _wholeNumberValue = newWholeNumber;
        _decimalValue = newDecimal;
      });

      // Animate the wheels to the new position
      _firstWheelController.animateToItem(
        newWholeNumber,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _secondWheelController.animateToItem(
        newDecimal,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Update the value
    _updateValue();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // First wheel (whole numbers or hours)
              Expanded(
                flex: 2,
                child: _buildFirstWheel(),
              ),

              // Separator
              if (widget.isHoursMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ":",
                    style: AppTextStyle.size(30)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ".",
                    style: AppTextStyle.size(30)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ),

              // Second wheel (decimals or minutes)
              Expanded(
                flex: widget.isHoursMode ? 2 : 1,
                child: _buildSecondWheel(),
              ),

              // Suffix
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  widget.suffix,
                  style: AppTextStyle.size(20)
                      .medium
                      .withColor(AppColorToken.golden),
                ),
              ),
            ],
          ),
        ),
        _buildQuickSelectButtons(),
      ],
    );
  }

  Widget _buildFirstWheel() {
    if (widget.isHoursMode) {
      // Hours wheel (0-24)
      return CupertinoPicker(
        scrollController: _firstWheelController,
        itemExtent: 40,
        onSelectedItemChanged: (int value) {
          setState(() {
            _hours = value;
            _updateValue();
          });
        },
        children: List<Widget>.generate(25, (int index) {
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style:
                  AppTextStyle.size(22).medium.withColor(AppColorToken.white),
            ),
          );
        }),
      );
    } else {
      // Whole number wheel for miles (0-999)
      return CupertinoPicker(
        scrollController: _firstWheelController,
        itemExtent: 40,
        onSelectedItemChanged: (int value) {
          setState(() {
            _wholeNumberValue = value;
            _updateValue();
          });
        },
        children: List<Widget>.generate(1000, (int index) {
          return Center(
            child: Text(
              index.toString(),
              style:
                  AppTextStyle.size(22).medium.withColor(AppColorToken.white),
            ),
          );
        }),
      );
    }
  }

  Widget _buildSecondWheel() {
    if (widget.isHoursMode) {
      // Minutes wheel (0-59, in 5-minute increments)
      return CupertinoPicker(
        scrollController: _secondWheelController,
        itemExtent: 40,
        onSelectedItemChanged: (int value) {
          setState(() {
            _minutes = value * 5;
            _updateValue();
          });
        },
        children: List<Widget>.generate(12, (int index) {
          return Center(
            child: Text(
              (index * 5).toString().padLeft(2, '0'),
              style:
                  AppTextStyle.size(22).medium.withColor(AppColorToken.white),
            ),
          );
        }),
      );
    } else {
      // Decimal wheel for miles (0-9)
      return CupertinoPicker(
        scrollController: _secondWheelController,
        itemExtent: 40,
        onSelectedItemChanged: (int value) {
          setState(() {
            _decimalValue = value;
            _updateValue();
          });
        },
        children: List<Widget>.generate(10, (int index) {
          return Center(
            child: Text(
              index.toString(),
              style:
                  AppTextStyle.size(22).medium.withColor(AppColorToken.white),
            ),
          );
        }),
      );
    }
  }

  Widget _buildQuickSelectButtons() {
    List<double> quickValues;

    if (widget.isHoursMode) {
      quickValues = [
        1.0,
        2.0,
        2.5,
        3.0,
        3.5,
        4.0,
        4.5,
        5.0,
        5.5,
        6.0,
        6.5,
        7.0,
        7.5,
        8.0
      ];
    } else {
      quickValues = [
        1.0,
        2.0,
        2.5,
        3.0,
        3.5,
        4.0,
        4.5,
        5.0,
        5.5,
        6.0,
        6.5,
        7.0,
        7.5,
        8.0,
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Quick Select',
              style: AppTextStyle.size(14)
                  .medium
                  .withColor(AppColorToken.white..color.withAlpha(150)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickValues
                  .map((value) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildQuickButton(value),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(double value) {
    // Calculate current selected value
    final currentValue = widget.isHoursMode
        ? _hours + (_minutes / 60)
        : _wholeNumberValue + (_decimalValue / 10);

    final bool isSelected = (currentValue - value).abs() < 0.01;

    return GestureDetector(
      onTap: () {
        // Update wheels to the selected value
        updateToValue(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorToken.golden.value.withAlpha(80)
              : AppColorToken.black.value.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColorToken.golden.value
                : AppColorToken.golden.value.withAlpha(50),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          widget.isHoursMode
              ? '${value.toStringAsFixed(1)} hrs'
              : '${value.toStringAsFixed(1)} mi',
          style: AppTextStyle.size(14).medium.withColor(
                isSelected ? AppColorToken.golden : AppColorToken.white,
              ),
        ),
      ),
    );
  }
}
