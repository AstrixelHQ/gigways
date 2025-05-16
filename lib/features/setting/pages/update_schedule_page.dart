import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/extensions/snackbar_extension.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/enhanced_time_picker.dart';
import 'package:gigways/core/widgets/loading_overlay.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/schedule/models/schedule_models.dart';
import 'package:gigways/features/schedule/notifiers/schedule_notifier.dart';

class UpdateSchedulePage extends ConsumerStatefulWidget {
  const UpdateSchedulePage({super.key});

  static const String path = '/update-schedule';

  @override
  ConsumerState<UpdateSchedulePage> createState() => _UpdateSchedulePageState();
}

class _UpdateSchedulePageState extends ConsumerState<UpdateSchedulePage> {
  final Map<String, bool> selectedDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  // Time ranges for local UI management
  final Map<String, PickerTimeRange?> dayTimeRanges = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScheduleData();
    });
  }

  void _initializeScheduleData() {
    final schedule = ref.read(scheduleNotifierProvider).schedule;
    if (schedule == null) return;

    // Set employment type and shift preference in notifier
    // (Data is already in the notifier, just ensuring it's there)

    // Initialize the UI state from the schedule
    setState(() {
      // Initialize selected days
      schedule.weeklySchedule.forEach((day, daySchedule) {
        selectedDays[day] = daySchedule != null;

        if (daySchedule != null) {
          final startTime = TimeOfDay(
            hour: daySchedule.timeRange.start.hour,
            minute: daySchedule.timeRange.start.minute,
          );

          final endTime = TimeOfDay(
            hour: daySchedule.timeRange.end.hour,
            minute: daySchedule.timeRange.end.minute,
          );

          dayTimeRanges[day] = PickerTimeRange(start: startTime, end: endTime);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final isLoading = scheduleState.status == ScheduleStatus.loading;
    final schedule = scheduleState.schedule ?? ScheduleModel.defaultSchedule();

    // Listen for status changes
    ref.listen(scheduleNotifierProvider, (previous, current) {
      if (current.status == ScheduleStatus.success) {
        context.showSuccessSnackbar('Schedule updated successfully');
      } else if (current.status == ScheduleStatus.error) {
        context.showErrorSnackbar('Error updating schedule');
      }
    });

    return LoadingOverlay(
      isLoading: isLoading,
      child: ScaffoldWrapper(
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
                      color: AppColorToken.black.value.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorToken.golden.value.withAlpha(30),
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
                              isSelected:
                                  schedule.employmentType == 'Part-Time',
                              text: 'Part-Time',
                              onTap: () => ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .updateEmploymentType('Part-Time'),
                            ),
                            16.horizontalSpace,
                            _buildTypeButton(
                              isSelected:
                                  schedule.employmentType == 'Full-Time',
                              text: 'Full-Time',
                              onTap: () => ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .updateEmploymentType('Full-Time'),
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
                      color: AppColorToken.black.value.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorToken.golden.value.withAlpha(30),
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
                              isSelected: schedule.shiftPreference == 'Day',
                              icon: Icons.wb_sunny_outlined,
                              text: 'Day',
                              onTap: () => ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .updateShiftPreference('Day'),
                            ),
                            16.horizontalSpace,
                            _buildShiftButton(
                              isSelected: schedule.shiftPreference == 'Night',
                              icon: Icons.nightlight_outlined,
                              text: 'Night',
                              onTap: () => ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .updateShiftPreference('Night'),
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
                      color: AppColorToken.black.value.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorToken.golden.value.withAlpha(30),
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
                        ...selectedDays.entries
                            .map((entry) => _buildDaySchedule(
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
                  // Update the schedule in the notifier
                  ref.read(scheduleNotifierProvider.notifier).updateDaySchedule(
                        day,
                        null,
                        null,
                      );
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
                      color: AppColorToken.golden.value.withAlpha(30),
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
    // Default start/end times
    final defaultStart =
        dayTimeRanges[day]?.start ?? const TimeOfDay(hour: 9, minute: 0);
    final defaultEnd =
        dayTimeRanges[day]?.end ?? const TimeOfDay(hour: 17, minute: 0);

    // Show dialog with enhanced time picker
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorToken.black.value,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColorToken.golden.value.withAlpha(30),
          ),
        ),
        title: Text(
          'Set Work Hours for $day',
          style: AppTextStyle.size(18).medium.withColor(AppColorToken.golden),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EnhancedTimePicker(
                initialStartTime: defaultStart,
                initialEndTime: defaultEnd,
                onTimeRangeSelected: (start, end) {
                  setState(() {
                    dayTimeRanges[day] = PickerTimeRange(
                      start: start,
                      end: end,
                    );

                    // Also update the notifier
                    ref
                        .read(scheduleNotifierProvider.notifier)
                        .updateDaySchedule(
                          day,
                          start,
                          end,
                        );
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Done',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _saveSchedule() {
    // Save schedule data
    ref.read(scheduleNotifierProvider.notifier).saveSchedule();
  }
}

// Time Range Model for UI
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
