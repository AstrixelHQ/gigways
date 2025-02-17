import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/assets/assets.gen.dart';
import 'package:gigways/core/constants/app_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/widgets.dart';
import 'package:gigways/features/setting/widgets/widgets.dart';

class FaqPage extends ConsumerStatefulWidget {
  const FaqPage({super.key});

  static const String path = '/faq';

  @override
  ConsumerState<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends ConsumerState<FaqPage> {
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
                  AppBackButton(),
                  16.horizontalSpace,
                  Text(
                    'FAQ',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // Lottie Animation Placeholder
            Container(
              height: 200,
              width: double.infinity,
              child: Assets.lottie.faq.lottie(),
            ),
            32.verticalSpace,

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorToken.golden.value.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  style: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white),
                  decoration: InputDecoration(
                    hintText: 'Search FAQ',
                    hintStyle: AppTextStyle.size(16)
                        .regular
                        .withColor(AppColorToken.white..color.withOpacity(0.5)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColorToken.golden.value,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
              ),
            ),
            24.verticalSpace,

            // FAQ List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstant.faq.length,
                separatorBuilder: (context, index) => 16.verticalSpace,
                itemBuilder: (context, index) {
                  return FaqItemTile(faq: AppConstant.faq[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
