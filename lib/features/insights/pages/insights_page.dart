import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/insights/widgets/chart_card.dart';
import 'package:gigways/features/insights/widgets/insights_header.dart';
import 'package:gigways/features/insights/widgets/insights_summary_card.dart';
import 'package:gigways/features/insights/widgets/period_selector.dart';
import 'package:gigways/features/insights/widgets/recent_sessions_list.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  static const String path = '/insights';

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> with SingleTickerProviderStateMixin {
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
      ref.read(trackingNotifierProvider.notifier).setInsightPeriod(selectedPeriod);
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
    
    // Get current insights
    final insights = trackingState.selectedInsights;
    
    // Get period-specific data for different views
    final List<TrackingSession> recentSessions = [];
    // TODO: In a real implementation, fetch these from repository
    
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
            
            // Main content area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _periods.map((period) => _buildPeriodContent(
                  period: period,
                  insights: insights,
                  recentSessions: recentSessions,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodContent({
    required String period,
    required TrackingInsights? insights,
    required List<TrackingSession> recentSessions,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card with key metrics
          InsightsSummaryCard(insights: insights),
          24.verticalSpace,
          
          // Earnings & Expenses Chart
          Text(
            'Earnings & Expenses',
            style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,
          ChartCard(
            insights: insights,
            chartType: ChartType.earnings,
            period: period,
          ),
          24.verticalSpace,
          
          // Miles Chart
          Text(
            'Miles Driven',
            style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,
          ChartCard(
            insights: insights,
            chartType: ChartType.miles,
            period: period,
          ),
          24.verticalSpace,
          
          // Hours Chart
          Text(
            'Hours Worked',
            style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,
          ChartCard(
            insights: insights,
            chartType: ChartType.hours,
            period: period,
          ),
          24.verticalSpace,
          
          // Recent Sessions (only show for Today and Weekly)
          if (period == 'Today' || period == 'Weekly') ...[
            Text(
              'Recent Sessions',
              style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
            ),
            16.verticalSpace,
            RecentSessionsList(sessions: recentSessions),
            40.verticalSpace,
          ],
        ],
      ),
    );
  }
}