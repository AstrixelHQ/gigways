import 'package:flutter/material.dart';
import 'package:gigways/core/theme/app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static const _baseStyle = TextStyle();

  static TextStyle size(double fontSize) {
    return _baseStyle.copyWith(fontSize: fontSize);
  }
}

// Weight extensions
extension TextStyleWeightExtension on TextStyle {
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}

// Color extension using enum
extension TextStyleColorExtension on TextStyle {
  TextStyle withColor(AppColorToken token) => copyWith(color: token.color);
}

// Dynamic color builder
class TextStyleBuilder {
  final TextStyle _style;

  TextStyleBuilder(this._style);

  TextStyle call(AppColorToken token) => _style.withColor(token);
}

// Usage extension
extension TextStyleUsageExtension on TextStyle {
  TextStyleBuilder get color => TextStyleBuilder(this);
}
