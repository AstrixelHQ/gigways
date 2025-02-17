import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/app_text_field.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  static const String path = '/forgot-password';

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
                  'Reset Password',
                  style:
                      AppTextStyle.size(32).bold.withColor(AppColorToken.white),
                ),
                8.verticalSpace,
                Text(
                  'Enter your email address to receive a password reset link',
                  style: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white..color.withOpacity(0.7)),
                ),
                48.verticalSpace,

                // Email Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColorToken.golden.value,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      size: 40,
                      color: AppColorToken.golden.value,
                    ),
                  ),
                ),
                48.verticalSpace,

                // Email Input
                AppTextField(
                  label: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                40.verticalSpace,

                // Send Reset Link Button
                AppButton(
                  text: 'Send Reset Link',
                  onPressed: () {
                    // Handle password reset
                    _showResetLinkSentDialog(context);
                  },
                ),
                32.verticalSpace,

                // Remember Password Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate back to login
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Sign in',
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

  void _showResetLinkSentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColorToken.black.value,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorToken.golden.value.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: AppColorToken.golden.value,
                ),
              ),
              24.verticalSpace,
              Text(
                'Reset Link Sent!',
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.white),
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              Text(
                'Please check your email inbox and follow the instructions to reset your password.',
                style: AppTextStyle.size(14)
                    .regular
                    .withColor(AppColorToken.white..color.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              24.verticalSpace,
              AppButton(
                text: 'OK',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
