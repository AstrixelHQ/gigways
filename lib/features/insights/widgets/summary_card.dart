import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/insights/models/insight_summaries.dart';

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final VoidCallback? onTap;

  const WeeklySummaryCard({
    Key? key,
    required this.summary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(30),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header with week info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorToken.black.value.withAlpha(100),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week ${summary.weekNumber}',
                        style: AppTextStyle.size(16)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                      4.verticalSpace,
                      Text(
                        summary.dateRange,
                        style: AppTextStyle.size(14).regular.withColor(
                            AppColorToken.white..color.withAlpha(180)),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColorToken.golden.value.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.sessionCount} sessions',
                      style: AppTextStyle.size(12)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
            ),

            // Stats grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.directions_car_outlined,
                          value: '${summary.totalMiles.toStringAsFixed(1)} mi',
                          label: 'Miles',
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.access_time_outlined,
                          value: '${summary.totalHours.toStringAsFixed(1)} hrs',
                          label: 'Hours',
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.arrow_upward,
                          value:
                              '\$${summary.totalEarnings.toStringAsFixed(2)}',
                          label: 'Earnings',
                          valueColor: AppColorToken.green.value,
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.arrow_downward,
                          value:
                              '\$${summary.totalExpenses.toStringAsFixed(2)}',
                          label: 'Expenses',
                          valueColor: AppColorToken.red.value,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Net earnings footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColorToken.golden.value.withAlpha(10),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Earnings',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                  Text(
                    '\$${summary.netEarnings.toStringAsFixed(2)}',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: valueColor ?? AppColorToken.golden.value,
                size: 16,
              ),
              8.horizontalSpace,
              Text(
                label,
                style: AppTextStyle.size(12)
                    .regular
                    .withColor(AppColorToken.white..color.withAlpha(150)),
              ),
            ],
          ),
          8.verticalSpace,
          Text(
            value,
            style: AppTextStyle.size(16).bold.withColor(valueColor != null
                ? valueColor.toToken()
                : AppColorToken.white),
          ),
        ],
      ),
    );
  }
}

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final VoidCallback? onTap;

  const MonthlySummaryCard({
    Key? key,
    required this.summary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(30),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header with month info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorToken.black.value.withAlpha(100),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.monthName,
                        style: AppTextStyle.size(16)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                      4.verticalSpace,
                      Text(
                        summary.year.toString(),
                        style: AppTextStyle.size(14).regular.withColor(
                            AppColorToken.white..color.withAlpha(180)),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColorToken.golden.value.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.sessionCount} sessions',
                      style: AppTextStyle.size(12)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
            ),

            // Stats grid - Same as weekly
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.directions_car_outlined,
                          value: '${summary.totalMiles.toStringAsFixed(1)} mi',
                          label: 'Miles',
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.access_time_outlined,
                          value: '${summary.totalHours.toStringAsFixed(1)} hrs',
                          label: 'Hours',
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.arrow_upward,
                          value:
                              '\$${summary.totalEarnings.toStringAsFixed(2)}',
                          label: 'Earnings',
                          valueColor: AppColorToken.green.value,
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.arrow_downward,
                          value:
                              '\$${summary.totalExpenses.toStringAsFixed(2)}',
                          label: 'Expenses',
                          valueColor: AppColorToken.red.value,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Net earnings footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColorToken.golden.value.withAlpha(10),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Earnings',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                  Text(
                    '\$${summary.netEarnings.toStringAsFixed(2)}',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: valueColor ?? AppColorToken.golden.value,
                size: 16,
              ),
              8.horizontalSpace,
              Text(
                label,
                style: AppTextStyle.size(12)
                    .regular
                    .withColor(AppColorToken.white..color.withAlpha(150)),
              ),
            ],
          ),
          8.verticalSpace,
          Text(
            value,
            style: AppTextStyle.size(16).bold.withColor(valueColor != null
                ? valueColor.toToken()
                : AppColorToken.white),
          ),
        ],
      ),
    );
  }
}

// Dotted line connector widget
class DottedLineConnector extends StatelessWidget {
  final double height;
  final Color? color;

  const DottedLineConnector({
    Key? key,
    this.height = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 2,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: CustomPaint(
        painter: DottedLinePainter(
          color: color ?? AppColorToken.golden.value.withAlpha(50),
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashHeight = 5;
    const dashSpace = 5;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
