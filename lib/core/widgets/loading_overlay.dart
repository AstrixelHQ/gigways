import 'package:flutter/material.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:lottie/lottie.dart';

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
              color: backgroundColor ?? Colors.grey.withOpacity(0.5),
              child: Center(
                child: Assets.lottie.loading.lottie(),
              ),
            ),
          ),
      ],
    );
  }
}
