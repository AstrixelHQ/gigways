import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String path = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.verticalSpace,
                // Header with Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(70)),
                        ),
                        4.verticalSpace,
                        Text(
                          'John Doe',
                          style: AppTextStyle.size(24)
                              .bold
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorToken.golden.value,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: AppColorToken.golden.value,
                        ),
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,

                // Today's Insight Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColorToken.golden.value.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header with Time Range
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Today\'s Insight',
                                  style: AppTextStyle.size(20)
                                      .bold
                                      .withColor(AppColorToken.golden),
                                ),
                                Icon(
                                  Icons.wb_sunny_outlined,
                                  color: AppColorToken.golden.value,
                                ),
                              ],
                            ),
                            16.verticalSpace,
                            Row(
                              children: [
                                _buildTimeBox('Start', '7 AM'),
                                16.horizontalSpace,
                                Text(
                                  '-',
                                  style: AppTextStyle.size(20)
                                      .bold
                                      .withColor(AppColorToken.white),
                                ),
                                16.horizontalSpace,
                                _buildTimeBox('End', '3 PM'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Current Status
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColorToken.golden.value.withAlpha(10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Georgia:',
                                style: AppTextStyle.size(16)
                                    .medium
                                    .withColor(AppColorToken.white),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyle.size(16)
                                      .medium
                                      .withColor(AppColorToken.white),
                                  children: [
                                    TextSpan(
                                      text: '4,000',
                                      style: TextStyle(
                                        color: AppColorToken.golden.value,
                                      ),
                                    ),
                                    const TextSpan(text: ' / '),
                                    const TextSpan(text: '7,000'),
                                    const TextSpan(text: ' driving right now!'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Time Slots Grid
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final hour = index + 5;
                            final period = hour < 12 ? 'AM' : 'PM';
                            final displayHour = hour > 12 ? hour - 12 : hour;
                            final drivers = [
                              5000,
                              5500,
                              5700,
                              5800,
                              5600,
                              5600,
                              5000,
                              5000,
                              5200,
                              5500,
                              6000,
                              6500
                            ][index];
                            return _buildTimeSlot(
                              '$displayHour $period',
                              drivers,
                            );
                          },
                        ),
                      ),

                      // Best Time Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Georgia: ',
                                  style: AppTextStyle.size(16)
                                      .medium
                                      .withColor(AppColorToken.white),
                                ),
                                Text(
                                  '5 AM',
                                  style: AppTextStyle.size(16)
                                      .bold
                                      .withColor(AppColorToken.golden),
                                ),
                                Text(
                                  ' is best time to drive!',
                                  style: AppTextStyle.size(16)
                                      .medium
                                      .withColor(AppColorToken.white),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                            Text(
                              'Always stay alert for rest and driving notifications',
                              style: AppTextStyle.size(14).regular.withColor(
                                  AppColorToken.white..color.withAlpha(70)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                // News and Ads Section
                Text(
                  'News And Ads',
                  style: AppTextStyle.size(20)
                      .bold
                      .withColor(AppColorToken.golden),
                ),
                16.verticalSpace,
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColorToken.golden.value.withAlpha(30),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: AppColorToken.golden.value,
                        ),
                        16.verticalSpace,
                        Text(
                          'Power Up Your App with Firebase Data!',
                          style: AppTextStyle.size(16)
                              .medium
                              .withColor(AppColorToken.white),
                        ),
                        8.verticalSpace,
                        Text(
                          'Firebase Official Site',
                          style: AppTextStyle.size(14)
                              .regular
                              .withColor(AppColorToken.golden),
                        ),
                      ],
                    ),
                  ),
                ),
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyle.size(12)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(70)),
          ),
          4.verticalSpace,
          Text(
            time,
            style: AppTextStyle.size(16).bold.withColor(AppColorToken.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, int drivers) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: AppTextStyle.size(14).medium.withColor(AppColorToken.white),
          ),
          Text(
            '$drivers',
            style: AppTextStyle.size(14).bold.withColor(AppColorToken.golden),
          ),
        ],
      ),
    );
  }
}
