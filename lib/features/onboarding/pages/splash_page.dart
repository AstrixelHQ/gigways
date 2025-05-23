import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/constants/app_constant.dart';
import 'package:gigways/core/extensions/snackbar_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';
import 'dart:math' show pi;

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
  bool _isNavigating = false;

  User? get user => FirebaseAuth.instance.currentUser;

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
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load user data after dependencies are set
    Future.delayed(Duration.zero, () {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).loadUserData(user);
      }
    });
  }

  Future<void> _startAnimation() async {
    if (!mounted) return;
    await _controller.forward();
  }

  void _handleNavigation(AuthState state) {
    if (!mounted) return;
    if (_isNavigating) return;
    _isNavigating = true;

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      if (user != null) {
        switch (state) {
          case AuthState.authenticated:
            HomeRoute().pushReplacement(context);
            break;
          case AuthState.unauthenticated:
            OnboardingRoute().pushReplacement(context);
            break;
          case AuthState.error:
            context.showErrorSnackbar('Something went wrong');
            OnboardingRoute().pushReplacement(context);
            break;
          default:
            OnboardingRoute().pushReplacement(context);
        }
      } else {
        OnboardingRoute().pushReplacement(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (mounted) {
        _handleNavigation(next.state);
      }
    });

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
                            color: AppColorToken.darkGrey.value,
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
                          child: Center(
                            child: Assets.svg.logo.svg(
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Transform.translate(
                      offset: Offset(
                          0,
                          _slideAnimation.value *
                              (1 - _opacityAnimation.value)),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
