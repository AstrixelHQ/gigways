import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String path = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(authNotifierProvider).userData;

    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,
            // Header
            SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Row(
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
                      // Navigate to profile update page
                      UpdateProfileRoute().push(context);
                    },
                    child: GradientAvatar(
                      name: userData?.fullName ?? 'User',
                      imageUrl: userData?.profileImageUrl,
                      size: 48,
                      isEditable: false,
                      onEdit: () {
                        UpdateProfileRoute().push(context);
                      },
                    ),
                  )
                ],
              ),
            ),
            32.verticalSpace,

            // App Logo
            Center(
              child: Column(
                children: [
                  GradientAvatar(
                    name: userData?.fullName ?? 'User',
                    imageUrl: userData?.profileImageUrl,
                    size: 60,
                  ),
                  16.verticalSpace,
                  Text(
                    userData?.fullName ?? 'User',
                    style: AppTextStyle.size(18)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  4.verticalSpace,
                  Text(
                    userData?.email ?? 'email@example.com',
                    style: AppTextStyle.size(10)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(70)),
                  ),
                ],
              ),
            ),
            40.verticalSpace,

            // Settings Menu
            ..._buildSettingsItems(context),

            // const Spacer(),

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
