import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/app_constant.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/routers/app_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
  });

  static const String path = '/';

  @override
  ConsumerState<SplashPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ))
      ..addListener(() {});

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60.0,
      ),
    ]).animate(_controller);

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _controller.forward();
    await Future.delayed(const Duration(seconds: 1));
    OnboardingRoute().pushReplacement(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...List.generate(
                20,
                (index) => Positioned(
                  left: (MediaQuery.of(context).size.width * (index / 20)) *
                      _opacityAnimation.value,
                  top: (MediaQuery.of(context).size.height * (index % 5 / 5)) *
                      _opacityAnimation.value,
                  child: Opacity(
                    opacity: 0.1 * _opacityAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value * (index % 2 == 0 ? 1 : -1),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColorToken.surface.value,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColorToken.surface.value,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColorToken.textPrimary.value
                                    .withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.rocket_launch,
                            size: 60,
                            color: AppColorToken.primary.value,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              AppConstant.appName,
                              style: AppTextStyle.size(28)
                                  .semiBold
                                  .withColor(AppColorToken.surface),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your next job is just a tap away',
                              style: AppTextStyle.size(16)
                                  .regular
                                  .withColor(AppColorToken.surface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
