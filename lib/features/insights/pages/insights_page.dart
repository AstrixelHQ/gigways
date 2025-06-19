import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/insights/models/paginated_insights.dart';
import 'package:gigways/features/insights/notifiers/paginated_insight_notifier.dart';
import 'package:gigways/features/insights/services/pdf_export_service.dart';
import 'package:gigways/features/insights/widgets/period_selector.dart';
import 'package:gigways/features/insights/widgets/summary_card_widget.dart';

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
  final Map<InsightPeriod, ScrollController> _scrollControllers = {};
  bool _isExportingPdf = false;
  bool _canExport = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize scroll controllers for each period
    for (final period in InsightPeriod.values) {
      _scrollControllers[period] = ScrollController();
      _scrollControllers[period]!.addListener(() => _onScroll(period));
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final selectedPeriod = _periods[_tabController.index];
      ref.read(selectedInsightProvider.notifier).state =
          InsightPeriod.fromString(selectedPeriod);
    });

    // Check export eligibility
    _checkExportEligibility();
  }

  void _checkExportEligibility() async {
    try {
      final pdfService = ref.read(pdfExportServiceProvider);
      final user = ref.read(authNotifierProvider).user;
      if (user != null) {
        final canExport = await pdfService.canUserExport(user.uid);
        setState(() {
          _canExport = canExport;
        });
      }
    } catch (e) {
      setState(() {
        _canExport = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll(InsightPeriod period) {
    final controller = _scrollControllers[period]!;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(paginatedInsightNotifierProvider(period).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedInsightProvider);

    // Set tab controller index based on selected period
    final periodIndex = _periods.indexOf(selectedPeriod.displayName);
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

                  // Export PDF Button - only show for yearly
                  if (selectedPeriod == InsightPeriod.yearly)
                    _buildExportButton(
                      onPressed: _canExport && !_isExportingPdf
                          ? () => _handleExportPdf(selectedPeriod)
                          : null,
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
                    .map((period) => _buildPeriodInsightsView(
                        InsightPeriod.fromString(period)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required VoidCallback? onPressed,
  }) {
    String buttonText = 'Export PDF';
    IconData buttonIcon = Icons.file_download_outlined;
    Color backgroundColor = AppColorToken.golden.value;
    Color foregroundColor = AppColorToken.black.value;

    if (_isExportingPdf) {
      buttonText = 'Exporting...';
      backgroundColor = AppColorToken.golden.value;
      foregroundColor = AppColorToken.black.value;
    } else if (!_canExport) {
      buttonText = 'Already Exported';
      buttonIcon = Icons.check_circle_outline;
      backgroundColor = AppColorToken.darkGrey.value;
      foregroundColor =
          AppColorToken.white.value; // Better contrast for dark theme
    }

    return ElevatedButton.icon(
      onPressed: !_canExport && !_isExportingPdf
          ? () => _showExportUsedInfo()
          : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      icon: _isExportingPdf
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
              buttonIcon,
              size: 18,
            ),
      label: Text(
        buttonText,
        style:
            AppTextStyle.size(14).medium.withColor(foregroundColor.toToken()),
      ),
    );
  }

  Future<void> _handleExportPdf(InsightPeriod selectedPeriod) async {
    if (!_canExport || _isExportingPdf) return;

    // Show confirmation dialog
    final shouldExport = await _showExportConfirmationDialog();
    if (!shouldExport) return;

    setState(() {
      _isExportingPdf = true;
    });

    String currentStep = 'Preparing export...';
    late ScaffoldMessengerState scaffoldMessenger;

    try {
      scaffoldMessenger = ScaffoldMessenger.of(context);
      final pdfService = ref.read(pdfExportServiceProvider);
      final currentYear = DateTime.now().year;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColorToken.black.value,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColorToken.golden.color,
                  ),
                  16.verticalSpace,
                  Text(
                    currentStep,
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Update progress steps
      void updateProgress(String step) {
        currentStep = step;
        if (mounted) {
          setState(() {});
        }
      }

      updateProgress('Fetching yearly data...');

      final result = await pdfService.exportYearlyInsights(
        year: currentYear,
        onProgress: () => updateProgress('Generating PDF...'),
      );

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isExportingPdf = false;
      });

      if (result.success && result.filePath != null) {
        // Update export eligibility
        setState(() {
          _canExport = false;
        });

        // Show success dialog
        _showSuccessDialog(result.filePath!, pdfService);
      } else {
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to export PDF'),
            backgroundColor: AppColorToken.error.value,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isExportingPdf = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: AppColorToken.error.value,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showExportUsedInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorToken.black.value,
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColorToken.golden.value,
              size: 24,
            ),
            12.horizontalSpace,
            Text(
              'Export Already Used',
              style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have already exported your yearly report for ${DateTime.now().year}.',
              style:
                  AppTextStyle.size(14).regular.withColor(AppColorToken.white),
              textAlign: TextAlign.center,
            ),
            16.verticalSpace,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorToken.orange.value.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorToken.orange.value.withAlpha(100),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColorToken.orange.value,
                    size: 20,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'You can export once per month. Next export will be available next month.',
                      style: AppTextStyle.size(12)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorToken.golden.value,
              foregroundColor: AppColorToken.black.value,
            ),
            child: Text(
              'Got it',
              style:
                  AppTextStyle.size(14).medium.withColor(AppColorToken.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExportConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColorToken.black.value,
            title: Text(
              'Export Yearly Report',
              style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will generate a PDF report for ${DateTime.now().year} containing:',
                  style: AppTextStyle.size(14)
                      .regular
                      .withColor(AppColorToken.white),
                ),
                12.verticalSpace,
                _buildFeatureBullet(
                    'Monthly breakdown of miles, hours, earnings, and expenses'),
                _buildFeatureBullet('Yearly summary with totals'),
                _buildFeatureBullet('Minimalist design for easy reading'),
                16.verticalSpace,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorToken.orange.value.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColorToken.orange.value.withAlpha(100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColorToken.orange.value,
                        size: 20,
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Text(
                          'You can only export once per month to control costs.',
                          style: AppTextStyle.size(12)
                              .regular
                              .withColor(AppColorToken.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.darkGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorToken.golden.value,
                  foregroundColor: AppColorToken.black.value,
                ),
                child: Text(
                  'Export PDF',
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.black),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style:
                AppTextStyle.size(14).regular.withColor(AppColorToken.golden),
          ),
          Expanded(
            child: Text(
              text,
              style:
                  AppTextStyle.size(12).regular.withColor(AppColorToken.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String filePath, PdfExportService pdfService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorToken.black.value,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColorToken.success.value,
              size: 24,
            ),
            12.horizontalSpace,
            Text(
              'Export Successful!',
              style:
                  AppTextStyle.size(18).bold.withColor(AppColorToken.success),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your yearly insights report has been generated successfully.',
              style:
                  AppTextStyle.size(14).regular.withColor(AppColorToken.white),
              textAlign: TextAlign.center,
            ),
            16.verticalSpace,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorToken.golden.value.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: AppColorToken.golden.value,
                    size: 20,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'gigways_insights_${DateTime.now().year}.pdf',
                      style: AppTextStyle.size(12)
                          .medium
                          .withColor(AppColorToken.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyle.size(14)
                  .medium
                  .withColor(AppColorToken.darkGrey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              pdfService.openPdf(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorToken.golden.value,
              foregroundColor: AppColorToken.black.value,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(
              'Open PDF',
              style:
                  AppTextStyle.size(14).medium.withColor(AppColorToken.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInsightsView(InsightPeriod period) {
    final controller = _scrollControllers[period]!;

    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(paginatedInsightNotifierProvider(period));

        if (state.isLoading || state.isInitial) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColorToken.golden.color,
            ),
          );
        } else if (state.isLoadingMore) {
          return _buildSuccessView(
            state.displayData ?? [],
            controller,
            true,
          );
        } else if (state.isSuccess) {
          return _buildSuccessView(
            state.displayData ?? [],
            controller,
            false,
            hasMore: state.data?.hasMore ?? false,
          );
        } else if (state.isError) {
          return _buildErrorView('Error loading insights');
        } else {
          return const Center(child: Text('Loading...'));
        }
      },
    );
  }

  Widget _buildSuccessView(
    List<SummaryCardData> displayData,
    ScrollController controller,
    bool isLoadingMore, {
    bool hasMore = false,
  }) {
    if (displayData.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(
                _getHeaderTitle(ref.watch(selectedInsightProvider)),
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
                  '${displayData.length} ${displayData.length == 1 ? 'entry' : 'entries'}',
                  style: AppTextStyle.size(12)
                      .medium
                      .withColor(AppColorToken.white),
                ),
              ),
            ],
          ),
        ),

        // Scrollable list
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount: displayData.length + (isLoadingMore || hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayData.length) {
                // Loading indicator at bottom
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColorToken.golden.color,
                    ),
                  ),
                );
              }

              final data = displayData[index];
              final isLast = index == displayData.length - 1 && !hasMore;

              return SummaryCardWidget(
                data: data,
                isLast: isLast,
                onTap: () {
                  // TODO: Add detailed view navigation
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColorToken.red.color,
            ),
            16.verticalSpace,
            Text(
              'Error loading insights',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              message,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: AppColorToken.white.value.withAlpha(100),
            ),
            16.verticalSpace,
            Text(
              'No activity data available',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              'Start tracking to see your insights here',
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

  String _getHeaderTitle(InsightPeriod period) {
    switch (period) {
      case InsightPeriod.today:
        return 'Today\'s Activity';
      case InsightPeriod.weekly:
        return 'Weekly Summary';
      case InsightPeriod.monthly:
        return 'Monthly Summary';
      case InsightPeriod.yearly:
        return 'Yearly Overview';
    }
  }
}
