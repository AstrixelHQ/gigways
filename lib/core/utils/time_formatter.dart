class TimeFormatter {
  /// Formats seconds into HH:MM:SS format
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds into a more readable format (e.g., "2h 30m")
  static String formatDurationCompact(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      final remainingSeconds = seconds % 60;
      return minutes > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${remainingSeconds}s';
    }
  }

  /// Formats a time value from TimeOfDay
  static String formatTimeOfDay(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
