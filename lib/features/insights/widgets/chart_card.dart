import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

enum ChartType {
  earnings,
  miles,
  hours,
}

class ChartCard extends StatelessWidget {
  final TrackingInsights? insights;
  final ChartType chartType;
  final String period;

  const ChartCard({
    super.key,
    required this.insights,
    required this.chartType,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    // Get chart title and data based on type
    final String title;
    final dynamic value;
    final Color valueColor;
    final String changeText;
    final IconData changeIcon;
    final Color changeColor;

    switch (chartType) {
      case ChartType.earnings:
        final earnings = insights?.totalEarnings ?? 0.0;
        final expenses = insights?.totalExpenses ?? 0.0;
        final net = earnings - expenses;

        title = 'Net Earnings';
        value = '\$${net.toStringAsFixed(2)}';
        valueColor = AppColorToken.golden.value;

        // Mock percentage change (would be calculated from historical data)
        changeText = '+12%';
        changeIcon = Icons.arrow_upward;
        changeColor = Colors.green;
        break;

      case ChartType.miles:
        final miles = insights?.totalMiles.toInt() ?? 0;

        title = 'Miles';
        value = '$miles mi';
        valueColor = AppColorToken.white.value;

        // Mock percentage change
        changeText = '+8%';
        changeIcon = Icons.arrow_upward;
        changeColor = Colors.green;
        break;

      case ChartType.hours:
        final hours = insights?.hours ?? 0.0;

        title = 'Hours';
        value = '${hours.toStringAsFixed(1)}h';
        valueColor = AppColorToken.white.value;

        // Mock percentage change
        changeText = '-5%';
        changeIcon = Icons.arrow_downward;
        changeColor = Colors.red;
        break;
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
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
          // Title and Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.size(16)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                  6.verticalSpace,
                  Text(
                    value.toString(),
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(valueColor.toToken()),
                  ),
                ],
              ),
              _buildPercentageChange(changeText, changeIcon, changeColor),
            ],
          ),
          16.verticalSpace,

          // Chart
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageChange(
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          4.horizontalSpace,
          Text(
            text,
            style: AppTextStyle.size(12).medium.withColor(color.toToken()),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // In a real implementation, we'd use a proper chart library like fl_chart,
    // syncfusion_flutter_charts, or charts_flutter.
    // For now, we'll create a mockup of different chart types.

    switch (chartType) {
      case ChartType.earnings:
        return _buildEarningsChart();
      case ChartType.miles:
        return _buildMilesChart();
      case ChartType.hours:
        return _buildHoursChart();
    }
  }

  Widget _buildEarningsChart() {
    return CustomPaint(
      painter: BarChartPainter(
        barData: _getMockEarningsData(),
        barWidth: 12,
        primaryColor: AppColorToken.golden.value,
        secondaryColor: Colors.redAccent.withAlpha(150),
        showLegend: true,
        primaryLabel: 'Earnings',
        secondaryLabel: 'Expenses',
      ),
    );
  }

  Widget _buildMilesChart() {
    return CustomPaint(
      painter: LineChartPainter(
        dataPoints: _getMockMilesData(),
        lineColor: AppColorToken.golden.value,
        fillColor: AppColorToken.golden.value.withAlpha(40),
      ),
    );
  }

  Widget _buildHoursChart() {
    return CustomPaint(
      painter: BarChartPainter(
        barData: _getMockHoursData(),
        barWidth: 24,
        primaryColor: AppColorToken.white.value.withAlpha(180),
        showLegend: false,
      ),
    );
  }

  // Mock data generation methods
  List<BarData> _getMockEarningsData() {
    try {
      if (period == 'Today') {
        return [
          BarData(label: '8am', value: 15, secondaryValue: 3),
          BarData(label: '10am', value: 20, secondaryValue: 4),
          BarData(label: '12pm', value: 25, secondaryValue: 5),
          BarData(label: '2pm', value: 30, secondaryValue: 6),
          BarData(label: '4pm', value: 35, secondaryValue: 7),
          BarData(label: '6pm', value: 30, secondaryValue: 5),
        ];
      } else if (period == 'Weekly') {
        return [
          BarData(label: 'Mon', value: 70, secondaryValue: 15),
          BarData(label: 'Tue', value: 90, secondaryValue: 18),
          BarData(label: 'Wed', value: 85, secondaryValue: 17),
          BarData(label: 'Thu', value: 100, secondaryValue: 20),
          BarData(label: 'Fri', value: 120, secondaryValue: 24),
          BarData(label: 'Sat', value: 150, secondaryValue: 30),
          BarData(label: 'Sun', value: 85, secondaryValue: 17),
        ];
      } else if (period == 'Monthly') {
        return [
          BarData(label: 'Week 1', value: 380, secondaryValue: 80),
          BarData(label: 'Week 2', value: 450, secondaryValue: 95),
          BarData(label: 'Week 3', value: 500, secondaryValue: 105),
          BarData(label: 'Week 4', value: 420, secondaryValue: 85),
        ];
      } else {
        return [
          BarData(label: 'Jan', value: 1200, secondaryValue: 250),
          BarData(label: 'Feb', value: 1300, secondaryValue: 260),
          BarData(label: 'Mar', value: 1400, secondaryValue: 280),
          BarData(label: 'Apr', value: 1500, secondaryValue: 300),
          BarData(label: 'May', value: 1700, secondaryValue: 340),
          BarData(label: 'Jun', value: 1800, secondaryValue: 360),
        ];
      }
    } catch (e) {
      // Return default data if anything goes wrong
      return [
        BarData(label: 'No Data', value: 0, secondaryValue: 0),
      ];
    }
  }

  List<DataPoint> _getMockMilesData() {
    try {
      if (period == 'Today') {
        return [
          DataPoint(label: '8am', value: 10),
          DataPoint(label: '10am', value: 25),
          DataPoint(label: '12pm', value: 40),
          DataPoint(label: '2pm', value: 60),
          DataPoint(label: '4pm', value: 75),
          DataPoint(label: '6pm', value: 90),
        ];
      } else if (period == 'Weekly') {
        return [
          DataPoint(label: 'Mon', value: 45),
          DataPoint(label: 'Tue', value: 55),
          DataPoint(label: 'Wed', value: 50),
          DataPoint(label: 'Thu', value: 65),
          DataPoint(label: 'Fri', value: 70),
          DataPoint(label: 'Sat', value: 80),
          DataPoint(label: 'Sun', value: 60),
        ];
      } else if (period == 'Monthly') {
        return [
          DataPoint(label: 'Week 1', value: 220),
          DataPoint(label: 'Week 2', value: 280),
          DataPoint(label: 'Week 3', value: 310),
          DataPoint(label: 'Week 4', value: 260),
        ];
      } else {
        return [
          DataPoint(label: 'Jan', value: 950),
          DataPoint(label: 'Feb', value: 1020),
          DataPoint(label: 'Mar', value: 1100),
          DataPoint(label: 'Apr', value: 1200),
          DataPoint(label: 'May', value: 1350),
          DataPoint(label: 'Jun', value: 1450),
        ];
      }
    } catch (e) {
      // Return default data if anything goes wrong
      return [
        DataPoint(label: 'No Data', value: 0),
      ];
    }
  }

  List<BarData> _getMockHoursData() {
    try {
      if (period == 'Today') {
        return [
          BarData(label: '8am', value: 1),
          BarData(label: '10am', value: 1),
          BarData(label: '12pm', value: 1.5),
          BarData(label: '2pm', value: 2),
          BarData(label: '4pm', value: 1.5),
          BarData(label: '6pm', value: 1),
        ];
      } else if (period == 'Weekly') {
        return [
          BarData(label: 'Mon', value: 4),
          BarData(label: 'Tue', value: 5),
          BarData(label: 'Wed', value: 4.5),
          BarData(label: 'Thu', value: 6),
          BarData(label: 'Fri', value: 7),
          BarData(label: 'Sat', value: 8),
          BarData(label: 'Sun', value: 4),
        ];
      } else if (period == 'Monthly') {
        return [
          BarData(label: 'Week 1', value: 22),
          BarData(label: 'Week 2', value: 26),
          BarData(label: 'Week 3', value: 28),
          BarData(label: 'Week 4', value: 24),
        ];
      } else {
        return [
          BarData(label: 'Jan', value: 90),
          BarData(label: 'Feb', value: 95),
          BarData(label: 'Mar', value: 105),
          BarData(label: 'Apr', value: 110),
          BarData(label: 'May', value: 125),
          BarData(label: 'Jun', value: 135),
        ];
      }
    } catch (e) {
      // Return default data if anything goes wrong
      return [
        BarData(label: 'No Data', value: 0),
      ];
    }
  }
}

class DataPoint {
  final String label;
  final double value;

  DataPoint({required this.label, required this.value});
}

class BarData {
  final String label;
  final double value;
  final double? secondaryValue;

  BarData({required this.label, required this.value, this.secondaryValue});
}

// Custom painter for line charts
class LineChartPainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) {
      _drawNoDataMessage(canvas, size);
      return;
    }

    try {
      final Paint linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final Paint fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final Paint gridPaint = Paint()
        ..color = Colors.white.withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final TextStyle labelStyle = TextStyle(
        color: Colors.white.withAlpha(120),
        fontSize: 10,
      );
      final TextStyle valueStyle = TextStyle(
        color: Colors.white.withAlpha(150),
        fontSize: 10,
      );

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      // Calculate maximum value for scaling
      final maxValue = dataPoints.isNotEmpty
          ? dataPoints
              .map((point) => point.value)
              .reduce((value, element) => value > element ? value : element)
          : 0.0;

      // If maxValue is 0 (no data), set a default
      final yScale = maxValue > 0 ? maxValue : 1.0;

      // Padding for the chart
      const double paddingLeft = 40;
      const double paddingRight = 10;
      const double paddingTop = 10;
      const double paddingBottom = 30;

      // Draw grid lines
      for (int i = 0; i <= 4; i++) {
        final y =
            paddingTop + (size.height - paddingTop - paddingBottom) / 4 * i;
        canvas.drawLine(
          Offset(paddingLeft, y),
          Offset(size.width - paddingRight, y),
          gridPaint,
        );

        // Draw y-axis labels
        if (i < 4) {
          final value = yScale * (4 - i) / 4;
          textPainter.text = TextSpan(
            text: value.toInt().toString(),
            style: valueStyle,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(paddingLeft - textPainter.width - 5,
                y - textPainter.height / 2),
          );
        }
      }

      // Create line path
      final Path linePath = Path();
      final Path fillPath = Path();

      for (int i = 0; i < dataPoints.length; i++) {
        final point = dataPoints[i];
        final x = paddingLeft +
            (size.width - paddingLeft - paddingRight) *
                i /
                (dataPoints.length - 1);
        final y = paddingTop +
            (size.height - paddingTop - paddingBottom) *
                (1 - point.value / (yScale == 0 ? 1.0 : yScale));

        if (i == 0) {
          linePath.moveTo(x, y);
          fillPath.moveTo(x, size.height - paddingBottom);
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }

        // Draw x-axis labels
        textPainter.text = TextSpan(
          text: point.label,
          style: labelStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - paddingBottom + 5),
        );
      }

      // Complete fill path
      if (dataPoints.isNotEmpty) {
        fillPath.lineTo(paddingLeft + (size.width - paddingLeft - paddingRight),
            size.height - paddingBottom);
        fillPath.close();

        // Draw fill and line
        canvas.drawPath(fillPath, fillPaint);
        canvas.drawPath(linePath, linePaint);
      }
    } catch (e) {
      // If any error occurs, show the no data message
      _drawNoDataMessage(canvas, size);
    }
  }

  void _drawNoDataMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'No data available',
        style: TextStyle(
          color: Colors.white.withAlpha(150),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<BarData> barData;
  final double barWidth;
  final Color primaryColor;
  final Color? secondaryColor;
  final bool showLegend;
  final String? primaryLabel;
  final String? secondaryLabel;

  BarChartPainter({
    required this.barData,
    required this.barWidth,
    required this.primaryColor,
    this.secondaryColor,
    this.showLegend = false,
    this.primaryLabel,
    this.secondaryLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barData.isEmpty) {
      _drawNoDataMessage(canvas, size);
      return;
    }

    try {
      final Paint primaryBarPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      final Paint secondaryBarPaint = Paint()
        ..color = secondaryColor ?? primaryColor.withAlpha(70)
        ..style = PaintingStyle.fill;

      final Paint gridPaint = Paint()
        ..color = Colors.white.withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final TextStyle labelStyle = TextStyle(
        color: Colors.white.withAlpha(120),
        fontSize: 10,
      );
      final TextStyle valueStyle = TextStyle(
        color: Colors.white.withAlpha(150),
        fontSize: 10,
      );
      final TextStyle legendStyle = TextStyle(
        color: Colors.white.withAlpha(180),
        fontSize: 12,
      );

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      // Calculate maximum value for scaling (safely)
      double maxValue = 0;
      for (var data in barData) {
        if (data.value > maxValue) maxValue = data.value;
        if (data.secondaryValue != null && data.secondaryValue! > maxValue) {
          maxValue = data.secondaryValue!;
        }
      }
      // Add 20% padding or set a minimum if all values are 0
      maxValue = maxValue > 0 ? maxValue * 1.2 : 100;

      // Padding for the chart
      const double paddingLeft = 40;
      const double paddingRight = 10;
      const double paddingTop = 10;
      double paddingBottom = 30;

      // Add extra padding for legend if needed
      if (showLegend) {
        paddingBottom += 20;
      }

      // Draw grid lines
      for (int i = 0; i <= 4; i++) {
        final y =
            paddingTop + (size.height - paddingTop - paddingBottom) / 4 * i;
        canvas.drawLine(
          Offset(paddingLeft, y),
          Offset(size.width - paddingRight, y),
          gridPaint,
        );

        // Draw y-axis labels
        if (i < 4) {
          final value = maxValue * (4 - i) / 4;
          final displayValue = value >= 1000
              ? '${(value / 1000).toStringAsFixed(1)}k'
              : value.toInt().toString();

          textPainter.text = TextSpan(
            text: displayValue,
            style: valueStyle,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(paddingLeft - textPainter.width - 5,
                y - textPainter.height / 2),
          );
        }
      }

      // Draw legend if needed
      if (showLegend && primaryLabel != null) {
        // Primary legend
        final double legendY = size.height - 15;
        const double legendX = paddingLeft;

        canvas.drawRect(
          Rect.fromLTWH(legendX, legendY - 6, 12, 12),
          primaryBarPaint,
        );

        textPainter.text = TextSpan(
          text: primaryLabel!,
          style: legendStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(legendX + 16, legendY - textPainter.height / 2),
        );

        // Secondary legend if needed
        if (secondaryLabel != null && secondaryColor != null) {
          final double secondLegendX = legendX + textPainter.width + 30;

          canvas.drawRect(
            Rect.fromLTWH(secondLegendX, legendY - 6, 12, 12),
            secondaryBarPaint,
          );

          textPainter.text = TextSpan(
            text: secondaryLabel!,
            style: legendStyle,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(secondLegendX + 16, legendY - textPainter.height / 2),
          );
        }
      }

      // Calculate bar spacing
      final barSpacing =
          (size.width - paddingLeft - paddingRight) / barData.length;

      // Draw bars
      for (int i = 0; i < barData.length; i++) {
        final data = barData[i];
        final x = paddingLeft + barSpacing * i + barSpacing / 2 - barWidth / 2;

        // Primary bar
        final primaryHeight = (size.height - paddingTop - paddingBottom) *
            (data.value / maxValue);
        final primaryY = size.height - paddingBottom - primaryHeight;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, primaryY, barWidth, primaryHeight),
            const Radius.circular(4),
          ),
          primaryBarPaint,
        );

        // Secondary bar if available
        if (data.secondaryValue != null) {
          final secondaryHeight = (size.height - paddingTop - paddingBottom) *
              (data.secondaryValue! / maxValue);
          final secondaryY = size.height - paddingBottom - secondaryHeight;

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  x + barWidth + 2, secondaryY, barWidth, secondaryHeight),
              const Radius.circular(4),
            ),
            secondaryBarPaint,
          );
        }

        // X-axis label
        textPainter.text = TextSpan(
          text: data.label,
          style: labelStyle,
        );
        textPainter.layout();
        final labelX = x + barWidth / 2 - textPainter.width / 2;
        if (data.secondaryValue != null) {
          // Center between the two bars
          final labelX = x + barWidth - textPainter.width / 2 + 1;
          textPainter.paint(
            canvas,
            Offset(labelX, size.height - paddingBottom + 5),
          );
        } else {
          textPainter.paint(
            canvas,
            Offset(labelX, size.height - paddingBottom + 5),
          );
        }
      }
    } catch (e) {
      // If any error occurs, show the no data message
      _drawNoDataMessage(canvas, size);
    }
  }

  void _drawNoDataMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'No data available',
        style: TextStyle(
          color: Colors.white.withAlpha(150),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
