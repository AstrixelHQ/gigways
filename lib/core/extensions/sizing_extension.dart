import 'package:flutter/material.dart';
import '../utils/ui_utils.dart';

extension SizingExtension on num {
  // Calculate responsive value
  double get responsive => this * (UIUtils.screenWidth / 375);

  // Spacing widgets
  Widget get verticalSpace => SizedBox(height: responsive);
  Widget get horizontalSpace => SizedBox(width: responsive);
}
