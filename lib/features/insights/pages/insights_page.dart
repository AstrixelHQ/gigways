import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/extensions/snackbar_extension.dart';
import 'package:gigways/core/services/pdf_report_service.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/insights/models/insight_entry.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/notifiers/insight_notifier.dart';
import 'package:gigways/features/insights/widgets/delete_confirmation_dialog.dart';
import 'package:gigways/features/insights/widgets/edit_entry_bottom_sheet.dart';
import 'package:gigways/features/insights/widgets/period_selector.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/notifiers/tracking_notifier.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

final selectedInsightProvider = StateProvider<InsightPeriod>((ref) {
  return InsightPeriod.today;
});

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  static const String path = '/insights';

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _periods =
      InsightPeriod.values.map((period) => period.displayName).toList();

  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final selectedPeriod = _periods[_tabController.index];
      ref.read(selectedInsightProvider.notifier).state =
          InsightPeriod.fromString(selectedPeriod);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedInsightProvider);
    final trackingState = ref.watch(trackingNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final insightState = ref.watch(insightNotifierProvider(selectedPeriod));

    // Set tab controller index based on selected period
    final periodIndex = _periods.indexOf(selectedPeriod.displayName);
    if (periodIndex != -1 && _tabController.index != periodIndex) {
      _tabController.animateTo(periodIndex);
    }

    // Check if export should be enabled
    final canExport = insightState.isSuccess &&
        insightState.sessions != null &&
        insightState.sessions!.isNotEmpty &&
        !_isExportingPdf;

    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,

            // Page header with back button and export button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  16.horizontalSpace,
                  Text(
                    'Insights',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                  const Spacer(),

                  // Export PDF Button
                  _buildExportButton(
                    canExport: canExport,
                    isLoading: _isExportingPdf,
                    onPressed: () => _handleExportPdf(selectedPeriod),
                  ),
                ],
              ),
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
                    .map((period) => _buildPeriodInsightsTable(
                        period, trackingState, selectedPeriod))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required bool canExport,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: canExport ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canExport
              ? AppColorToken.golden.value
              : AppColorToken.golden.value.withAlpha(100),
          foregroundColor: canExport
              ? AppColorToken.black.value
              : AppColorToken.black.value.withAlpha(150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: canExport ? 2 : 0,
        ),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColorToken.black.value,
                  ),
                ),
              )
            : Icon(
                Icons.file_download_outlined,
                size: 18,
              ),
        label: Text(
          'Export',
          style: AppTextStyle.size(14).medium.withColor(
                canExport ? AppColorToken.black : AppColorToken.black
                  ..color.withAlpha(150),
              ),
        ),
      ),
    );
  }

  Future<void> _handleExportPdf(InsightPeriod selectedPeriod) async {
    final insightState = ref.read(insightNotifierProvider(selectedPeriod));
    final authState = ref.read(authNotifierProvider);

    // Check if we have data and user info
    if (!insightState.isSuccess ||
        insightState.sessions == null ||
        insightState.sessions!.isEmpty ||
        authState.userData == null) {
      context.showErrorSnackbar('No data available to export');
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final pdfService = ref.read(pdfReportServiceProvider);
      final sessions = [...insightState.sessions!];
      final insights = insightState.insights!;
      final userName = authState.userData!.fullName ?? 'Unknown User';
      final userState = authState.userData!.state ?? 'Unknown State';

      final filePath = await pdfService.generateEarningsReport(
        period: selectedPeriod,
        sessions: sessions,
        insights: insights,
        userName: userName,
        userState: userState,
      );

      if (filePath != null) {
        context.showSuccessSnackbar('Report exported successfully!',
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ));
      } else {
        context.showErrorSnackbar('Failed to export report');
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      context.showErrorSnackbar('Failed to export report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Widget _buildPeriodInsightsTable(String period, TrackingState trackingState,
      InsightPeriod selectedPeriod) {
    // Get real tracking sessions based on the selected period
    final insight = ref.watch(insightNotifierProvider(selectedPeriod));
    final sessions = insight.sessions;
    final insights = _convertSessionsToEntries([...?sessions]);

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
                  '${sessions?.length ?? 0} entries',
                  style: AppTextStyle.size(12)
                      .medium
                      .withColor(AppColorToken.white),
                ),
              ),
            ],
          ),
        ),

        // Table content
        Expanded(
          child: (() {
            if (insight.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColorToken.golden.color,
                ),
              );
            } else if (sessions == null || sessions.isEmpty) {
              return _buildEmptyState();
            } else {
              return ListView.builder(
                itemCount: insights.length,
                itemBuilder: (context, index) {
                  final item = insights[index];
                  final isAlternateRow = index % 2 == 1;
                  return _buildTableRow(
                      context, item, isAlternateRow, sessions[index]);
                },
              );
            }
          })(),
        ),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, InsightEntry item,
      bool isAlternateRow, TrackingSession session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isAlternateRow
            ? AppColorToken.black.value.withAlpha(40)
            : AppColorToken.black.value.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Main row content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date and Time Column - Combined for better readability
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.date,
                        style: AppTextStyle.size(16)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                      4.verticalSpace,
                      Text(
                        item.time,
                        style: AppTextStyle.size(14).regular.withColor(
                            AppColorToken.white..color.withAlpha(180)),
                      ),
                    ],
                  ),
                ),

                // Financial details
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      // Miles + Hours column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  color: AppColorToken.golden.value,
                                  size: 14,
                                ),
                                4.horizontalSpace,
                                Text(
                                  '${item.miles.toStringAsFixed(1)} mi',
                                  style: AppTextStyle.size(14)
                                      .regular
                                      .withColor(AppColorToken.white),
                                ),
                              ],
                            ),
                            6.verticalSpace,
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_outlined,
                                  color: AppColorToken.golden.value,
                                  size: 14,
                                ),
                                4.horizontalSpace,
                                Text(
                                  '${item.hours.toStringAsFixed(1)} hrs',
                                  style: AppTextStyle.size(14)
                                      .regular
                                      .withColor(AppColorToken.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Earnings + Expenses column
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                4.horizontalSpace,
                                Text(
                                  '\$${item.earnings.toStringAsFixed(2)}',
                                  style: AppTextStyle.size(14)
                                      .medium
                                      .withColor(AppColorToken.green),
                                ),
                              ],
                            ),
                            6.verticalSpace,
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: AppColorToken.red.color,
                                  size: 14,
                                ),
                                4.horizontalSpace,
                                Text(
                                  '\$${item.expenses.toStringAsFixed(2)}',
                                  style: AppTextStyle.size(14)
                                      .medium
                                      .withColor(AppColorToken.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions column
                Container(
                  width: 38,
                  child: PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColorToken.golden.value,
                    ),
                    color: AppColorToken.black.value,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColorToken.golden.value.withAlpha(50),
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppColorToken.golden.value,
                              size: 18,
                            ),
                            8.horizontalSpace,
                            Text(
                              'Edit',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outlined,
                              color: AppColorToken.red.color,
                              size: 18,
                            ),
                            8.horizontalSpace,
                            Text(
                              'Delete',
                              style: AppTextStyle.size(14)
                                  .regular
                                  .withColor(AppColorToken.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        EditEntryBottomSheet.show(
                            context, item, session, _updateSession);
                      } else if (value == 'delete') {
                        DeleteConfirmationDialog.show(
                          context,
                          'Delete Entry',
                          'Are you sure you want to delete this entry? This action cannot be undone.',
                          onDelete: () {
                            Navigator.pop(context);

                            ref
                                .read(insightNotifierProvider(
                                        ref.read(selectedInsightProvider))
                                    .notifier)
                                .deleteInsight(session);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Net row - shows the net earnings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColorToken.black.value.withAlpha(100),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Net:',
                  style: AppTextStyle.size(14)
                      .regular
                      .withColor(AppColorToken.white..color.withAlpha(150)),
                ),
                8.horizontalSpace,
                Text(
                  '\$${(item.earnings - item.expenses).toStringAsFixed(2)}',
                  style: AppTextStyle.size(16)
                      .bold
                      .withColor(AppColorToken.golden),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the session with new values
  void _updateSession(
    TrackingSession session, {
    required double miles,
    required double hours,
    required double earnings,
    required double expenses,
  }) {
    // Convert hours to seconds
    final durationInSeconds = (hours * 3600).round();

    // Update the session in the insight notifier
    ref
        .read(
            insightNotifierProvider(ref.read(selectedInsightProvider)).notifier)
        .updateInsight(
          session,
          miles: miles,
          durationInSeconds: durationInSeconds,
          earnings: earnings,
          expenses: expenses,
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
