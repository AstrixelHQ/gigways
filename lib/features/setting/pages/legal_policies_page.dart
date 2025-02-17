import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/app_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/widgets.dart';
import 'package:gigways/features/setting/widgets/widgets.dart';

class LegalPoliciesPage extends ConsumerStatefulWidget {
  const LegalPoliciesPage({super.key});

  static const String path = '/legal-policies';

  @override
  ConsumerState<LegalPoliciesPage> createState() => _LegalPoliciesPageState();
}

class _LegalPoliciesPageState extends ConsumerState<LegalPoliciesPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          children: [
            16.verticalSpace,
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    'Legal & Policies',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // Policies List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstant.policies.length,
                separatorBuilder: (context, index) => 16.verticalSpace,
                itemBuilder: (context, index) {
                  return PolicyItemTile(policy: AppConstant.policies[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


