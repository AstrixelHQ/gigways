import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/models/insight_summary_models.dart';
import 'package:gigways/features/insights/notifiers/insight_summary_notifier.dart';
import 'package:gigways/routers/app_router.dart';

final selectedInsightPeriodProvider = StateProvider<InsightPeriod>((ref) {
  return InsightPeriod.today;
});

class InsightSection extends ConsumerStatefulWidget {
  const InsightSection({Key? key}) : super(key: key);

  @override
  ConsumerState<InsightSection> createState() => _UpdatedInsightSectionState();
}

class _UpdatedInsightSectionState extends ConsumerState<InsightSection> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(insightSummaryNotifierProvider.notifier)
          .performAppOpenValidation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(insightSummaryNotifierProvider);
    final selectedPeriod = ref.watch(selectedInsightPeriodProvider);

    PeriodInsights? currentInsight;

    switch (selectedPeriod) {
      case InsightPeriod.today:
        currentInsight = summaryState.summary?.today;
        break;
      case InsightPeriod.weekly:
        currentInsight = summaryState.summary?.thisWeek;
        break;
      case InsightPeriod.monthly:
        currentInsight = summaryState.summary?.thisMonth;
        break;
      case InsightPeriod.yearly:
        currentInsight = summaryState.summary?.thisYear;
        break;
    }

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
          _buildHeader(summaryState, selectedPeriod),
          16.verticalSpace,

          // Loading state
          if (summaryState.isLoading)
            _buildLoadingState()

          // Error state with retry option
          else if (summaryState.hasError)
            _buildErrorState(summaryState)

          // Fallback indicator
          else if (summaryState.isUsingFallback)
            _buildFallbackIndicator()

          // Success state - show insights
          else if (currentInsight != null)
            _buildInsightCards(currentInsight)

          // Empty state
          else
            _buildEmptyState(),

          16.verticalSpace,
          _buildNavigationButton(summaryState),
        ],
      ),
    );
  }

  Widget _buildHeader(
      InsightSummaryState summaryState, InsightPeriod selectedPeriod) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Insights',
          style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
        ),
        Row(
          children: [
            // Period selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorToken.black.value,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColorToken.golden.value.withAlpha(30),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<InsightPeriod>(
                  value: selectedPeriod,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppColorToken.golden.value,
                  ),
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.white),
                  dropdownColor: AppColorToken.black.value,
                  isDense: true,
                  items: InsightPeriod.values.map((period) {
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
                      ref.read(selectedInsightPeriodProvider.notifier).state =
                          value;
                    }
                  },
                ),
              ),
            ),
            8.horizontalSpace,

            // Status indicator
            if (summaryState.isValidating)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColorToken.golden.color,
                  strokeWidth: 2,
                ),
              )
            else if (summaryState.hasQueuedUpdates)
              Icon(
                Icons.sync_problem,
                size: 16,
                color: Colors.orange,
              )
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColorToken.golden.color),
          8.verticalSpace,
          Text(
            'Loading insights...',
            style: AppTextStyle.size(14).regular.withColor(
                  AppColorToken.white..color.withAlpha(180),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(InsightSummaryState summaryState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              8.horizontalSpace,
              Expanded(
                child: Text(
                  'Unable to load insights',
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.white),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(insightSummaryNotifierProvider.notifier)
                        .loadSummary(force: true);
                  },
                  child: Text(
                    'Retry',
                    style: AppTextStyle.size(12)
                        .medium
                        .withColor(AppColorToken.golden),
                  ),
                ),
              ),
              if (summaryState.hasQueuedUpdates)
                TextButton(
                  onPressed: () {
                    ref
                        .read(insightSummaryNotifierProvider.notifier)
                        .retryPendingUpdates();
                  },
                  child: Text(
                    'Sync',
                    style: AppTextStyle.size(12)
                        .medium
                        .withColor(AppColorToken.orange),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 16),
          8.horizontalSpace,
          Expanded(
            child: Text(
              'Using calculated data',
              style:
                  AppTextStyle.size(12).regular.withColor(AppColorToken.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards(PeriodInsights insight) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                icon: Icons.directions_car,
                title: 'Miles',
                value: insight.totalMiles.toStringAsFixed(1),
                suffix: 'mi',
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: _buildInsightCard(
                icon: Icons.access_time_filled,
                title: 'Hours',
                value: insight.hours.toStringAsFixed(1),
                suffix: 'hrs',
              ),
            ),
          ],
        ),
        8.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                icon: Icons.attach_money,
                title: 'Earnings',
                value: '\$${insight.totalEarnings.toStringAsFixed(2)}',
                valueColor: AppColorToken.success.value,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: _buildInsightCard(
                icon: Icons.receipt_long,
                title: 'Expenses',
                value: '\$${insight.totalExpenses.toStringAsFixed(2)}',
                valueColor: AppColorToken.error.value,
              ),
            ),
          ],
        ),
      ],
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
                style: AppTextStyle.size(12).medium.withColor(
                      AppColorToken.white..color.withAlpha(70),
                    ),
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
                  style: AppTextStyle.size(12).medium.withColor(
                        AppColorToken.white..color.withAlpha(70),
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final selectedPeriod = ref.watch(selectedInsightPeriodProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorToken.golden.value.withAlpha(10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(30),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 32,
              color: AppColorToken.golden.value.withAlpha(180),
            ),
          ),
          16.verticalSpace,
          Text(
            'No ${selectedPeriod.displayName.toLowerCase()} data yet',
            style: AppTextStyle.size(16).semiBold.withColor(AppColorToken.white),
          ),
          8.verticalSpace,
          Text(
            selectedPeriod == InsightPeriod.today
                ? 'Start tracking your drive to see insights here'
                : 'Track more drives to build your ${selectedPeriod.displayName.toLowerCase()} insights',
            style: AppTextStyle.size(13).regular.withColor(
                  AppColorToken.white..color.withAlpha(150),
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          16.verticalSpace,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorToken.golden.value.withAlpha(5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorToken.golden.value.withAlpha(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColorToken.golden.value.withAlpha(180),
                ),
                8.horizontalSpace,
                Expanded(
                  child: Text(
                    'Tap the tracking button above to start your first drive',
                    style: AppTextStyle.size(12).medium.withColor(
                          AppColorToken.golden..color.withAlpha(200),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(InsightSummaryState summaryState) {
    return Center(
      child: GestureDetector(
        onTap: () => InsightsRoute().push(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              if (summaryState.hasQueuedUpdates) ...[
                6.horizontalSpace,
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
