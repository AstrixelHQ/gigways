import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/routers/app_router.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  static const String path = '/onboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldWrapper(
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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorToken.black.value,
                  border: Border.all(
                    color: AppColorToken.golden.value,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'GW',
                    style: AppTextStyle.size(40)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ),
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
                    TextSpan(
                      text: 'Hero',
                      style: AppTextStyle.size(32)
                          .regular
                          .withColor(AppColorToken.white),
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
                  // Google button
                  _buildSocialButton(
                    context: context,
                    icon: Assets.svg.google.path,
                    text: 'Google',
                    onPressed: () {
                      // Handle Google sign in
                      HomeRoute().go(context);
                    },
                  ),
                  16.horizontalSpace,

                  // Facebook button
                  _buildSocialButton(
                    context: context,
                    icon:
                        'assets/svg/facebook.svg', // You'll need to add this asset
                    text: 'Facebook',
                    onPressed: () {
                      // Handle Facebook sign in
                      HomeRoute().go(context);
                    },
                    iconColor: Colors.blue,
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
                onPressed: () {
                  // Handle Apple sign in
                  HomeRoute().go(context);
                },
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
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String icon,
    required String text,
    required VoidCallback onPressed,
    bool isWide = false,
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
            // Check if the icon path exists in the assets
            icon == Assets.svg.google.path || icon == Assets.svg.apple.path
                ? SvgIcon(path: icon, color: iconColor)
                : Icon(
                    Icons.facebook,
                    color: iconColor ?? AppColorToken.white.value,
                    size: 24,
                  ),
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
      child: path.contains('.svg')
          ? SvgPicture.asset(
              path,
              colorFilter: color != null
                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                  : ColorFilter.mode(
                      AppColorToken.white.value, BlendMode.srcIn),
            )
          : Icon(
              Icons.error,
              color: AppColorToken.white.value,
              size: 24,
            ),
    );
  }
}
