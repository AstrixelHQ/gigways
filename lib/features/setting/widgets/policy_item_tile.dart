import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/setting/models/policy_model.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:intl/intl.dart';

class PolicyItemTile extends StatelessWidget {
  final PolicyModel policy;

  const PolicyItemTile({
    required this.policy,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PolicyDetailRoute($extra: policy).push(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(30),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorToken.golden.value.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                policy.icon,
                color: AppColorToken.golden.value,
                size: 24,
              ),
            ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: AppTextStyle.size(16)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  4.verticalSpace,
                  Text(
                    policy.description,
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(70)),
                  ),
                  8.verticalSpace,
                  Text(
                    'Last updated: ${DateFormat('MMM d, y').format(policy.lastUpdated)}',
                    style: AppTextStyle.size(12)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(50)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColorToken.golden.value,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
