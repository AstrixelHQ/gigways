import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';

class NumberSelectorWheel extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;
  final double step;
  final ValueChanged<double> onChanged;
  final String Function(double) formatValue;
  final String? suffix;

  const NumberSelectorWheel({
    Key? key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.onChanged,
    required this.formatValue,
    this.suffix,
  }) : super(key: key);

  @override
  State<NumberSelectorWheel> createState() => _NumberSelectorWheelState();
}

class _NumberSelectorWheelState extends State<NumberSelectorWheel> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  late List<double> _values;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    // Calculate how many values we need
    final count =
        ((widget.maxValue - widget.minValue) / widget.step).ceil() + 1;

    // Generate all possible values
    _values = List.generate(
      count,
      (index) => widget.minValue + (index * widget.step),
    );

    // Find the closest index to initial value
    _selectedIndex = _findClosestIndex(widget.initialValue);

    // Initialize the scroll controller to the selected index
    _scrollController =
        FixedExtentScrollController(initialItem: _selectedIndex);
  }

  int _findClosestIndex(double value) {
    // Ensure the value is within range
    final clampedValue = value.clamp(widget.minValue, widget.maxValue);

    // Find closest index
    return ((clampedValue - widget.minValue) / widget.step).round();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker.builder(
      scrollController: _scrollController,
      itemExtent: 50,
      onSelectedItemChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.onChanged(_values[index]);
      },
      childCount: _values.length,
      itemBuilder: (context, index) {
        final isSelected = index == _selectedIndex;
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.formatValue(_values[index]),
                style: TextStyle(
                  fontSize: isSelected ? 22 : 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColorToken.golden.value
                      : AppColorToken.white.value.withOpacity(0.7),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  widget.suffix!,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 14,
                    color: isSelected
                        ? AppColorToken.golden.value
                        : AppColorToken.white.value.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      magnification: 1.2,
      squeeze: 0.8,
      useMagnifier: true,
      backgroundColor: Colors.transparent,
    );
  }
}
