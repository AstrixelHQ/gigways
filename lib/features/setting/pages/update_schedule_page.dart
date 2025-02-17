import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:time_range_picker/time_range_picker.dart';

class UpdateSchedulePage extends ConsumerStatefulWidget {
  const UpdateSchedulePage({super.key});

  static const String path = '/update-schedule';

  @override
  ConsumerState<UpdateSchedulePage> createState() => _UpdateSchedulePageState();
}

class _UpdateSchedulePageState extends ConsumerState<UpdateSchedulePage> {
  bool isPartTime = true;
  bool isDayShift = true;
  Map<String, bool> selectedDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  Map<String, PickerTimeRange?> dayTimeRanges = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.verticalSpace,
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColorToken.golden.value,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColorToken.golden.value,
                          size: 20,
                        ),
                      ),
                    ),
                    16.horizontalSpace,
                    Text(
                      'My Schedule',
                      style: AppTextStyle.size(24)
                          .bold
                          .withColor(AppColorToken.white),
                    ),
                  ],
                ),
                32.verticalSpace,

                // Employment Type Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorToken.golden.value.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employment Type',
                        style: AppTextStyle.size(18)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                      16.verticalSpace,
                      Row(
                        children: [
                          _buildTypeButton(
                            isSelected: isPartTime,
                            text: 'Part-Time',
                            onTap: () => setState(() => isPartTime = true),
                          ),
                          16.horizontalSpace,
                          _buildTypeButton(
                            isSelected: !isPartTime,
                            text: 'Full-Time',
                            onTap: () => setState(() => isPartTime = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                // Shift Preference
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorToken.golden.value.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Preference',
                        style: AppTextStyle.size(18)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                      16.verticalSpace,
                      Row(
                        children: [
                          _buildShiftButton(
                            isSelected: isDayShift,
                            icon: Icons.wb_sunny_outlined,
                            text: 'Day',
                            onTap: () => setState(() => isDayShift = true),
                          ),
                          16.horizontalSpace,
                          _buildShiftButton(
                            isSelected: !isDayShift,
                            icon: Icons.nightlight_outlined,
                            text: 'Night',
                            onTap: () => setState(() => isDayShift = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                // Weekly Schedule
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorToken.golden.value.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Schedule',
                        style: AppTextStyle.size(18)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                      16.verticalSpace,
                      ...selectedDays.entries.map((entry) => _buildDaySchedule(
                            day: entry.key,
                            isSelected: entry.value,
                            timeRange: dayTimeRanges[entry.key],
                          )),
                    ],
                  ),
                ),
                32.verticalSpace,

                // Save Button
                AppButton(
                  text: 'Save Schedule',
                  onPressed: _saveSchedule,
                ),
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required bool isSelected,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColorToken.golden.value
                : AppColorToken.black.value,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColorToken.golden.value,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyle.size(16).medium.withColor(
                    isSelected ? AppColorToken.black : AppColorToken.golden,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftButton({
    required bool isSelected,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColorToken.golden.value
                : AppColorToken.black.value,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColorToken.golden.value,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColorToken.black.color
                    : AppColorToken.golden.color,
                size: 20,
              ),
              8.horizontalSpace,
              Text(
                text,
                style: AppTextStyle.size(16).medium.withColor(
                      isSelected ? AppColorToken.black : AppColorToken.golden,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySchedule({
    required String day,
    required bool isSelected,
    required PickerTimeRange? timeRange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDays[day] = !selectedDays[day]!;
                if (!selectedDays[day]!) {
                  dayTimeRanges[day] = null;
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColorToken.golden.value,
                ),
                color: isSelected
                    ? AppColorToken.golden.value
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: AppColorToken.black.value,
                    )
                  : null,
            ),
          ),
          16.horizontalSpace,
          SizedBox(
            width: 100,
            child: Text(
              day,
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
          ),
          if (isSelected) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTimeRange(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColorToken.golden.value.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    timeRange?.format() ?? 'Select Hours',
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTimeRange(String day) async {
    final PickerTimeRange? result = await _showTimeRangePicker(
      context: context,
      start: dayTimeRanges[day]?.start ?? TimeOfDay(hour: 9, minute: 0),
      end: dayTimeRanges[day]?.end ?? TimeOfDay(hour: 17, minute: 0),
      disabledTime: PickerTimeRange(
        // startTime: TimeOfDay(hour: 23, minute: 0),
        // endTime: TimeOfDay(hour: 5, minute: 0),
        start: TimeOfDay(hour: 0, minute: 0),
        end: TimeOfDay(hour: 0, minute: 0),
      ),
      backgroundColor: AppColorToken.black.value,
      selectedColor: AppColorToken.golden.value,
      strokeColor: AppColorToken.golden.value,
      handlerColor: AppColorToken.golden.value,
      strokeWidth: 4,
      timeTextStyle:
          AppTextStyle.size(16).medium.withColor(AppColorToken.white),
      activeTimeTextStyle:
          AppTextStyle.size(16).bold.withColor(AppColorToken.black),
    );

    if (result != null) {
      setState(() {
        dayTimeRanges[day] = result;
      });
    }
  }

  void _saveSchedule() {
    // Prepare schedule data
    final schedule = {
      'employmentType': isPartTime ? 'Part-Time' : 'Full-Time',
      'shiftPreference': isDayShift ? 'Day' : 'Night',
      'weeklySchedule': selectedDays.map((day, isSelected) => MapEntry(
            day,
            isSelected
                ? {
                    'isSelected': true,
                    'timeRange': dayTimeRanges[day]?.toMap(),
                  }
                : {'isSelected': false},
          )),
    };

    // Save schedule (implement your save logic)
    print('Saving schedule: $schedule');
  }
}

// Time Range Model
class PickerTimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  PickerTimeRange({
    required this.start,
    required this.end,
  });

  String format() {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'start': {'hour': start.hour, 'minute': start.minute},
      'end': {'hour': end.hour, 'minute': end.minute},
    };
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

// Time Range Picker Dialog
Future<PickerTimeRange?> _showTimeRangePicker({
  required BuildContext context,
  required TimeOfDay start,
  required TimeOfDay end,
  required PickerTimeRange disabledTime,
  required Color backgroundColor,
  required Color selectedColor,
  required Color strokeColor,
  required Color handlerColor,
  required double strokeWidth,
  required TextStyle timeTextStyle,
  required TextStyle activeTimeTextStyle,
}) async {
  final TimeRange? result = await showTimeRangePicker(
    context: context,
    paintingStyle: PaintingStyle.fill,
    labels: ["12 am", "3 am", "6 am", "9 am", "12 pm", "3 pm", "6 pm", "9 pm"]
        .asMap()
        .entries
        .map((e) {
      return ClockLabel.fromIndex(idx: e.key, length: 8, text: e.value);
    }).toList(),
    labelOffset: -30,
    autoAdjustLabels: true,
    handlerColor: handlerColor,
    labelStyle: const TextStyle(
      fontSize: 22,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    ),
    ticks: 8,
    clockRotation: 180.0,
    timeTextStyle: TextStyle(
      color: AppColorToken.golden.color,
      fontSize: 24,
      fontWeight: FontWeight.w500,
    ),
    activeTimeTextStyle: TextStyle(
      color: AppColorToken.orange.color,
      fontSize: 25,
      fontWeight: FontWeight.w500,
    ),
  );

  if (result != null) {
    return PickerTimeRange(
      start: result.startTime,
      end: result.endTime,
    );
  } else {
    return null;
  }
}
