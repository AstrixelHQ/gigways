import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/app_text_field.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/core/widgets/social_button.dart';
import 'package:gigways/routers/app_router.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static const String path = '/login';

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

                Text(
                  'Welcome Back!',
                  style:
                      AppTextStyle.size(32).bold.withColor(AppColorToken.white),
                ),
                8.verticalSpace,
                Text(
                  'Sign in to continue your journey',
                  style: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white..color.withAlpha(70)),
                ),
                48.verticalSpace,

                // Form Fields
                AppTextField(
                  label: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                24.verticalSpace,

                AppTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                16.verticalSpace,

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => ForgotPasswordRoute().push(context),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ),
                40.verticalSpace,

                // Login Button
                AppButton(
                  text: 'Sign In',
                  onPressed: () => VerifyEmailRoute().push(context),
                ),
                32.verticalSpace,

                // Social Login Options
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Colors.white30),
                    ),
                    24.horizontalSpace,
                    Text(
                      'Or continue with',
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
                32.verticalSpace,

                // Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: Assets.svg.google.path,
                      onPressed: () {
                        // Handle Google login
                      },
                    ),
                    16.horizontalSpace,
                    SocialButton(
                      icon: Assets.svg.apple.path,
                      onPressed: () {
                        // Handle Apple login
                      },
                    ),
                  ],
                ),
                32.verticalSpace,

                // Sign Up Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                    GestureDetector(
                      onTap: () => SignupRoute().push(context),
                      child: Text(
                        'Sign up',
                        style: AppTextStyle.size(14)
                            .medium
                            .withColor(AppColorToken.golden),
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
