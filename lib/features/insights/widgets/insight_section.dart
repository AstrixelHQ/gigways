import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/notifiers/insight_notifier.dart';
import 'package:gigways/routers/app_router.dart';

final selectedInsightProvider = StateProvider<InsightPeriod>((ref) {
  return InsightPeriod.today;
});

class InsightSection extends ConsumerStatefulWidget {
  const InsightSection({Key? key}) : super(key: key);

  @override
  ConsumerState<InsightSection> createState() => _InsightSectionState();
}

class _InsightSectionState extends ConsumerState<InsightSection> {
  @override
  void initState() {
    Future.delayed(
        Duration.zero,
        () => ref
            .read(insightNotifierProvider(InsightPeriod.today).notifier)
            .fetchInsights());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedInsight = ref.watch(selectedInsightProvider);

    ref.listen(
      selectedInsightProvider,
      (previous, next) {
        final insightProviderExists = ref.exists(insightNotifierProvider(next));
        if (!insightProviderExists) {
          ref.read(insightNotifierProvider(next).notifier).fetchInsights();
        }
      },
    );

    final insightState = ref.watch(insightNotifierProvider(selectedInsight));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Insights',
                style:
                    AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorToken.black.value,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColorToken.golden.value.withAlpha(30),
                      ),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<InsightPeriod>(
                            value: ref.watch(selectedInsightProvider),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColorToken.golden.value,
                            ),
                            style: AppTextStyle.size(14)
                                .medium
                                .withColor(AppColorToken.white),
                            dropdownColor: AppColorToken.black.value,
                            isDense: true,
                            items: InsightPeriod.values
                                .map((InsightPeriod period) {
                              return DropdownMenuItem<InsightPeriod>(
                                value: period,
                                child: Text(
                                  period.displayName,
                                  style: AppTextStyle.size(14)
                                      .medium
                                      .withColor(AppColorToken.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(selectedInsightProvider.notifier)
                                    .state = value;
                                ref
                                    .read(
                                        insightNotifierProvider(selectedInsight)
                                            .notifier)
                                    .fetchInsights();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  12.horizontalSpace,
                  if (insightState.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColorToken.golden.color,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => InsightsRoute().push(context),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColorToken.golden.value,
                      ),
                    ),
                ],
              ),
            ],
          ),
          16.verticalSpace,

          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.directions_car,
                  title: 'Miles',
                  value: (insightState.insights?.totalMiles ?? 0.0)
                      .toStringAsFixed(2),
                  suffix: 'mi',
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.access_time_filled,
                  title: 'Hours',
                  value:
                      (insightState.insights?.hours ?? 0.0).toStringAsFixed(2),
                  suffix: 'hrs',
                ),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              // Earnings
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.attach_money,
                  title: 'Earnings',
                  value:
                      '\$${insightState.insights?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
                  valueColor: AppColorToken.success.value,
                ),
              ),
              8.horizontalSpace,
              // Expenses
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.receipt_long,
                  title: 'Expenses',
                  value:
                      '\$${insightState.insights?.totalExpenses.toStringAsFixed(2) ?? '0.00'}',
                  valueColor: AppColorToken.error.value,
                ),
              ),
            ],
          ),

          // Add "See all insights" button/text
          16.verticalSpace,
          Center(
            child: GestureDetector(
              onTap: () => InsightsRoute().push(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all insights',
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                    6.horizontalSpace,
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColorToken.golden.value,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    String? suffix,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColorToken.golden.value,
                size: 16,
              ),
              8.horizontalSpace,
              Text(
                title,
                style: AppTextStyle.size(12)
                    .medium
                    .withColor(AppColorToken.white..color.withAlpha(70)),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              Text(
                value,
                style: AppTextStyle.size(18).bold.withColor(
                      valueColor != null
                          ? valueColor.toToken()
                          : AppColorToken.white,
                    ),
              ),
              if (suffix != null) ...[
                4.horizontalSpace,
                Text(
                  suffix,
                  style: AppTextStyle.size(12)
                      .medium
                      .withColor(AppColorToken.white..color.withAlpha(70)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
