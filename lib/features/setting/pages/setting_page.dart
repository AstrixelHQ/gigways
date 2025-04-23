import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String path = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(authNotifierProvider).userData;
    final size = MediaQuery.of(context).size;

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
              child: Text(
                'Setting',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    32.verticalSpace,

                    // App Logo
                    Center(
                      child: Column(
                        children: [
                          GradientAvatar(
                            name: userData?.fullName ?? '',
                            imageUrl: userData?.profileImageUrl,
                            size: 120,
                          ),
                          16.verticalSpace,
                          Text(
                            userData?.fullName ?? '',
                            style: AppTextStyle.size(26)
                                .bold
                                .withColor(AppColorToken.white),
                          ),
                          4.verticalSpace,
                          Text(
                            userData?.email ?? 'email@example.com',
                            style: AppTextStyle.size(14).regular.withColor(
                                AppColorToken.white..color.withAlpha(70)),
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
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: AppButton(
                        text: 'SIGN OUT',
                        width: size.width * 0.4,
                        height: 50,
                        onPressed: () => _showLogoutConfirmation(context, ref),
                        backgroundColor: AppColorToken.golden.value,
                        textColor: AppColorToken.black.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSettingsItems(BuildContext context) {
    final items = [
      (Icons.person_outline, 'Update Profile'),
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
            if (item.$2 == 'Update Profile') {
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
              Share.share('Check out GigWays App');
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

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyle.size(20).bold.withColor(AppColorToken.white),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'Cancel',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'Logout',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
              SplashRoute().go(context);
            },
          ),
        ],
      ),
    );
  }
}
