import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

part 'debug_log_service.g.dart';

/// Log level enumeration
enum LogLevel {
  debug(0, '🔍 DEBUG'),
  info(1, 'ℹ️  INFO'),
  warning(2, '⚠️  WARN'),
  error(3, '❌ ERROR'),
  critical(4, '🚨 CRITICAL');

  const LogLevel(this.priority, this.icon);
  final int priority;
  final String icon;
}

/// Log category for better organization
enum LogCategory {
  notification('🔔 NOTIFICATION'),
  tracking('📍 TRACKING'),
  location('🌍 LOCATION'),
  activity('🚶 ACTIVITY'),
  auth('🔐 AUTH'),
  storage('💾 STORAGE'),
  ui('🎨 UI'),
  network('🌐 NETWORK'),
  permission('🔒 PERMISSION'),
  system('⚙️  SYSTEM'),
  general('📝 GENERAL');

  const LogCategory(this.icon);
  final String icon;
}

/// Detailed log entry model
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? details;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;
  final String? userId;
  final String? sessionId;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.details,
    this.metadata,
    this.stackTrace,
    this.userId,
    this.sessionId,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level.name,
      'category': category.name,
      'message': message,
      'details': details,
      'metadata': metadata,
      'stackTrace': stackTrace,
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  /// Create from JSON
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      category: LogCategory.values.firstWhere((c) => c.name == json['category']),
      message: json['message'],
      details: json['details'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      stackTrace: json['stackTrace'],
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }

  /// Formatted string for display/export
  String toFormattedString() {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final levelStr = level.icon.padRight(12);
    final categoryStr = category.icon.padRight(15);
    
    final buffer = StringBuffer();
    buffer.writeln('[$dateStr] $levelStr $categoryStr $message');
    
    if (details != null) {
      buffer.writeln('  Details: $details');
    }
    
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('  Metadata: ${jsonEncode(metadata)}');
    }
    
    if (userId != null) {
      buffer.writeln('  User: $userId');
    }
    
    if (sessionId != null) {
      buffer.writeln('  Session: $sessionId');
    }
    
    if (stackTrace != null) {
      buffer.writeln('  Stack Trace:');
      buffer.writeln('    ${stackTrace!.replaceAll('\n', '\n    ')}');
    }
    
    buffer.writeln(''); // Empty line for readability
    return buffer.toString();
  }
}

/// Debug log service for comprehensive app logging
class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final List<LogEntry> _logBuffer = [];
  final int _maxBufferSize = 1000; // Keep last 1000 logs in memory
  final int _maxFileSize = 5 * 1024 * 1024; // 5MB max file size
  
  Timer? _flushTimer;
  String? _currentUserId;
  String? _currentSessionId;
  
  // Configuration
  LogLevel _minLogLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _isEnabled = true;
  bool _shouldWriteToFile = true;
  bool _shouldPrintToConsole = kDebugMode;

  /// Initialize the logging service
  Future<void> initialize({String? userId}) async {
    _currentUserId = userId;
    _generateNewSessionId();
    
    // Start periodic flush timer (every 30 seconds)
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushLogsToFile();
    });
    
    // Log service startup
    await log(
      level: LogLevel.info,
      category: LogCategory.system,
      message: 'DebugLogService initialized',
      metadata: {
        'userId': _currentUserId,
        'sessionId': _currentSessionId,
        'debugMode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Generate new session ID
  void _generateNewSessionId() {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Update user ID
  void setUserId(String? userId) {
    _currentUserId = userId;
    log(
      level: LogLevel.info,
      category: LogCategory.auth,
      message: 'User ID updated',
      metadata: {'newUserId': userId},
    );
  }

  /// Main logging method
  Future<void> log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? details,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    Object? error,
  }) async {
    if (!_isEnabled || level.priority < _minLogLevel.priority) {
      return;
    }

    // Generate unique ID for this log entry
    final id = 'log_${DateTime.now().millisecondsSinceEpoch}_${_logBuffer.length}';
    
    // Extract stack trace from error if provided
    String? finalStackTrace = stackTrace;
    if (error != null) {
      finalStackTrace ??= error.toString();
      if (error is Error) {
        finalStackTrace = error.stackTrace?.toString();
      }
    }

    final logEntry = LogEntry(
      id: id,
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      details: details,
      metadata: metadata,
      stackTrace: finalStackTrace,
      userId: _currentUserId,
      sessionId: _currentSessionId,
    );

    // Add to buffer
    _addToBuffer(logEntry);

    // Print to console if enabled
    if (_shouldPrintToConsole) {
      _printToConsole(logEntry);
    }

    // Write to file asynchronously
    if (_shouldWriteToFile) {
      unawaited(_writeToFile(logEntry));
    }
  }

  /// Add log entry to buffer with size management
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    
    // Remove old entries if buffer is too large
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeRange(0, _logBuffer.length - _maxBufferSize);
    }
  }

  /// Print log to console with formatting
  void _printToConsole(LogEntry entry) {
    final dateStr = DateFormat('HH:mm:ss.SSS').format(entry.timestamp);
    final prefix = '[$dateStr] ${entry.level.icon} ${entry.category.icon}';
    
    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('$prefix ${entry.message}');
        break;
      case LogLevel.info:
        debugPrint('$prefix ${entry.message}');
        break;
      case LogLevel.warning:
        debugPrint('$prefix ${entry.message}');
        break;
      case LogLevel.error:
      case LogLevel.critical:
        debugPrint('$prefix ${entry.message}');
        if (entry.details != null) {
          debugPrint('  Details: ${entry.details}');
        }
        if (entry.stackTrace != null) {
          debugPrint('  Stack: ${entry.stackTrace}');
        }
        break;
    }
  }

  /// Write log entry to file
  Future<void> _writeToFile(LogEntry entry) async {
    try {
      final file = await _getLogFile();
      final logLine = entry.toFormattedString();
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  /// Flush all buffered logs to file
  Future<void> _flushLogsToFile() async {
    if (_logBuffer.isEmpty || !_shouldWriteToFile) return;
    
    try {
      final file = await _getLogFile();
      final buffer = StringBuffer();
      
      for (final entry in _logBuffer) {
        buffer.write(entry.toFormattedString());
      }
      
      await file.writeAsString(buffer.toString(), mode: FileMode.append);
      
      // Check file size and rotate if needed
      await _rotateLogFileIfNeeded(file);
    } catch (e) {
      debugPrint('Failed to flush logs to file: $e');
    }
  }

  /// Get log file handle
  Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return File('${logDir.path}/gigways_debug_$today.log');
  }

  /// Rotate log file if it's too large
  Future<void> _rotateLogFileIfNeeded(File file) async {
    try {
      final stat = await file.stat();
      if (stat.size > _maxFileSize) {
        final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final archivePath = '${file.path}.archive_$timestamp';
        await file.rename(archivePath);
        
        // Keep only last 5 archive files
        await _cleanupOldLogFiles();
      }
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Clean up old log files
  Future<void> _cleanupOldLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) return;
      
      final files = await logDir.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((f) => f.path.contains('gigways_debug_'))
          .toList();
      
      // Sort by modification date
      logFiles.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      
      // Keep only the last 10 files
      if (logFiles.length > 10) {
        for (final file in logFiles.take(logFiles.length - 10)) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old log files: $e');
    }
  }

  /// Get recent logs for display
  List<LogEntry> getRecentLogs({
    int limit = 100,
    LogLevel? minLevel,
    LogCategory? category,
  }) {
    var logs = _logBuffer.toList();
    
    if (minLevel != null) {
      logs = logs.where((log) => log.level.priority >= minLevel.priority).toList();
    }
    
    if (category != null) {
      logs = logs.where((log) => log.category == category).toList();
    }
    
    // Sort by timestamp (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return logs.take(limit).toList();
  }

  /// Export logs to file and share
  Future<String> exportLogs({
    Duration? timeRange,
    LogLevel? minLevel,
    List<LogCategory>? categories,
  }) async {
    try {
      await _flushLogsToFile(); // Ensure all logs are written
      
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final exportFile = File('${exportDir.path}/gigways_logs_$timestamp.txt');
      
      final buffer = StringBuffer();
      
      // Add header information
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('GIGWAYS DEBUG LOGS EXPORT');
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
      buffer.writeln('User ID: ${_currentUserId ?? 'Unknown'}');
      buffer.writeln('Session ID: ${_currentSessionId ?? 'Unknown'}');
      buffer.writeln('Debug Mode: $kDebugMode');
      buffer.writeln('Platform: ${Platform.operatingSystem}');
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('');

      // Filter logs based on criteria
      var logsToExport = _logBuffer.toList();
      
      if (timeRange != null) {
        final cutoff = DateTime.now().subtract(timeRange);
        logsToExport = logsToExport.where((log) => log.timestamp.isAfter(cutoff)).toList();
      }
      
      if (minLevel != null) {
        logsToExport = logsToExport.where((log) => log.level.priority >= minLevel.priority).toList();
      }
      
      if (categories != null && categories.isNotEmpty) {
        logsToExport = logsToExport.where((log) => categories.contains(log.category)).toList();
      }
      
      // Sort chronologically
      logsToExport.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Add log entries
      for (final entry in logsToExport) {
        buffer.write(entry.toFormattedString());
      }
      
      // Add footer
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('END OF LOGS - Total Entries: ${logsToExport.length}');
      buffer.writeln('='.padRight(80, '='));
      
      await exportFile.writeAsString(buffer.toString());
      
      await log(
        level: LogLevel.info,
        category: LogCategory.system,
        message: 'Logs exported successfully',
        metadata: {
          'exportPath': exportFile.path,
          'entriesCount': logsToExport.length,
          'fileSize': await exportFile.length(),
        },
      );
      
      return exportFile.path;
    } catch (e, stackTrace) {
      await log(
        level: LogLevel.error,
        category: LogCategory.system,
        message: 'Failed to export logs',
        details: e.toString(),
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Share logs via system share dialog
  Future<void> shareLogs({
    Duration? timeRange,
    LogLevel? minLevel,
    List<LogCategory>? categories,
  }) async {
    try {
      final filePath = await exportLogs(
        timeRange: timeRange,
        minLevel: minLevel,
        categories: categories,
      );
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'GigWays Debug Logs - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        text: 'Debug logs from GigWays app for developer review. User ID: ${_currentUserId ?? 'Unknown'}',
      );
      
      await log(
        level: LogLevel.info,
        category: LogCategory.system,
        message: 'Logs shared successfully',
      );
    } catch (e, stackTrace) {
      await log(
        level: LogLevel.error,
        category: LogCategory.system,
        message: 'Failed to share logs',
        details: e.toString(),
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _logBuffer.clear();
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
      }
      
      await log(
        level: LogLevel.info,
        category: LogCategory.system,
        message: 'All logs cleared',
      );
    } catch (e) {
      debugPrint('Failed to clear log files: $e');
    }
  }

  /// Get log statistics
  Map<String, dynamic> getLogStatistics() {
    final stats = <String, dynamic>{
      'totalLogs': _logBuffer.length,
      'sessionId': _currentSessionId,
      'userId': _currentUserId,
      'isEnabled': _isEnabled,
      'minLogLevel': _minLogLevel.name,
    };
    
    // Count by level
    for (final level in LogLevel.values) {
      final count = _logBuffer.where((log) => log.level == level).length;
      stats['${level.name}Count'] = count;
    }
    
    // Count by category
    for (final category in LogCategory.values) {
      final count = _logBuffer.where((log) => log.category == category).length;
      stats['${category.name}Count'] = count;
    }
    
    return stats;
  }

  /// Configure logging settings
  void configure({
    LogLevel? minLogLevel,
    bool? isEnabled,
    bool? shouldWriteToFile,
    bool? shouldPrintToConsole,
  }) {
    if (minLogLevel != null) _minLogLevel = minLogLevel;
    if (isEnabled != null) _isEnabled = isEnabled;
    if (shouldWriteToFile != null) _shouldWriteToFile = shouldWriteToFile;
    if (shouldPrintToConsole != null) _shouldPrintToConsole = shouldPrintToConsole;
    
    log(
      level: LogLevel.info,
      category: LogCategory.system,
      message: 'Logging configuration updated',
      metadata: {
        'minLogLevel': _minLogLevel.name,
        'isEnabled': _isEnabled,
        'shouldWriteToFile': _shouldWriteToFile,
        'shouldPrintToConsole': _shouldPrintToConsole,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _flushTimer?.cancel();
    _flushLogsToFile();
  }
}

@Riverpod(keepAlive: true)
DebugLogService debugLogService(Ref ref) {
  final service = DebugLogService();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}

/// Convenience logging functions
extension DebugLogExtension on DebugLogService {
  /// Log debug message
  Future<void> debug(String message, {LogCategory category = LogCategory.general, String? details, Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.debug, category: category, message: message, details: details, metadata: metadata);
  }
  
  /// Log info message
  Future<void> info(String message, {LogCategory category = LogCategory.general, String? details, Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.info, category: category, message: message, details: details, metadata: metadata);
  }
  
  /// Log warning message
  Future<void> warning(String message, {LogCategory category = LogCategory.general, String? details, Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.warning, category: category, message: message, details: details, metadata: metadata);
  }
  
  /// Log error message
  Future<void> error(String message, {LogCategory category = LogCategory.general, String? details, Map<String, dynamic>? metadata, Object? error}) {
    return log(level: LogLevel.error, category: category, message: message, details: details, metadata: metadata, error: error);
  }
  
  /// Log critical message
  Future<void> critical(String message, {LogCategory category = LogCategory.general, String? details, Map<String, dynamic>? metadata, Object? error}) {
    return log(level: LogLevel.critical, category: category, message: message, details: details, metadata: metadata, error: error);
  }
}