import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/bouncy.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    this.height = 56,
    this.width = double.infinity,
    this.disabled = false,
    this.text,
    this.loading = false,
    this.isSmallButton = false,
    this.leading,
    this.backgroundColor,
    this.textColor,
  });

  final double height;
  final double width;
  final VoidCallback onPressed;
  final bool disabled;
  final String? text;
  final bool loading;
  final bool isSmallButton;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? textColor;

  bool get isDisabled => disabled || loading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: Bouncy(
        onTap: isDisabled
            ? null
            : () {
                FocusScope.of(context).unfocus();
                onPressed();
              },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: height,
              width: loading
                  ? height // Makes it square for circle shape
                  : (isSmallButton ? height : width),
              decoration: loading
                  ? ShapeDecoration(
                      shape: const CircleBorder(),
                      color: (backgroundColor ?? const Color(0xFF2A2A2A))
                          .withOpacity(0.8),
                    )
                  : BoxDecoration(
                      color: backgroundColor ?? const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: loading
                      ? BorderRadius.circular(height)
                      : BorderRadius.circular(12),
                  onTap: isDisabled
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          onPressed();
                        },
                  splashColor: AppColorToken.white.value.withOpacity(0.1),
                  highlightColor: AppColorToken.white.value.withOpacity(0.05),
                  child: Center(
                    child: loading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                textColor ?? AppColorToken.white.value,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (leading != null) ...[
                                leading!,
                                const SizedBox(width: 8),
                              ],
                              if (text != null)
                                Text(
                                  text!,
                                  style: AppTextStyle.size(18).medium.withColor(
                                      textColor != null
                                          ? AppColorToken.fromName(
                                                      textColor.toString())
                                                  as AppColorToken? ??
                                              AppColorToken.white
                                          : AppColorToken.white),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
