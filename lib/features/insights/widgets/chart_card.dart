import 'dart:math' as math;
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
      height: 220, // Reduced height for a more compact view
      width: double.infinity, // Ensure full width
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
                    style: AppTextStyle.size(22) // Slightly smaller size
                        .bold
                        .withColor(valueColor.toToken()),
                  ),
                ],
              ),
              _buildPercentageChange(changeText, changeIcon, changeColor),
            ],
          ),
          16.verticalSpace,

          // Simplified Chart
          Expanded(
            child: _buildSimplifiedChart(),
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
            style: AppTextStyle.size(12).medium.withColor(AppColorToken.golden),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedChart() {
    // Simplified chart with better visualization
    switch (chartType) {
      case ChartType.earnings:
        return _buildSimplifiedEarningsChart();
      case ChartType.miles:
        return _buildSimplifiedMilesChart();
      case ChartType.hours:
        return _buildSimplifiedHoursChart();
    }
  }

  Widget _buildSimplifiedEarningsChart() {
    final data = _getSimplifiedEarningsData();
    
    return CustomPaint(
      size: Size.infinite,
      painter: SimplifiedBarChartPainter(
        data: data,
        primaryColor: AppColorToken.golden.value,
        secondaryColor: Colors.redAccent.withAlpha(150),
        labelColor: AppColorToken.white.value.withAlpha(130),
      ),
    );
  }

  Widget _buildSimplifiedMilesChart() {
    final data = _getSimplifiedMilesData();
    
    return CustomPaint(
      size: Size.infinite,
      painter: SimplifiedLineChartPainter(
        data: data,
        lineColor: AppColorToken.golden.value,
        fillColor: AppColorToken.golden.value.withAlpha(40),
        labelColor: AppColorToken.white.value.withAlpha(130),
      ),
    );
  }

  Widget _buildSimplifiedHoursChart() {
    final data = _getSimplifiedHoursData();
    
    return CustomPaint(
      size: Size.infinite,
      painter: SimplifiedBarChartPainter(
        data: data,
        primaryColor: AppColorToken.white.value.withAlpha(180),
        labelColor: AppColorToken.white.value.withAlpha(130),
        showSecondary: false,
      ),
    );
  }

  // Simplified data for better visualization
  List<ChartDataPoint> _getSimplifiedEarningsData() {
    final labels = period == 'Today' 
        ? ['8am', '12pm', '4pm', '8pm']
        : period == 'Weekly'
            ? ['Mon', 'Wed', 'Fri', 'Sun']
            : period == 'Monthly'
                ? ['Week 1', 'Week 2', 'Week 3', 'Week 4']
                : ['Q1', 'Q2', 'Q3', 'Q4'];
                
    return [
      ChartDataPoint(label: labels[0], primaryValue: 250, secondaryValue: 50),
      ChartDataPoint(label: labels[1], primaryValue: 450, secondaryValue: 75),
      ChartDataPoint(label: labels[2], primaryValue: 350, secondaryValue: 60),
      ChartDataPoint(label: labels[3], primaryValue: 600, secondaryValue: 90),
    ];
  }

  List<ChartDataPoint> _getSimplifiedMilesData() {
    final labels = period == 'Today' 
        ? ['8am', '12pm', '4pm', '8pm']
        : period == 'Weekly'
            ? ['Mon', 'Wed', 'Fri', 'Sun']
            : period == 'Monthly'
                ? ['Week 1', 'Week 2', 'Week 3', 'Week 4']
                : ['Q1', 'Q2', 'Q3', 'Q4'];
                
    return [
      ChartDataPoint(label: labels[0], primaryValue: 5),
      ChartDataPoint(label: labels[1], primaryValue: 12),
      ChartDataPoint(label: labels[2], primaryValue: 8),
      ChartDataPoint(label: labels[3], primaryValue: 15),
    ];
  }

  List<ChartDataPoint> _getSimplifiedHoursData() {
    final labels = period == 'Today' 
        ? ['8am', '12pm', '4pm', '8pm']
        : period == 'Weekly'
            ? ['Mon', 'Wed', 'Fri', 'Sun']
            : period == 'Monthly'
                ? ['Week 1', 'Week 2', 'Week 3', 'Week 4']
                : ['Q1', 'Q2', 'Q3', 'Q4'];
                
    return [
      ChartDataPoint(label: labels[0], primaryValue: 2),
      ChartDataPoint(label: labels[1], primaryValue: 3.5),
      ChartDataPoint(label: labels[2], primaryValue: 2.5),
      ChartDataPoint(label: labels[3], primaryValue: 4),
    ];
  }
}

class ChartDataPoint {
  final String label;
  final double primaryValue;
  final double? secondaryValue;

  ChartDataPoint({
    required this.label, 
    required this.primaryValue, 
    this.secondaryValue,
  });
}

// Simplified Bar Chart Painter
class SimplifiedBarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color primaryColor;
  final Color? secondaryColor;
  final Color labelColor;
  final bool showSecondary;

  SimplifiedBarChartPainter({
    required this.data,
    required this.primaryColor,
    this.secondaryColor,
    required this.labelColor,
    this.showSecondary = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double barWidth = size.width / (data.length * (showSecondary ? 3 : 2));
    final double maxValue = data.fold(0.0, (max, point) => 
      math.max(max, math.max(point.primaryValue, point.secondaryValue ?? 0)));
    final double scale = size.height / (maxValue * 1.2); // Add 20% padding at top

    final Paint primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final Paint secondaryPaint = Paint()
      ..color = secondaryColor ?? primaryColor.withAlpha(70)
      ..style = PaintingStyle.fill;

    final TextStyle labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      
      // Primary bar
      final double primaryHeight = point.primaryValue * scale;
      final double primaryX = i * size.width / data.length + barWidth / 2;
      final double primaryY = size.height - primaryHeight;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(primaryX, primaryY, barWidth, primaryHeight),
          const Radius.circular(4),
        ),
        primaryPaint,
      );
      
      // Secondary bar if enabled
      if (showSecondary && point.secondaryValue != null) {
        final double secondaryHeight = point.secondaryValue! * scale;
        final double secondaryX = primaryX + barWidth * 1.5;
        final double secondaryY = size.height - secondaryHeight;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(secondaryX, secondaryY, barWidth, secondaryHeight),
            const Radius.circular(4),
          ),
          secondaryPaint,
        );
      }
      
      // X-axis label
      textPainter.text = TextSpan(
        text: point.label,
        style: labelStyle,
      );
      textPainter.layout();
      
      final double labelX = i * size.width / data.length + 
          (size.width / data.length - textPainter.width) / 2;
      final double labelY = size.height - textPainter.height - 2;
      
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Simplified Line Chart Painter
class SimplifiedLineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color lineColor;
  final Color fillColor;
  final Color labelColor;

  SimplifiedLineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxValue = data.fold(0.0, (max, point) => 
      math.max(max, point.primaryValue));
    final double scale = size.height / (maxValue * 1.2); // Add 20% padding at top

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final TextStyle labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Create line and fill paths
    final Path linePath = Path();
    final Path fillPath = Path();
    
    // First point
    final double firstX = 0;
    final double firstY = size.height - (data[0].primaryValue * scale);
    
    linePath.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, size.height);
    fillPath.lineTo(firstX, firstY);
    
    // Draw points and line segments
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final double x = i * size.width / (data.length - 1);
      final double y = size.height - (point.primaryValue * scale);
      
      if (i > 0) {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      // Draw point marker
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = lineColor,
      );
      
      // X-axis label
      textPainter.text = TextSpan(
        text: point.label,
        style: labelStyle,
      );
      textPainter.layout();
      
      final double labelX = x - textPainter.width / 2;
      final double labelY = size.height - textPainter.height - 2;
      
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
    
    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
