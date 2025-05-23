import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/loading_overlay.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  static const String path = '/onboarding';

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // Listen to auth changes after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).listenToAuthChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authNotifierProvider, (previous, current) {
      if (!mounted) return;

      switch (current.state) {
        case AuthState.needsState:
          StateSelectionRoute().go(context);
          break;
        case AuthState.authenticated:
          HomeRoute().go(context);
          break;
        case AuthState.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${current.errorMessage}',
                style: AppTextStyle.size(14)
                    .regular
                    .withColor(AppColorToken.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        default:
          break;
      }
    });

    final _isLoading =
        ref.watch(authNotifierProvider).state == AuthState.loading;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: ScaffoldWrapper(
        shouldShowGradient: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                Center(
                  child: Assets.svg.logo.svg(width: 180, height: 180),
                ),
                32.verticalSpace,

                // Welcome Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome To\n',
                        style: AppTextStyle.size(32)
                            .regular
                            .withColor(AppColorToken.white),
                      ),
                      TextSpan(
                        text: 'GigWays ',
                        style: AppTextStyle.size(32)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                Text(
                  'Join our community of gig drivers',
                  style: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white..color.withAlpha(70)),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 1),

                24.verticalSpace,

                // Google and Facebook buttons in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        context: context,
                        icon: Assets.svg.google.path,
                        text: 'Google',
                        onPressed: ref
                            .read(authNotifierProvider.notifier)
                            .signInWithGoogle,
                      ),
                    ),
                    16.horizontalSpace,

                    // Facebook button
                    Expanded(
                      child: _buildSocialButton(
                        context: context,
                        icon: Assets.svg.facebook.path,
                        text: 'Facebook',
                        onPressed: ref
                            .read(authNotifierProvider.notifier)
                            .signInWithFacebook,
                        iconColor: AppColorToken.white.value,
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,

                // Apple button
                _buildSocialButton(
                  context: context,
                  icon: Assets.svg.apple.path,
                  text: 'Apple',
                  isWide: true,
                  onPressed:
                      ref.read(authNotifierProvider.notifier).signInWithApple,
                ),
                16.verticalSpace,

                // Terms text
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: AppTextStyle.size(12)
                      .regular
                      .withColor(AppColorToken.white..color.withAlpha(70)),
                  textAlign: TextAlign.center,
                ),
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String icon,
    required String text,
    required VoidCallback? onPressed,
    bool isWide = false,
    bool isLoading = false,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:
            isWide ? double.infinity : MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorToken.white.value.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColorToken.white.value,
                  ),
                ),
              )
            else
              SvgIcon(path: icon, color: iconColor),
            12.horizontalSpace,
            Text(
              text,
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
          ],
        ),
      ),
    );
  }
}

class SvgIcon extends StatelessWidget {
  final String path;
  final Color? color;

  const SvgIcon({
    super.key,
    required this.path,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(
        path,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : ColorFilter.mode(AppColorToken.white.value, BlendMode.srcIn),
      ),
    );
  }
}
