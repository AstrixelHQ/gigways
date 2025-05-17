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

class _StrikePageState extends ConsumerState<StrikePage>
    with SingleTickerProviderStateMixin {
  bool showCalendar = false;
  DateTime selectedDate = DateTime.now();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Animation controller for subtle UI effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Refresh strike data on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(strikeNotifierProvider.notifier).refreshStrikeData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

                  // Nationwide Strike Card - show if user has a strike, selected date, or there's a popular date
                  if (strikeState.userStrike != null ||
                      strikeState.selectedDate != null ||
                      strikeState.mostPopularDate != null)
                    _buildNationwideStrikeCard(strikeState),

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
        borderRadius: BorderRadius.circular(12),
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
    // Determine which date to display with clear priority order
    final DateTime displayDate;
    final String cardTitle;
    final bool isUserSelectedDate;

    if (strikeState.userStrike != null) {
      // User's scheduled strike has highest priority
      displayDate = strikeState.userStrike!.date;
      cardTitle = 'Your Scheduled Strike';
      isUserSelectedDate = true;
    } else if (strikeState.selectedDate != null) {
      // User's temporarily selected date comes next
      displayDate = strikeState.selectedDate!;
      cardTitle = 'Selected Strike Date';
      isUserSelectedDate = true;
    } else if (strikeState.mostPopularDate != null) {
      // Most popular date as fallback
      displayDate = strikeState.mostPopularDate!.date;
      cardTitle = 'Most Popular Strike Date';
      isUserSelectedDate = false;
    } else {
      // Unlikely fallback case
      displayDate = DateTime.now();
      cardTitle = 'Upcoming Strike';
      isUserSelectedDate = false;
    }

    // Format date parts
    final month = DateFormat('MMM').format(displayDate);
    final day = DateFormat('dd').format(displayDate);
    final year = DateFormat('yyyy').format(displayDate);

    // Get appropriate statistics for the displayed date
    final StrikeCountResult? statsToShow;
    if (strikeState.userStrike != null || strikeState.selectedDate != null) {
      statsToShow = strikeState.selectedDateStats;
    } else {
      statsToShow = strikeState.mostPopularDate;
    }

    final totalParticipants = statsToShow?.totalCount ?? 0;
    final stateParticipants = statsToShow?.stateCount ?? 0;

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
        boxShadow: [
          BoxShadow(
            color: AppColorToken.golden.value.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardTitle,
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
              ),
              // Day/night icon based on time
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: AppColorToken.golden.value,
                  size: 20,
                ),
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
          20.verticalSpace,

          // Start Time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColorToken.black.value.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(40),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColorToken.golden.value,
                  size: 18,
                ),
                10.horizontalSpace,
                Text(
                  'Start $startTime',
                  style: AppTextStyle.size(16)
                      .medium
                      .withColor(AppColorToken.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          24.verticalSpace,

          // Participant Information in a notice-like card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColorToken.white.value.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color: AppColorToken.golden.value,
                  size: 20,
                ),
                12.horizontalSpace,
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyle.size(15)
                          .medium
                          .withColor(AppColorToken.white),
                      children: [
                        TextSpan(
                          text: '$totalParticipants',
                          style: TextStyle(
                            color: AppColorToken.golden.value,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' participants nationwide, '),
                        TextSpan(
                          text: '$stateParticipants',
                          style: TextStyle(
                            color: AppColorToken.golden.value,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' in ${strikeState.userState}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          24.verticalSpace,

          // Buttons
          if (isUserSelectedDate && strikeState.userStrike != null) ...[
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorToken.black.value.withAlpha(120),
                  foregroundColor: AppColorToken.golden.value,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColorToken.golden.value,
                      width: 1,
                    ),
                  ),
                ),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Reschedule Strike'),
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime.now();
                    showCalendar = true;
                  });
                },
              ),
            ),
          ],

          // Join button - For popular dates not selected by user
          if (!isUserSelectedDate) ...[
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return AppButton(
                    text: 'Join This Strike',
                    onPressed: () {
                      // Schedule the strike for this date
                      ref
                          .read(strikeNotifierProvider.notifier)
                          .scheduleStrike(displayDate);
                    },
                    width: 200,
                    backgroundColor: Color.lerp(
                      AppColorToken.golden.value.withAlpha(180),
                      AppColorToken.golden.value,
                      _animationController.value,
                    ),
                  );
                },
              ),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: AppColorToken.black.value.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: AppColorToken.golden.value,
                size: 24,
              ),
              12.horizontalSpace,
              Text(
                'Schedule Strike',
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
              ),
            ],
          ),
          24.verticalSpace,

          // Statistics Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorToken.black.value.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  'Nationwide users',
                  '${strikeState.totalUsers}',
                  Icons.public,
                ),
                12.verticalSpace,
                _buildStatRow(
                  '${strikeState.userState} users',
                  '${strikeState.stateUsers}',
                  Icons.location_on_outlined,
                ),
                16.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColorToken.golden.value.withAlpha(180),
                      size: 18,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Text(
                        'Strike to unite, demand higher wages, and improve conditions!',
                        style: AppTextStyle.size(14)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          24.verticalSpace,

          // Popular Dates Section
          Text(
            'Popular Strike Dates',
            style:
                AppTextStyle.size(16).semiBold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,

          // Dates Display
          if (datesToShow.isEmpty)
            _buildEmptyDatesWidget()
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorToken.black.value.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Time of day display
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColorToken.black.value.withAlpha(100),
                          border: Border.all(
                            color: AppColorToken.golden.value.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _isDayTime()
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round,
                          color: AppColorToken.golden.value,
                          size: 16,
                        ),
                      ),
                      12.horizontalSpace,
                      Text(
                        _isDayTime() ? 'Day Time' : 'Night Time',
                        style: AppTextStyle.size(14)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                      const Spacer(),
                      Text(
                        'State %',
                        style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(150),
                            ),
                      ),
                    ],
                  ),
                  20.verticalSpace,

                  // Date list
                  ...datesToShow
                      .map((result) => _buildDateCard(
                            result,
                            isTopChoice: datesToShow.indexOf(result) == 0,
                            totalStateParticipants: datesToShow.fold<int>(
                                0, (sum, item) => sum + item.stateCount),
                            datesToShow: datesToShow,
                          ))
                      .toList(),
                ],
              ),
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
              leading: const Icon(Icons.calendar_today, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDatesWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.white.value.withAlpha(20),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: AppColorToken.white.value.withAlpha(100),
              size: 40,
            ),
            16.verticalSpace,
            Text(
              'No strike dates scheduled yet',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              'Be the first to schedule a strike date!',
              style: AppTextStyle.size(14).regular.withColor(
                    AppColorToken.white..color.withAlpha(150),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColorToken.golden.value.withAlpha(180),
          size: 18,
        ),
        10.horizontalSpace,
        Text(
          '$label:',
          style: AppTextStyle.size(14).regular.withColor(AppColorToken.white),
        ),
        8.horizontalSpace,
        Text(
          value,
          style: AppTextStyle.size(14).semiBold.withColor(AppColorToken.golden),
        ),
      ],
    );
  }

  Widget _buildDateCard(StrikeCountResult result,
      {required bool isTopChoice,
      required int totalStateParticipants,
      required List<StrikeCountResult> datesToShow}) {
    final statePercentage = totalStateParticipants > 0
        ? (result.stateCount / totalStateParticipants * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isTopChoice
            ? AppColorToken.golden.value.withAlpha(40)
            : AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTopChoice
              ? AppColorToken.golden.value.withAlpha(100)
              : AppColorToken.white.value.withAlpha(20),
        ),
      ),
      child: Row(
        children: [
          if (isTopChoice)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColorToken.golden.value.withAlpha(70),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: AppColorToken.golden.value,
                size: 16,
              ),
            )
          else
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Text(
                '${datesToShow.indexOf(result) + 1}',
                style: AppTextStyle.size(14).medium.withColor(
                      AppColorToken.white..color.withAlpha(150),
                    ),
              ),
            ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(result.date),
                  style: AppTextStyle.size(15).medium.withColor(
                        isTopChoice
                            ? AppColorToken.golden
                            : AppColorToken.white,
                      ),
                ),
                if (result.stateCount > 0 || result.totalCount > 0) ...[
                  6.verticalSpace,
                  Text(
                    '${result.stateCount} in state, ${result.totalCount} nationwide',
                    style: AppTextStyle.size(12).regular.withColor(
                          AppColorToken.white..color.withAlpha(150),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorToken.black.value.withAlpha(100),
            ),
            child: Center(
              child: Text(
                '$statePercentage%',
                style: AppTextStyle.size(12).bold.withColor(
                      isTopChoice ? AppColorToken.golden : AppColorToken.white,
                    ),
              ),
            ),
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

  Widget _buildCalendarView(StrikeState strikeState) {
    final isRescheduling = strikeState.userStrike != null;

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
            isRescheduling ? 'Reschedule Strike' : 'Schedule Strike',
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
                  text: isRescheduling ? 'Reschedule' : 'Set Strike',
                  onPressed: () {
                    if (isRescheduling) {
                      ref
                          .read(strikeNotifierProvider.notifier)
                          .rescheduleStrike(selectedDate);
                    } else {
                      ref
                          .read(strikeNotifierProvider.notifier)
                          .scheduleStrike(selectedDate);
                    }
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
        boxShadow: [
          BoxShadow(
            color: AppColorToken.black.value.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyle.size(18).bold.withColor(AppColorToken.black),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month and year with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColorToken.golden.value,
                  ),
                  onPressed: () {
                    final previousMonth = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                    onDateSelected(previousMonth);
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style:
                    AppTextStyle.size(18).bold.withColor(AppColorToken.white),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColorToken.golden.value,
                  ),
                  onPressed: () {
                    final nextMonth = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                    onDateSelected(nextMonth);
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
          20.verticalSpace,

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
          16.verticalSpace,

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

              // Check if this date is today
              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

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
                            : isToday
                                ? AppColorToken.golden.value.withOpacity(0.1)
                                : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColorToken.white.value
                          : hasStrikeOnDate
                              ? AppColorToken.golden.value
                              : isToday
                                  ? AppColorToken.golden.value.withAlpha(100)
                                  : Colors.transparent,
                      width: isToday || hasStrikeOnDate ? 1 : 0,
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
      ),
    );
  }
}
