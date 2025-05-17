import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';

class InsightsHeader extends ConsumerWidget {
  const InsightsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(authNotifierProvider).userData;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
            ),
            6.verticalSpace,
            Text(
              'Track your progress & earnings',
              style: AppTextStyle.size(14).regular.withColor(
                    AppColorToken.white..color.withAlpha(70),
                  ),
            ),
          ],
        ),
        const Spacer(),
        GradientAvatar(
          name: userData?.fullName ?? 'User',
          imageUrl: userData?.profileImageUrl,
          size: 40,
        ),
      ],
    );
  }
}