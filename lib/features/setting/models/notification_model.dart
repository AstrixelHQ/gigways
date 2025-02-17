class NotificationModel {
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  NotificationModel({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

// Notification Types
enum NotificationType {
  alert,
  message,
  update,
  payment,
}
