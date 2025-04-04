import 'package:flutter/material.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Widget? loadingWidget;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ??
                  AppColorToken.lightDark.color.withOpacity(0.9),
              child: Center(
                child: Assets.lottie.loading.lottie(

                ),
              ),
            ),
          ),
      ],
    );
  }
}
