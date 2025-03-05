// lib/features/strike/pages/strike_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/loading_overlay.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/strike/models/strike_model.dart';
import 'package:gigways/features/strike/notifiers/strike_notifier.dart';
import 'package:intl/intl.dart';

class StrikePage extends ConsumerStatefulWidget {
  const StrikePage({super.key});

  static const String path = '/strike';

  @override
  ConsumerState<StrikePage> createState() => _StrikePageState();
}

class _StrikePageState extends ConsumerState<StrikePage> {
  bool showCalendar = false;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Refresh strike data on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(strikeNotifierProvider.notifier).refreshStrikeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strikeState = ref.watch(strikeNotifierProvider);
    final isLoading = strikeState.status == StrikeStatus.loading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: ScaffoldWrapper(
        shouldShowGradient: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.verticalSpace,
                  // Header
                  Text(
                    'Strike',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                  24.verticalSpace,

                  // Error message if any
                  if (strikeState.status == StrikeStatus.error)
                    _buildErrorWidget(
                        strikeState.errorMessage ?? 'An error occurred'),

                  // Nationwide Strike Card - only show if user has selected a date or has an active strike
                  if (strikeState.userStrike != null ||
                      strikeState.selectedDate != null)
                    _buildNationwideStrikeCard(strikeState),

                  // Only show schedule card if user doesn't have an active strike

                  24.verticalSpace,

                  // Schedule Strike Section
                  if (showCalendar)
                    _buildCalendarView(strikeState)
                  else
                    _buildScheduleStrikeCard(strikeState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          16.horizontalSpace,
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationwideStrikeCard(StrikeState strikeState) {
    // Get the date to display (either user's strike date or selected date)
    final displayDate =
        strikeState.userStrike?.date ?? strikeState.selectedDate!;

    // Format date parts
    final month = DateFormat('MMM').format(displayDate);
    final day = DateFormat('dd').format(displayDate);
    final year = DateFormat('yyyy').format(displayDate);

    // Get statistics
    final statsToShow = strikeState.selectedDateStats;
    final totalParticipants = statsToShow?.totalCount ?? 0;

    // Get optimal time based on the date
    final startTime = strikeState.getRecommendedTime(displayDate);

    // Determine if it's daytime hours (6am-6pm)
    final isDay = startTime.contains('AM') ||
        (startTime.contains('PM') && int.parse(startTime.split(':')[0]) < 6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nationwide Strike',
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
              ),
              // Day/night icon based on time
              Icon(
                isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: AppColorToken.golden.value,
              ),
            ],
          ),
          24.verticalSpace,
          // Date Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateBox(month),
              16.horizontalSpace,
              Text(
                '-',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.white),
              ),
              16.horizontalSpace,
              _buildDateBox(day),
              16.horizontalSpace,
              Text(
                '-',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.white),
              ),
              16.horizontalSpace,
              _buildDateBox(year),
            ],
          ),
          16.verticalSpace,
          // Start Time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColorToken.white.value.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Start $startTime',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
              textAlign: TextAlign.center,
            ),
          ),
          16.verticalSpace,
          // Participants Count - Only show if there are actual participants
          if (totalParticipants > 0)
            RichText(
              text: TextSpan(
                style:
                    AppTextStyle.size(16).medium.withColor(AppColorToken.white),
                children: [
                  TextSpan(
                    text: '$totalParticipants',
                    style: TextStyle(
                      color: AppColorToken.golden.value,
                    ),
                  ),
                  const TextSpan(text: ' out of '),
                  TextSpan(
                    text: '${strikeState.totalUsers}',
                    style: TextStyle(
                      color: AppColorToken.golden.value,
                    ),
                  ),
                  const TextSpan(text: ' users chose this day!'),
                ],
              ),
            )
          else
            Text(
              'No participants for this day yet. Be the first!',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
          24.verticalSpace,
          // How To Strike Section
          Text(
            'How To Strike',
            style: AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
          ),
          12.verticalSpace,
          Text(
            'Stay home, relax and enjoy family time!',
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
          8.verticalSpace,
          Text(
            'Share with others!',
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStrikeCard(StrikeState strikeState) {
    // Get data to display
    final upcomingDates = strikeState.upcomingStrikeDates;
    final mostPopularDate = upcomingDates.isNotEmpty ? upcomingDates[0] : null;

    // Date to show (either user selected date or most popular upcoming date)
    final showDate = strikeState.selectedDate ?? mostPopularDate?.date;

    // Determine what statistics to show
    final datesToShow = upcomingDates.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Strike',
            style: AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,
          _buildParticipantInfo(
            'Nationwide users',
            '${strikeState.totalUsers}',
          ),
          8.verticalSpace,
          _buildParticipantInfo(
            '${strikeState.userState} users',
            '${strikeState.stateUsers}',
          ),
          16.verticalSpace,
          Text(
            'Strike to unite, demand higher wages, and improve conditions!',
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
          24.verticalSpace,

          // Progress Circle with popular dates
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(160, 160),
                        painter: ProgressCirclePainter(
                          progress: _calculateProgressFromDates(datesToShow),
                          color: AppColorToken.golden.value,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Use appropriate icon based on time of day
                          Icon(
                            _isDayTime()
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            color: AppColorToken.golden.value,
                            size: 24,
                          ),
                          8.verticalSpace,
                          Text(
                            _isDayTime() ? 'Day Time' : 'Night Time',
                            style: AppTextStyle.size(16)
                                .medium
                                .withColor(AppColorToken.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              20.horizontalSpace,
              Expanded(
                flex: 3,
                child: Column(
                  children: _buildPopularDatesList(datesToShow),
                ),
              ),
            ],
          ),
          24.verticalSpace,

          // Choose Date Button - Only show if user doesn't have an active strike
          if (strikeState.userStrike == null)
            AppButton(
              text: 'Choose Date',
              onPressed: () {
                setState(() {
                  // Set initial selected date
                  if (showDate != null) {
                    selectedDate = showDate;
                  } else {
                    selectedDate = DateTime.now();
                  }
                  showCalendar = true;
                });
              },
            ),
        ],
      ),
    );
  }

  // Helper to determine if it's day time
  bool _isDayTime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18; // 6am to 6pm
  }

  // Calculate progress based on date distribution
  double _calculateProgressFromDates(List<StrikeCountResult> dates) {
    if (dates.isEmpty) {
      return 0.6; // Default if no data
    }

    // Get total participants across all dates
    final totalParticipants =
        dates.fold<int>(0, (sum, result) => sum + result.totalCount);

    if (totalParticipants == 0) {
      return 0.6; // Default if no participants
    }

    // Use the ratio of most popular date to total participants
    final mostPopular = dates[0].totalCount;

    return mostPopular / totalParticipants;
  }

  List<Widget> _buildPopularDatesList(List<StrikeCountResult> dates) {
    if (dates.isEmpty) {
      return [
        _buildDateDistribution('No data', 'No strikes scheduled yet'),
      ];
    }

    // Calculate total participants for percentage calculation
    final totalParticipants =
        dates.fold<int>(0, (sum, result) => sum + result.totalCount);

    return dates.map((result) {
      final percentage = totalParticipants > 0
          ? (result.totalCount / totalParticipants * 100).round()
          : 0;

      final dateText = DateFormat('MMM dd yyyy').format(result.date);

      return _buildDateDistribution(
        '$percentage % user:',
        dateText,
      );
    }).toList();
  }

  Widget _buildCalendarView(StrikeState strikeState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Strike',
            style: AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
          ),
          24.verticalSpace,
          CalendarGrid(
            selectedDate: selectedDate,
            userStrike: strikeState.userStrike,
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
              // Just update the selectedDate in the state
              ref.read(strikeNotifierProvider.notifier).selectDate(date);
            },
          ),
          24.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  onPressed: () {
                    setState(() {
                      showCalendar = false;
                    });
                  },
                  backgroundColor: Colors.grey[800],
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: 'Set Strike',
                  onPressed: () {
                    ref
                        .read(strikeNotifierProvider.notifier)
                        .scheduleStrike(selectedDate);
                    setState(() {
                      showCalendar = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.white.value,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyle.size(18).bold.withColor(AppColorToken.black),
      ),
    );
  }

  Widget _buildParticipantInfo(String label, String count) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
        ),
        Text(
          count,
          style: AppTextStyle.size(16).bold.withColor(AppColorToken.golden),
        ),
      ],
    );
  }

  Widget _buildDateDistribution(String percentage, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            percentage,
            style:
                AppTextStyle.size(16).regular.withColor(AppColorToken.golden),
          ),
          1.horizontalSpace,
          Expanded(
            child: Text(
              ' $date',
              style:
                  AppTextStyle.size(16).regular.withColor(AppColorToken.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Progress Circle Painter
class ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressCirclePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    // Draw background circle
    canvas.drawCircle(center, radius, paint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top (-90 degrees)
      progress * 2 * 3.14159, // Convert progress to radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Calendar Grid Widget
class CalendarGrid extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final StrikeModel? userStrike;

  const CalendarGrid({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.userStrike,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = selectedDate.month;
    final currentYear = selectedDate.year;

    // Get days in the month
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    // Get first day of the month
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);

    // Get weekday of the first day (1 = Monday in DateTime)
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // Adjust for Sunday as the first day of the week (0 = Sunday for the grid)
    final adjustedFirstWeekday = firstWeekdayOfMonth % 7;

    // Current date - for disabling past dates
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month and year with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: AppColorToken.white.value,
              ),
              onPressed: () {
                final previousMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month - 1,
                  1,
                );
                onDateSelected(previousMonth);
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: AppTextStyle.size(20).bold.withColor(AppColorToken.white),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: AppColorToken.white.value,
              ),
              onPressed: () {
                final nextMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month + 1,
                  1,
                );
                onDateSelected(nextMonth);
              },
            ),
          ],
        ),
        16.verticalSpace,

        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 30,
                    child: Text(
                      day,
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        12.verticalSpace,

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            // Calculate the day number
            final dayNumber = index - adjustedFirstWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(currentYear, currentMonth, dayNumber);

            // Check if this date is before today (past dates not selectable)
            final isPastDate = date.isBefore(todayDate);

            // Check if this date is the selected date
            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;

            // Check if user has a strike scheduled for this date
            final hasStrikeOnDate = userStrike != null &&
                userStrike?.date.day == date.day &&
                userStrike?.date.month == date.month &&
                userStrike?.date.year == date.year;

            return GestureDetector(
              onTap: isPastDate ? null : () => onDateSelected(date),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColorToken.white.value
                      : hasStrikeOnDate
                          ? AppColorToken.golden.value.withOpacity(0.3)
                          : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColorToken.white.value
                        : hasStrikeOnDate
                            ? AppColorToken.golden.value
                            : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayNumber.toString(),
                    style: AppTextStyle.size(14).medium.withColor(
                          isPastDate
                              ? AppColorToken.white
                              : isSelected
                                  ? AppColorToken.black
                                  : AppColorToken.white,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
