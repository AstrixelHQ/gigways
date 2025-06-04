import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/insights/models/insight_summary_models.dart';
import 'package:gigways/features/insights/services/insight_summary_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'insight_sync_queue.g.dart';

@Riverpod(keepAlive: true)
InsightSyncQueue insightSyncQueue(Ref ref) {
  return InsightSyncQueue(
    insightSummaryService: ref.read(insightSummaryServiceProvider),
  );
}

class InsightSyncQueue {
  final InsightSummaryService _insightSummaryService;
  static const String _queueKey = 'insight_sync_queue';
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 30);

  Timer? _syncTimer;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  InsightSyncQueue({
    required InsightSummaryService insightSummaryService,
  }) : _insightSummaryService = insightSummaryService;

  /// Add failed update to queue
  Future<void> queueUpdate(PendingInsightUpdate update) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingQueue = await _getQueueFromStorage(prefs);

      // Add new update to queue
      existingQueue.add(update);

      // Save back to storage
      await _saveQueueToStorage(prefs, existingQueue);

      debugPrint(
          'Queued insight update: ${update.type.name} for user ${update.userId}');

      // Start processing if not already running
      _startPeriodicSync();
    } catch (e) {
      debugPrint('Error queuing insight update: $e');
    }
  }

  /// Process pending updates
  Future<void> processPendingUpdates() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueueFromStorage(prefs);

      if (queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('Processing ${queue.length} pending insight updates');

      final processedUpdates = <String>[];
      final failedUpdates = <PendingInsightUpdate>[];

      for (final update in queue) {
        try {
          // Try to retry the update via cloud function
          final success = await _insightSummaryService.retryFailedUpdates();

          if (success) {
            processedUpdates.add(update.id);
            debugPrint('Successfully processed update: ${update.id}');
          } else {
            // Increment retry count
            final updatedUpdate = PendingInsightUpdate(
              id: update.id,
              userId: update.userId,
              sessionData: update.sessionData,
              type: update.type,
              timestamp: update.timestamp,
              retryCount: update.retryCount + 1,
            );

            if (updatedUpdate.retryCount < _maxRetries) {
              failedUpdates.add(updatedUpdate);
            } else {
              debugPrint('Max retries reached for update: ${update.id}');
              processedUpdates.add(update.id); // Remove from queue
            }
          }
        } catch (e) {
          debugPrint('Error processing update ${update.id}: $e');

          // Increment retry count and re-queue if under limit
          final updatedUpdate = PendingInsightUpdate(
            id: update.id,
            userId: update.userId,
            sessionData: update.sessionData,
            type: update.type,
            timestamp: update.timestamp,
            retryCount: update.retryCount + 1,
          );

          if (updatedUpdate.retryCount < _maxRetries) {
            failedUpdates.add(updatedUpdate);
          } else {
            processedUpdates.add(update.id); // Remove from queue
          }
        }
      }

      // Update queue with only failed updates that still have retries left
      await _saveQueueToStorage(prefs, failedUpdates);

      debugPrint(
          'Processed ${processedUpdates.length} updates, ${failedUpdates.length} remaining');
    } catch (e) {
      debugPrint('Error processing pending updates: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_retryDelay, (_) {
      processPendingUpdates();
    });
  }

  /// Stop periodic sync
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueueFromStorage(prefs);
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all pending updates
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      debugPrint('Cleared insight sync queue');
    } catch (e) {
      debugPrint('Error clearing queue: $e');
    }
  }

  /// Load queue from local storage
  Future<List<PendingInsightUpdate>> _getQueueFromStorage(
      SharedPreferences prefs) async {
    try {
      final queueJson = prefs.getStringList(_queueKey) ?? [];
      return queueJson
          .map((json) => PendingInsightUpdate.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading queue from storage: $e');
      return [];
    }
  }

  /// Save queue to local storage
  Future<void> _saveQueueToStorage(
      SharedPreferences prefs, List<PendingInsightUpdate> queue) async {
    try {
      final queueJson =
          queue.map((update) => jsonEncode(update.toMap())).toList();
      await prefs.setStringList(_queueKey, queueJson);
    } catch (e) {
      debugPrint('Error saving queue to storage: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopSync();
  }
}
