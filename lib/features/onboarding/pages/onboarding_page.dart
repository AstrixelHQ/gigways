import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
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
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome To\n',
                      style: AppTextStyle.size(36)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                    TextSpan(
                      text: 'GigWays ',
                      style: AppTextStyle.size(36)
                          .regular
                          .withColor(AppColorToken.golden),
                    ),
                    TextSpan(
                      text: 'Hero!',
                      style: AppTextStyle.size(36)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                  ],
                ),
              ),
              48.verticalSpace,

              // Logo Section
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorToken.black.value,
                ),
                child: Center(
                  child: Placeholder(
                    color: AppColorToken.white.value,
                    child: const SizedBox(
                      width: 160,
                      height: 160,
                    ),
                  ),
                ),
              ),
              48.verticalSpace,

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'We Are Not Robot.',
                    style: AppTextStyle.size(24)
                        .regular
                        .withColor(AppColorToken.golden),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColorToken.white.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Placeholder(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              AppButton(
                text: 'Get Started',
                onPressed: () {
                  SignupRoute().push(context);
                },
              ),
              23.verticalSpace,

              // Sign in Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white),
                  ),
                  GestureDetector(
                    onTap: () => LoginRoute().push(context),
                    child: Text(
                      'Sign in',
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
