import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final List<TextInputFormatter> inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.inputFormatters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.size(14).medium.withColor(AppColorToken.white),
        ),
        8.verticalSpace,
        TextFormField(
          validator: validator,
          inputFormatters: inputFormatters,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: AppTextStyle.size(16)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(50)),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColorToken.golden.value,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorToken.white.value.withAlpha(30),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorToken.white.value.withAlpha(30),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorToken.golden.value,
              ),
            ),
            filled: true,
            fillColor: AppColorToken.black.value.withAlpha(30),
          ),
        ),
      ],
    );
  }
}
