import 'package:flutter/material.dart';
import 'package:gigways/features/insights/models/insight_summary_models.dart';
import 'package:gigways/features/insights/services/insight_summary_service.dart';
import 'package:gigways/features/insights/services/insight_sync_queue.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insight_error_handler.g.dart';

@Riverpod(keepAlive: true)
InsightErrorHandler insightErrorHandler(Ref ref) {
  return InsightErrorHandler(
    insightSummaryService: ref.read(insightSummaryServiceProvider),
    syncQueue: ref.read(insightSyncQueueProvider),
  );
}

class InsightErrorHandler {
  final InsightSummaryService _insightSummaryService;
  final InsightSyncQueue _syncQueue;

  InsightErrorHandler({
    required InsightSummaryService insightSummaryService,
    required InsightSyncQueue syncQueue,
  })  : _insightSummaryService = insightSummaryService,
        _syncQueue = syncQueue;

  /// Handle insight summary fetch error with all 3 strategies
  Future<InsightErrorResult> handleSummaryError(
    String userId,
    Exception error,
    BuildContext? context,
  ) async {
    debugPrint('Handling insight summary error: $error');

    try {
      // Strategy 1: Show user error notification
      if (context != null) {
        _showErrorSnackbar(context, error);
      }

      // Strategy 2: Queue for retry (if it's a sync issue)
      if (_isSyncError(error)) {
        await _queueForRetry(userId, error);
      }

      // Strategy 3: Fall back to real-time calculation
      final fallbackSummary =
          await _insightSummaryService.getSummaryWithFallback(userId);

      return InsightErrorResult(
        success: true,
        summary: fallbackSummary,
        usedFallback: true,
        errorHandled: true,
      );
    } catch (fallbackError) {
      debugPrint('Fallback also failed: $fallbackError');

      if (context != null) {
        _showCriticalErrorSnackbar(context);
      }

      return InsightErrorResult(
        success: false,
        summary: UserInsightSummary.empty(userId),
        usedFallback: true,
        errorHandled: false,
        error: Exception(
          'Failed to load insights: $fallbackError',
        ),
      );
    }
  }

  /// Handle insight update error
  Future<void> handleUpdateError(
    String userId,
    Map<String, dynamic> sessionData,
    InsightUpdateType updateType,
    Exception error,
    BuildContext? context,
  ) async {
    debugPrint('Handling insight update error: $error');

    // Strategy 1: Show user error
    if (context != null) {
      _showUpdateErrorSnackbar(context);
    }

    // Strategy 2: Queue for retry
    final pendingUpdate = PendingInsightUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionData: sessionData,
      type: updateType,
      timestamp: DateTime.now(),
      retryCount: 0,
    );

    await _syncQueue.queueUpdate(pendingUpdate);

    debugPrint('Queued failed insight update for retry');
  }

  /// Show error snackbar to user
  void _showErrorSnackbar(BuildContext context, Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load insights. Using cached data.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Trigger manual refresh
            _syncQueue.processPendingUpdates();
          },
        ),
      ),
    );
  }

  /// Show update error snackbar
  void _showUpdateErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Insight update failed. Will retry automatically.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show critical error snackbar
  void _showCriticalErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load insights. Please check your connection.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Could trigger app refresh or retry
          },
        ),
      ),
    );
  }

  /// Queue error for retry
  Future<void> _queueForRetry(String userId, Exception error) async {
    // Create a general retry entry
    final pendingUpdate = PendingInsightUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionData: {'error': error.toString()},
      type: InsightUpdateType.sessionEnd,
      timestamp: DateTime.now(),
      retryCount: 0,
    );

    await _syncQueue.queueUpdate(pendingUpdate);
  }

  /// Check if error is sync-related
  bool _isSyncError(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('network') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('firebase') ||
        errorMessage.contains('unavailable');
  }

  /// Get sync queue status for UI
  Future<SyncQueueStatus> getSyncStatus() async {
    final queueSize = await _syncQueue.getQueueSize();
    return SyncQueueStatus(
      hasQueuedItems: queueSize > 0,
      queueSize: queueSize,
      isProcessing: _syncQueue.isProcessing,
    );
  }

  /// Manual retry of all pending updates
  Future<bool> retryAllPending() async {
    try {
      await _syncQueue.processPendingUpdates();
      return true;
    } catch (e) {
      debugPrint('Error retrying pending updates: $e');
      return false;
    }
  }
}

/// Result of error handling operation
class InsightErrorResult {
  final bool success;
  final UserInsightSummary summary;
  final bool usedFallback;
  final bool errorHandled;
  final Exception? error;

  InsightErrorResult({
    required this.success,
    required this.summary,
    required this.usedFallback,
    required this.errorHandled,
    this.error,
  });
}

/// Sync queue status for UI
class SyncQueueStatus {
  final bool hasQueuedItems;
  final int queueSize;
  final bool isProcessing;

  SyncQueueStatus({
    required this.hasQueuedItems,
    required this.queueSize,
    required this.isProcessing,
  });
}
