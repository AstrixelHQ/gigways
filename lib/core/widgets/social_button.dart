import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gigways/core/theme/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColorToken.white.value.withAlpha(30),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              AppColorToken.white.value,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
