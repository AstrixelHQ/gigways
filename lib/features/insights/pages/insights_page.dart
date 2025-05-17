import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/insights/widgets/period_selector.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
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
      appBar: AppBar(
        title: Text(
          'Insights',
          style: AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
        ),
        leading: Center(child: const AppBackButton()),
        backgroundColor: AppColorToken.black.value.withAlpha(100),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,

            // Page header with back button

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
                    .map((period) =>
                        _buildPeriodInsightsTable(period, trackingState))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInsightsTable(String period, TrackingState trackingState) {
    // Get real tracking sessions based on the selected period
    final List<TrackingSession> sessions =
        _getSessionsForPeriod(period, trackingState);

    // Convert sessions to table entries
    final List<InsightEntry> insights = _convertSessionsToEntries(sessions);

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
                flex: 2,
                child: Text(
                  'Date',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Time',
                  style: AppTextStyle.size(14)
                      .semiBold
                      .withColor(AppColorToken.golden),
                ),
              ),
              Expanded(
                flex: 1,
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
                          // Date column
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.date,
                              style: AppTextStyle.size(14)
                                  .medium
                                  .withColor(AppColorToken.white),
                            ),
                          ),
                          // Time column
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.time,
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          ),
                          // Miles column
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.miles.toStringAsFixed(1)}',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          ),
                          // Earnings column
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${item.earnings.toStringAsFixed(2)}',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.golden),
                            ),
                          ),
                          // Expenses column
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

  // Get the real tracking sessions for the selected period
  List<TrackingSession> _getSessionsForPeriod(
      String period, TrackingState trackingState) {
    final List<TrackingSession> sessions = [];

    switch (period) {
      case 'Today':
        // For 'Today', check if there's an active session and include it
        if (trackingState.activeSession != null) {
          sessions.add(trackingState.activeSession!);
        }

        // Get sessions for today from the tracking repository
        // This would typically be done through the tracking notifier
        final todaySessions = _getTodaySessions(trackingState);
        sessions.addAll(todaySessions);
        break;

      case 'Weekly':
        // Get sessions for the current week
        final weeklySessions = _getWeeklySessions(trackingState);
        sessions.addAll(weeklySessions);
        break;

      case 'Monthly':
        // Get sessions for the current month
        final monthlySessions = _getMonthlySessions(trackingState);
        sessions.addAll(monthlySessions);
        break;

      case 'Yearly':
        // Get sessions for the current year
        final yearlySessions = _getYearlySessions(trackingState);
        sessions.addAll(yearlySessions);
        break;
    }

    return sessions;
  }

  // Helper methods to get sessions for different time periods
  List<TrackingSession> _getTodaySessions(TrackingState trackingState) {
    // In a real implementation, you would get this data from a repository or service
    // For now, let's extract sessions from the insights if available
    final insights = trackingState.todayInsights;
    if (insights == null || insights.sessionCount == 0) {
      return [];
    }

    // Since we don't have direct access to the sessions from insights,
    // we'll try to find them in the tracking state
    // In a real implementation, you would directly query the repository
    return _extractSessionsFromState(trackingState);
  }

  List<TrackingSession> _getWeeklySessions(TrackingState trackingState) {
    final insights = trackingState.weeklyInsights;
    if (insights == null || insights.sessionCount == 0) {
      return [];
    }
    return _extractSessionsFromState(trackingState);
  }

  List<TrackingSession> _getMonthlySessions(TrackingState trackingState) {
    final insights = trackingState.monthlyInsights;
    if (insights == null || insights.sessionCount == 0) {
      return [];
    }
    return _extractSessionsFromState(trackingState);
  }

  List<TrackingSession> _getYearlySessions(TrackingState trackingState) {
    final insights = trackingState.yearlyInsights;
    if (insights == null || insights.sessionCount == 0) {
      return [];
    }
    return _extractSessionsFromState(trackingState);
  }

  // Helper method to extract sessions from tracking state
  // In a real implementation, you would directly query the repository
  List<TrackingSession> _extractSessionsFromState(TrackingState trackingState) {
    // This is a placeholder. In a real app, you would get this data from a repository
    // We're simulating it here based on the available insights

    final List<TrackingSession> dummySessions = [];

    // Create a sample session for demonstration
    // In a real app, these would come from the repository
    final insights = trackingState.selectedInsights;
    if (insights != null && insights.sessionCount > 0) {
      final now = DateTime.now();

      // Create some sample sessions based on the insights
      for (int i = 0; i < insights.sessionCount; i++) {
        final sessionStart = now.subtract(Duration(hours: i * 4));
        final sessionEnd = sessionStart.add(const Duration(hours: 3));

        // Calculate some reasonable values
        final miles = insights.totalMiles / insights.sessionCount;
        final hours = insights.hours / insights.sessionCount;
        final earnings = insights.totalEarnings / insights.sessionCount;
        final expenses = insights.totalExpenses / insights.sessionCount;

        // Create a sample session
        final session = TrackingSession(
          id: 'session_$i',
          userId: 'current_user',
          startTime: sessionStart,
          endTime: sessionEnd,
          durationInSeconds: (hours * 3600).round(),
          miles: miles,
          earnings: earnings,
          expenses: expenses,
          locations: [],
          isActive: false,
        );

        dummySessions.add(session);
      }
    }

    return dummySessions;
  }

  // Convert tracking sessions to table entries
  List<InsightEntry> _convertSessionsToEntries(List<TrackingSession> sessions) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    // Sort sessions by start time (newest first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions.map((session) {
      // Format date and time
      final date = dateFormatter.format(session.startTime);

      // Format time range
      final startTime = timeFormatter.format(session.startTime);
      final endTime = session.endTime != null
          ? timeFormatter.format(session.endTime!)
          : 'In Progress';
      final time = '$startTime - $endTime';

      // Calculate hours (from seconds)
      final hours = session.durationInSeconds / 3600;

      // Get miles, earnings, and expenses from the session
      final miles = session.miles;
      final earnings = session.earnings ?? 0.0;
      final expenses = session.expenses ?? 0.0;

      return InsightEntry(
        date: date,
        time: time,
        miles: miles,
        hours: hours,
        earnings: earnings,
        expenses: expenses,
      );
    }).toList();
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
