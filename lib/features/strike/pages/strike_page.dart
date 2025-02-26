import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';

class StrikePage extends ConsumerStatefulWidget {
  const StrikePage({super.key});

  static const String path = '/strike';

  @override
  ConsumerState<StrikePage> createState() => _StrikePageState();
}

class _StrikePageState extends ConsumerState<StrikePage> {
  bool showCalendar = false;
  DateTime selectedDate = DateTime(2025, 2, 24);

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.verticalSpace,
                // Header with Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Home',
                      style: AppTextStyle.size(24)
                          .bold
                          .withColor(AppColorToken.golden),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorToken.golden.value,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: AppColorToken.golden.value,
                        ),
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,

                // if (!showCalendar) ...[
                //   _buildStrikeOverview(),
                // ] else ...[
                //   ,
                // ],
                _buildStrikeOverview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrikeOverview() {
    return Column(
      children: [
        // Nationwide Strike Card
        Container(
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
                    style: AppTextStyle.size(20)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: AppColorToken.golden.value,
                  ),
                ],
              ),
              24.verticalSpace,
              // Date Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDateBox('Feb'),
                  16.horizontalSpace,
                  Text(
                    '-',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  16.horizontalSpace,
                  _buildDateBox('24'),
                  16.horizontalSpace,
                  Text(
                    '-',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  16.horizontalSpace,
                  _buildDateBox('2025'),
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
                  'Start 07:00 AM',
                  style: AppTextStyle.size(16)
                      .medium
                      .withColor(AppColorToken.white),
                  textAlign: TextAlign.center,
                ),
              ),
              16.verticalSpace,
              // Participants Count
              RichText(
                text: TextSpan(
                  style: AppTextStyle.size(16)
                      .medium
                      .withColor(AppColorToken.white),
                  children: [
                    TextSpan(
                      text: '124200',
                      style: TextStyle(
                        color: AppColorToken.golden.value,
                      ),
                    ),
                    const TextSpan(text: ' out of '),
                    TextSpan(
                      text: '207000',
                      style: TextStyle(
                        color: AppColorToken.golden.value,
                      ),
                    ),
                    const TextSpan(text: ' users chose this day!'),
                  ],
                ),
              ),
              24.verticalSpace,
              // How To Strike Section
              Text(
                'How To Strike',
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
              ),
              12.verticalSpace,
              Text(
                'Stay home, relax and enjoy family time!',
                style:
                    AppTextStyle.size(16).medium.withColor(AppColorToken.white),
              ),
              8.verticalSpace,
              Text(
                'Share with others!',
                style:
                    AppTextStyle.size(16).medium.withColor(AppColorToken.white),
              ),
            ],
          ),
        ),
        24.verticalSpace,
        // Schedule Strike Section
        if (showCalendar)
          _buildCalendarView()
        else
          Container(
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
                  style: AppTextStyle.size(20)
                      .bold
                      .withColor(AppColorToken.golden),
                ),
                16.verticalSpace,
                _buildParticipantInfo('Nationwide participant', '207,000'),
                8.verticalSpace,
                _buildParticipantInfo('Georgia participant', '7,000'),
                16.verticalSpace,
                Text(
                  'Strike to unite, demand higher wages, and improve conditions!',
                  style: AppTextStyle.size(16)
                      .medium
                      .withColor(AppColorToken.white),
                ),
                24.verticalSpace,
                // Progress Circle
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
                                progress: 0.6,
                                color: AppColorToken.golden.value,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wb_sunny_outlined,
                                  color: AppColorToken.golden.value,
                                  size: 24,
                                ),
                                8.verticalSpace,
                                Text(
                                  'Day-Time',
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
                        children: [
                          _buildDateDistribution('60 % user:', 'Feb 24 2025'),
                          _buildDateDistribution('20 % user:', 'Feb 15 2025'),
                          _buildDateDistribution('20 % user:', 'Feb 20 2025'),
                        ],
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,
                // Choose Date Button
                AppButton(
                  text: 'Choose Date',
                  onPressed: () {
                    setState(() {
                      showCalendar = true;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
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
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
          24.verticalSpace,
          AppButton(
            text: 'Set Strike',
            onPressed: () {
              setState(() {
                showCalendar = false;
              });
            },
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

// Calendar Grid Widget
class CalendarGrid extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarGrid({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feb',
          style: AppTextStyle.size(24).bold.withColor(AppColorToken.white),
        ),
        16.verticalSpace,
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
            final dayNumber = index - (firstWeekdayOfMonth - 1);
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(now.year, now.month, dayNumber);
            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColorToken.white.value
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColorToken.white.value
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayNumber.toString(),
                    style: AppTextStyle.size(14).medium.withColor(
                          isSelected
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
