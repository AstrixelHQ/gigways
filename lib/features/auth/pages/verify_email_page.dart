import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/resend_otp_timer_notifier.dart';
import 'package:gigways/routers/app_router.dart';

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key});

  static const String path = '/verify-email';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerCount = ref.watch(resendTimerNotifierProvider);
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
                  'Verify Email',
                  style:
                      AppTextStyle.size(32).bold.withColor(AppColorToken.white),
                ),
                8.verticalSpace,
                RichText(
                  text: TextSpan(
                    style: AppTextStyle.size(16)
                        .regular
                        .withColor(AppColorToken.white..color.withOpacity(0.7)),
                    children: [
                      const TextSpan(
                        text: 'We\'ve sent a verification code to\n',
                      ),
                      TextSpan(
                        text: 'example@email.com',
                        style: AppTextStyle.size(16)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                    ],
                  ),
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
                      Icons.mark_email_unread_outlined,
                      size: 40,
                      color: AppColorToken.golden.value,
                    ),
                  ),
                ),
                48.verticalSpace,

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) => SizedBox(
                      width: 70,
                      height: 70,
                      child: OTPDigitField(
                        onChanged: (value) {
                          // Handle OTP input
                          if (value.isNotEmpty && index < 3) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                40.verticalSpace,

                // Verify Button
                AppButton(
                  text: 'Verify',
                  onPressed: () => StrikeRoute().push(context),
                ),
                32.verticalSpace,

                // Resend Code Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive the code? ',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                    GestureDetector(
                      onTap: timerCount == 0
                          ? () {
                              ref
                                  .read(resendTimerNotifierProvider.notifier)
                                  .startTimer();
                            }
                          : null,
                      child: Text(
                        timerCount > 0 ? 'Resend in ${timerCount}s' : 'Resend',
                        style: AppTextStyle.size(14).medium.withColor(
                              timerCount == 0
                                  ? AppColorToken.golden
                                  : AppColorToken.white
                                ..color.withOpacity(0.5),
                            ),
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

// Custom OTP Digit Input Field
class OTPDigitField extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const OTPDigitField({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      style: AppTextStyle.size(24).bold.withColor(AppColorToken.white),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      decoration: InputDecoration(
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.white.value.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.white.value.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.golden.value,
          ),
        ),
        filled: true,
        fillColor: AppColorToken.black.value.withOpacity(0.3),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
    );
  }
}
