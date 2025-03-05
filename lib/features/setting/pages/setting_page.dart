import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/routers/app_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String path = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.verticalSpace,
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Setting',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
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
              32.verticalSpace,

              // App Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorToken.white.value,
                  ),
                  child: Center(
                    child: Text(
                      'AB',
                      style: AppTextStyle.size(36)
                          .bold
                          .withColor(AppColorToken.black),
                    ),
                  ),
                ),
              ),
              16.verticalSpace,
              Center(
                child: Text(
                  'Aayush Bhattarai',
                  style:
                      AppTextStyle.size(24).bold.withColor(AppColorToken.white),
                ),
              ),
              40.verticalSpace,

              // Settings Menu
              ..._buildSettingsItems(context),

              const Spacer(),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: AppButton(
                  text: 'SIGN OUT',
                  onPressed: () {
                    // Handle sign out
                  },
                  backgroundColor: AppColorToken.golden.value,
                  textColor: AppColorToken.black.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSettingsItems(BuildContext context) {
    final items = [
      (Icons.person_outline, 'User Update'),
      (Icons.calendar_today_outlined, 'Update Schedule'),
      (Icons.notifications_none_outlined, 'Notification'),
      (Icons.info_outline, 'FAQ'),
      (Icons.lock_outline, 'Legal and Policies'),
      (Icons.share_outlined, 'Share with Other!'),
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: InkWell(
          onTap: () {
            // Handle navigation
            if (item.$2 == 'User Update') {
              UpdateProfileRoute().push(context);
            } else if (item.$2 == 'Update Schedule') {
              UpdateScheduleRoute().push(context);
            } else if (item.$2 == 'Notification') {
              NotificationRoute().push(context);
            } else if (item.$2 == 'FAQ') {
              FaqRoute().push(context);
            } else if (item.$2 == 'Legal and Policies') {
              LegalPoliciesRoute().push(context);
            } else if (item.$2 == 'Share with Other!') {
              // Share app
            }
          },
          child: Row(
            children: [
              Icon(
                item.$1,
                color: AppColorToken.white.value,
                size: 28,
              ),
              24.horizontalSpace,
              Text(
                item.$2,
                style:
                    AppTextStyle.size(18).medium.withColor(AppColorToken.white),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
