import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:time_range_picker/time_range_picker.dart';

class EnhancedTimePicker extends StatefulWidget {
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;
  final Function(TimeOfDay start, TimeOfDay end) onTimeRangeSelected;

  const EnhancedTimePicker({
    Key? key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onTimeRangeSelected,
  }) : super(key: key);

  @override
  State<EnhancedTimePicker> createState() => _EnhancedTimePickerState();
}

class _EnhancedTimePickerState extends State<EnhancedTimePicker> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  // Controllers for text fields
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;

    // Set initial text field values
    _updateTextFields();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  // Update text fields with current time values
  void _updateTextFields() {
    _startController.text = _formatTimeOfDay(_startTime);
    _endController.text = _formatTimeOfDay(_endTime);
  }

  // Format TimeOfDay to string (e.g., "9:00 AM")
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // Parse string to TimeOfDay (e.g., "9:00 AM" to TimeOfDay)
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle different time formats
      timeStr = timeStr.trim();

      // Check if it contains AM/PM
      bool isAM = timeStr.toUpperCase().contains('AM');
      bool isPM = timeStr.toUpperCase().contains('PM');

      // Remove AM/PM suffix
      timeStr = timeStr
          .toUpperCase()
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      // Split into hour and minute
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Adjust hour based on AM/PM
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // Show the visual time range picker
  Future<void> _showVisualPicker() async {
    final result = await showTimeRangePicker(
      context: context,
      start: _startTime,
      end: _endTime,
      use24HourFormat: false,
      strokeColor: AppColorToken.golden.value,
      handlerColor: AppColorToken.golden.value,
      selectedColor: AppColorToken.golden.value,
      backgroundColor: AppColorToken.black.value,
      ticks: 24,
      ticksColor: AppColorToken.white.value.withAlpha(50),
      labels: ["12 am", "3 am", "6 am", "9 am", "12 pm", "3 pm", "6 pm", "9 pm"]
          .asMap()
          .entries
          .map((e) {
        return ClockLabel.fromIndex(idx: e.key, length: 8, text: e.value);
      }).toList(),
      labelOffset: 30,
      rotateLabels: false,
      padding: 60,
    );

    if (result != null) {
      setState(() {
        _startTime = result.startTime;
        _endTime = result.endTime;
        _updateTextFields();
      });

      widget.onTimeRangeSelected(_startTime, _endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Text fields row
        Row(
          children: [
            // Start time field
            Expanded(
              child: TextField(
                controller: _startController,
                style:
                    AppTextStyle.size(14).medium.withColor(AppColorToken.white),
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  labelStyle: AppTextStyle.size(12).regular.withColor(
                        AppColorToken.white..color.withAlpha(70),
                      ),
                  suffix: Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColorToken.golden.value,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColorToken.white.value.withAlpha(30),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColorToken.golden.value,
                    ),
                  ),
                ),
                onTap: () async {
                  // Show time picker for start time only
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColorToken.golden.value,
                            onSurface: AppColorToken.white.value,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _startTime = picked;
                      _updateTextFields();
                    });
                    widget.onTimeRangeSelected(_startTime, _endTime);
                  }
                },
                onChanged: (value) {
                  final parsed = _parseTimeString(value);
                  if (parsed != null) {
                    setState(() {
                      _startTime = parsed;
                    });
                    widget.onTimeRangeSelected(_startTime, _endTime);
                  }
                },
              ),
            ),
            16.horizontalSpace,
            // End time field
            Expanded(
              child: TextField(
                controller: _endController,
                style:
                    AppTextStyle.size(14).medium.withColor(AppColorToken.white),
                decoration: InputDecoration(
                  labelText: 'End Time',
                  labelStyle: AppTextStyle.size(12).regular.withColor(
                        AppColorToken.white..color.withAlpha(70),
                      ),
                  suffix: Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColorToken.golden.value,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColorToken.white.value.withAlpha(30),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColorToken.golden.value,
                    ),
                  ),
                ),
                onTap: () async {
                  // Show time picker for end time only
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColorToken.golden.value,
                            onSurface: AppColorToken.white.value,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _endTime = picked;
                      _updateTextFields();
                    });
                    widget.onTimeRangeSelected(_startTime, _endTime);
                  }
                },
                onChanged: (value) {
                  final parsed = _parseTimeString(value);
                  if (parsed != null) {
                    setState(() {
                      _endTime = parsed;
                    });
                    widget.onTimeRangeSelected(_startTime, _endTime);
                  }
                },
              ),
            ),
          ],
        ),
        16.verticalSpace,

        // Visual picker button
        GestureDetector(
          onTap: _showVisualPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColorToken.black.value,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  color: AppColorToken.golden.value,
                  size: 20,
                ),
                8.horizontalSpace,
                Text(
                  'Show Visual Time Picker',
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
