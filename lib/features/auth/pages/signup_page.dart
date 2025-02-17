import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/app_text_field.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/core/widgets/social_button.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  static const String path = '/signup';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.verticalSpace,
                // Back Button
                AppBackButton(),
                32.verticalSpace,

                // Header Section
                Text(
                  'Create Account',
                  style:
                      AppTextStyle.size(32).bold.withColor(AppColorToken.white),
                ),
                8.verticalSpace,
                Text(
                  'Please fill in the details to get started',
                  style: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white..color.withOpacity(0.7)),
                ),
                40.verticalSpace,

                // Form Fields
                AppTextField(
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                ),
                16.verticalSpace,

                AppTextField(
                  label: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                16.verticalSpace,

                AppTextField(
                  label: 'Password',
                  hintText: 'Create a strong password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                16.verticalSpace,

                AppTextField(
                  label: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                24.verticalSpace,

                // Terms and Conditions
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: false,
                        onChanged: (value) {
                          // Handle checkbox
                        },
                        side: BorderSide(
                          color: AppColorToken.white.color.withOpacity(0.7),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyle.size(14)
                              .regular
                              .withColor(AppColorToken.white),
                          children: [
                            const TextSpan(
                              text: 'I agree to the ',
                            ),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: AppTextStyle.size(14)
                                  .medium
                                  .withColor(AppColorToken.golden),
                              // Add gesture detector for terms
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                40.verticalSpace,

                // Signup Button
                AppButton(
                  text: 'Create Account',
                  onPressed: () {
                    // Handle signup
                  },
                ),
                24.verticalSpace,

                // Social Login Options
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Colors.white30),
                    ),
                    24.horizontalSpace,
                    Text(
                      'Or sign up with',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white..color.withAlpha(70)),
                    ),
                    24.horizontalSpace,
                    const Expanded(
                      child: Divider(color: Colors.white30),
                    ),
                  ],
                ),
                24.verticalSpace,

                // Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: Assets.svg.google.path,
                      onPressed: () {
                        // Handle Google signup
                      },
                    ),
                    16.horizontalSpace,
                    SocialButton(
                      icon: Assets.svg.apple.path,
                      onPressed: () {
                        // Handle Apple signup
                      },
                    ),
                  ],
                ),
                32.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
