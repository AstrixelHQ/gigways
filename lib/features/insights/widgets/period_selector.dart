import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';

class PeriodSelector extends StatelessWidget {
  final TabController tabController;
  final List<String> periods;

  const PeriodSelector({
    super.key,
    required this.tabController,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: AppColorToken.golden.value,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: AppColorToken.black.value,
        unselectedLabelColor: AppColorToken.white.value,
        labelStyle: AppTextStyle.size(14).medium,
        unselectedLabelStyle: AppTextStyle.size(14).regular,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: periods
            .map((period) => Tab(
                  text: period,
                ))
            .toList(),
      ),
    );
  }
}
