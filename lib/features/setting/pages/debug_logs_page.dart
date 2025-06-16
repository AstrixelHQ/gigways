import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/core/services/debug_log_service.dart';
import 'package:intl/intl.dart';

class DebugLogsPage extends ConsumerStatefulWidget {
  const DebugLogsPage({super.key});

  static const String path = '/debug-logs';

  @override
  ConsumerState<DebugLogsPage> createState() => _DebugLogsPageState();
}

class _DebugLogsPageState extends ConsumerState<DebugLogsPage> {
  LogLevel _selectedLevel = LogLevel.debug;
  LogCategory? _selectedCategory;
  int _displayLimit = 100;
  bool _isExporting = false;
  
  @override
  Widget build(BuildContext context) {
    final debugLogger = ref.read(debugLogServiceProvider);
    final logs = debugLogger.getRecentLogs(
      limit: _displayLimit,
      minLevel: _selectedLevel,
      category: _selectedCategory,
    );
    final stats = debugLogger.getLogStatistics();

    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  16.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Debug Logs',
                      style: AppTextStyle.size(24)
                          .bold
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                  _buildExportButton(debugLogger),
                ],
              ),
            ),
            16.verticalSpace,

            // Statistics
            _buildStatistics(stats),
            16.verticalSpace,

            // Filters
            _buildFilters(),
            16.verticalSpace,

            // Action buttons
            _buildActionButtons(debugLogger),
            16.verticalSpace,

            // Logs list
            Expanded(
              child: _buildLogsList(logs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(DebugLogService debugLogger) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : () => _exportLogs(debugLogger),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorToken.golden.value,
        foregroundColor: AppColorToken.black.value,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: _isExporting
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
          : const Icon(Icons.share, size: 18),
      label: Text(
        _isExporting ? 'Exporting...' : 'Export',
        style: AppTextStyle.size(14).medium.withColor(AppColorToken.black),
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTextStyle.size(16).bold.withColor(AppColorToken.golden),
          ),
          12.verticalSpace,
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatItem('Total Logs', '${stats['totalLogs']}'),
              _buildStatItem('Errors', '${stats['errorCount'] ?? 0}'),
              _buildStatItem('Warnings', '${stats['warningCount'] ?? 0}'),
              _buildStatItem('Notifications', '${stats['notificationCount'] ?? 0}'),
              _buildStatItem('Tracking', '${stats['trackingCount'] ?? 0}'),
            ],
          ),
          if (stats['sessionId'] != null) ...[
            8.verticalSpace,
            Text(
              'Session: ${stats['sessionId']?.toString().substring(0, 20)}...',
              style: AppTextStyle.size(12).regular.withColor(AppColorToken.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorToken.darkGrey.value.withAlpha(50),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyle.size(11).regular.withColor(AppColorToken.white),
          ),
          4.horizontalSpace,
          Text(
            value,
            style: AppTextStyle.size(11).medium.withColor(AppColorToken.golden),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyle.size(16).bold.withColor(AppColorToken.golden),
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level',
                      style: AppTextStyle.size(12).medium.withColor(AppColorToken.white),
                    ),
                    4.verticalSpace,
                    DropdownButtonFormField<LogLevel>(
                      value: _selectedLevel,
                      decoration: _buildDropdownDecoration(),
                      dropdownColor: AppColorToken.black.value,
                      items: LogLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(
                            level.icon,
                            style: AppTextStyle.size(12).regular.withColor(AppColorToken.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: AppTextStyle.size(12).medium.withColor(AppColorToken.white),
                    ),
                    4.verticalSpace,
                    DropdownButtonFormField<LogCategory?>(
                      value: _selectedCategory,
                      decoration: _buildDropdownDecoration(),
                      dropdownColor: AppColorToken.black.value,
                      items: [
                        const DropdownMenuItem<LogCategory?>(
                          value: null,
                          child: Text(
                            'All Categories',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        ...LogCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category.icon,
                              style: AppTextStyle.size(12).regular.withColor(AppColorToken.white),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildDropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColorToken.black.value.withAlpha(100),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColorToken.golden.value,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildActionButtons(DebugLogService debugLogger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await debugLogger.clearLogs();
                setState(() {}); // Refresh the UI
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Logs cleared successfully'),
                      backgroundColor: AppColorToken.success.value,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorToken.red.value,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                'Clear Logs',
                style: AppTextStyle.size(14).medium.withColor(AppColorToken.white),
              ),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Refresh the logs
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorToken.darkGrey.value,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Refresh',
                style: AppTextStyle.size(14).medium.withColor(AppColorToken.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: AppColorToken.white.value.withAlpha(100),
            ),
            16.verticalSpace,
            Text(
              'No logs found',
              style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              'Adjust your filters or start using the app to generate logs',
              style: AppTextStyle.size(14).regular.withColor(
                    AppColorToken.white..value.withAlpha(70),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(log.timestamp);
    
    Color levelColor;
    switch (log.level) {
      case LogLevel.debug:
        levelColor = Colors.grey;
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        break;
      case LogLevel.error:
        levelColor = Colors.red;
        break;
      case LogLevel.critical:
        levelColor = Colors.purple;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: levelColor.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level.icon,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              8.horizontalSpace,
              Text(
                log.category.icon,
                style: AppTextStyle.size(11).medium.withColor(AppColorToken.golden),
              ),
              8.horizontalSpace,
              Text(
                timeStr,
                style: AppTextStyle.size(11).regular.withColor(AppColorToken.white),
              ),
              const Spacer(),
              if (log.metadata != null && log.metadata!.isNotEmpty)
                Icon(
                  Icons.data_object,
                  size: 14,
                  color: AppColorToken.white.value.withAlpha(70),
                ),
            ],
          ),
          8.verticalSpace,
          Text(
            log.message,
            style: AppTextStyle.size(12).medium.withColor(AppColorToken.white),
          ),
          if (log.details != null) ...[
            4.verticalSpace,
            Text(
              log.details!,
              style: AppTextStyle.size(11).regular.withColor(
                    AppColorToken.white..value.withAlpha(80),
                  ),
            ),
          ],
          if (log.metadata != null && log.metadata!.isNotEmpty) ...[
            4.verticalSpace,
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorToken.darkGrey.value.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.metadata.toString(),
                style: AppTextStyle.size(10).regular.withColor(
                      AppColorToken.white..value.withAlpha(70),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportLogs(DebugLogService debugLogger) async {
    setState(() {
      _isExporting = true;
    });

    try {
      await debugLogger.shareLogs(
        timeRange: const Duration(hours: 24), // Last 24 hours
        minLevel: _selectedLevel,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logs exported and shared successfully'),
            backgroundColor: AppColorToken.success.value,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export logs: $e'),
            backgroundColor: AppColorToken.error.value,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}