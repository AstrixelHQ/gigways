import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/widgets.dart';
import 'package:gigways/features/setting/models/policy_model.dart';
import 'package:go_router/go_router.dart';

class PolicyDetailPage extends StatelessWidget {
  final PolicyModel policy;

  static const String path = '/policy-detail';

  const PolicyDetailPage({
    required this.policy,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          children: [
            16.verticalSpace,
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColorToken.golden.value,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColorToken.golden.value,
                        size: 20,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Text(
                    policy.title,
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...policy.content.map((section) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: AppTextStyle.size(18)
                              .bold
                              .withColor(AppColorToken.golden),
                        ),
                        12.verticalSpace,
                        Text(
                          section.content,
                          style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(70)),
                        ),
                        24.verticalSpace,
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
