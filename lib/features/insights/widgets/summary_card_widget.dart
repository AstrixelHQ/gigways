import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/insights/models/paginated_insights.dart';

class SummaryCardWidget extends StatelessWidget {
  final SummaryCardData data;
  final bool isLast;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SummaryCardWidget({
    super.key,
    required this.data,
    this.isLast = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColorToken.black.value.withAlpha(60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(20),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  style: AppTextStyle.size(18)
                                      .bold
                                      .withColor(AppColorToken.white),
                                ),
                                4.verticalSpace,
                                Text(
                                  data.subtitle,
                                  style: AppTextStyle.size(14)
                                      .regular
                                      .withColor(AppColorToken.white..color.withAlpha(150)),
                                ),
                              ],
                            ),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                      16.verticalSpace,
                      
                      // Stats row
                      Row(
                        children: [
                          // Miles & Hours
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatRow(
                                  Icons.directions_car_outlined,
                                  '${data.totalMiles.toStringAsFixed(1)} mi',
                                  AppColorToken.golden.value,
                                ),
                                8.verticalSpace,
                                _buildStatRow(
                                  Icons.access_time_outlined,
                                  '${data.totalHours.toStringAsFixed(1)} hrs',
                                  AppColorToken.golden.value,
                                ),
                                if (data.sessionCount > 1) ...[
                                  8.verticalSpace,
                                  _buildStatRow(
                                    Icons.event_note_outlined,
                                    '${data.sessionCount} sessions',
                                    AppColorToken.white.value.withAlpha(150),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Earnings & Expenses
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatRow(
                                  Icons.arrow_upward,
                                  '\$${data.totalEarnings.toStringAsFixed(2)}',
                                  AppColorToken.green.color,
                                ),
                                8.verticalSpace,
                                _buildStatRow(
                                  Icons.arrow_downward,
                                  '\$${data.totalExpenses.toStringAsFixed(2)}',
                                  AppColorToken.red.color,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Net earnings footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(100),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Earnings:',
                        style: AppTextStyle.size(14)
                            .regular
                            .withColor(AppColorToken.white..color.withAlpha(150)),
                      ),
                      Text(
                        '\$${data.netEarnings.toStringAsFixed(2)}',
                        style: AppTextStyle.size(16)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Connection line (dotted line to next card)
        if (!isLast)
          Container(
            height: 24,
            width: 2,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomPaint(
              painter: DottedLinePainter(
                color: AppColorToken.golden.value.withAlpha(100),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        6.horizontalSpace,
        Expanded(
          child: Text(
            text,
            style: AppTextStyle.size(14)
                .regular
                .withColor(AppColorToken.white),
          ),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;

  DottedLinePainter({
    required this.color,
    this.dashHeight = 3,
    this.dashSpace = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
