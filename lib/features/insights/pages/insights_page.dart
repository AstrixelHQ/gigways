import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/insights/widgets/insights_header.dart';
import 'package:gigways/features/insights/widgets/period_selector.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  static const String path = '/insights';

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _periods = ['Today', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen for tab changes to update the period in the tracking notifier
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final selectedPeriod = _periods[_tabController.index];
      ref
          .read(trackingNotifierProvider.notifier)
          .setInsightPeriod(selectedPeriod);
    });

    // Refresh insights data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingNotifierProvider.notifier).refreshInsights();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingNotifierProvider);
    final selectedPeriod = trackingState.selectedInsightPeriod;

    // Set tab controller index based on selected period
    final periodIndex = _periods.indexOf(selectedPeriod);
    if (periodIndex != -1 && _tabController.index != periodIndex) {
      _tabController.animateTo(periodIndex);
    }

    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,

            // Page header with user info
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: InsightsHeader(),
            ),
            24.verticalSpace,

            // Period selector tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PeriodSelector(
                tabController: _tabController,
                periods: _periods,
              ),
            ),
            16.verticalSpace,

            // Main content area with tab view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _periods
                    .map((period) => _buildPeriodInsightsTable(period))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInsightsTable(String period) {
    // Get mock data for the selected period
    final insights = _getMockInsightsData(period);

    return Column(
      children: [
        // Table header
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                'Activity Logs',
                style:
                    AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(30),
                  ),
                ),
                child: Text(
                  '${insights.length} entries',
                  style: AppTextStyle.size(12)
                      .medium
                      .withColor(AppColorToken.white),
                ),
              ),
            ],
          ),
        ),

        // Table headers (sticky)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColorToken.black.value.withAlpha(80),
            border: Border(
              bottom: BorderSide(
                color: AppColorToken.golden.value.withAlpha(30),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Date/Time',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Miles',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Hours',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Earnings',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Expenses',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
            ],
          ),
        ),

        // Table content
        Expanded(
          child: insights.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final item = insights[index];
                    final isLastItem = index == insights.length - 1;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: isLastItem
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color:
                                      AppColorToken.white.value.withAlpha(15),
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.date,
                                  style: AppTextStyle.size(14)
                                      .medium
                                      .withColor(AppColorToken.white),
                                ),
                                Text(
                                  item.time,
                                  style:
                                      AppTextStyle.size(12).regular.withColor(
                                            AppColorToken.white
                                              ..color.withAlpha(70),
                                          ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.miles} mi',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.hours}h',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${item.earnings.toStringAsFixed(2)}',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.golden),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${item.expenses.toStringAsFixed(2)}',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.golden),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 48,
              color: AppColorToken.white.value.withAlpha(100),
            ),
            16.verticalSpace,
            Text(
              'No activity logs available',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              'Start tracking to see your activity here',
              style: AppTextStyle.size(14).regular.withColor(
                    AppColorToken.white..color.withAlpha(70),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Mock data generation for different periods
  List<InsightEntry> _getMockInsightsData(String period) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final insights = <InsightEntry>[];

    switch (period) {
      case 'Today':
        final date = dateFormatter.format(now);
        insights.add(
          InsightEntry(
            date: date,
            time: '8:00 AM - 10:30 AM',
            miles: 12.3,
            hours: 2.5,
            earnings: 85.50,
            expenses: 15.20,
          ),
        );
        insights.add(
          InsightEntry(
            date: date,
            time: '11:00 AM - 2:45 PM',
            miles: 18.6,
            hours: 3.75,
            earnings: 115.75,
            expenses: 22.30,
          ),
        );
        insights.add(
          InsightEntry(
            date: date,
            time: '3:30 PM - 6:00 PM',
            miles: 14.2,
            hours: 2.5,
            earnings: 92.00,
            expenses: 17.80,
          ),
        );
        break;

      case 'Weekly':
        for (int i = 0; i < 7; i++) {
          final day = now.subtract(Duration(days: i));
          final date = dateFormatter.format(day);

          if (i % 2 == 0) {
            // Add some variety
            insights.add(
              InsightEntry(
                date: date,
                time: '9:00 AM - 5:00 PM',
                miles: 45.0 + i * 2.5,
                hours: 8.0,
                earnings: 220.00 + i * 10.0,
                expenses: 42.50 + i * 1.5,
              ),
            );
          } else {
            // Two entries for some days
            insights.add(
              InsightEntry(
                date: date,
                time: '8:00 AM - 12:00 PM',
                miles: 22.5 + i * 1.2,
                hours: 4.0,
                earnings: 110.00 + i * 5.0,
                expenses: 21.25 + i * 0.75,
              ),
            );
            insights.add(
              InsightEntry(
                date: date,
                time: '1:00 PM - 5:00 PM',
                miles: 18.3 + i * 1.0,
                hours: 4.0,
                earnings: 95.00 + i * 4.5,
                expenses: 18.40 + i * 0.65,
              ),
            );
          }
        }
        break;

      case 'Monthly':
        for (int i = 0; i < 15; i += 2) {
          final day = now.subtract(Duration(days: i));
          final date = dateFormatter.format(day);

          insights.add(
            InsightEntry(
              date: date,
              time: 'Full Day',
              miles: 55.0 + i * 1.5,
              hours: 8.0,
              earnings: 275.00 + i * 7.5,
              expenses: 52.50 + i * 1.25,
            ),
          );
        }
        break;

      case 'Yearly':
        for (int i = 0; i < 12; i++) {
          final month = now.month - i;
          final year = now.year + (month <= 0 ? -1 : 0);
          final adjustedMonth = month <= 0 ? month + 12 : month;

          final day = DateTime(year, adjustedMonth, 15);
          final date = DateFormat('MMMM yyyy').format(day);

          insights.add(
            InsightEntry(
              date: date,
              time: 'Monthly Summary',
              miles: 950.0 + i * 25.0,
              hours: 160.0,
              earnings: 4200.00 + i * 150.0,
              expenses: 850.00 + i * 35.0,
            ),
          );
        }
        break;
    }

    return insights;
  }
}

// Simple model for insight entries
class InsightEntry {
  final String date;
  final String time;
  final double miles;
  final double hours;
  final double earnings;
  final double expenses;

  InsightEntry({
    required this.date,
    required this.time,
    required this.miles,
    required this.hours,
    required this.earnings,
    required this.expenses,
  });
}
