import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/setting/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  static const String path = '/notifications';

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          children: [
            16.verticalSpace,
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColorToken.golden.value,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColorToken.golden.value,
                        size: 20,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Text(
                    'Notifications',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Handle mark all as read
                    },
                    child: Text(
                      'Mark all as read',
                      style: AppTextStyle.size(14)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // Notification List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 10, // Replace with actual notification count
                separatorBuilder: (context, index) => 16.verticalSpace,
                itemBuilder: (context, index) {
                  return _NotificationItem(
                    notification: NotificationModel(
                      type: _getRandomType(index),
                      title: 'Notification Title',
                      message:
                          'This is a sample notification message that can span multiple lines to show how it handles longer content.',
                      time: DateTime.now().subtract(Duration(hours: index)),
                      isRead: index % 3 == 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  NotificationType _getRandomType(int index) {
    final types = NotificationType.values;
    return types[index % types.length];
  }
}

// Notification Item Widget
class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({
    required this.notification,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyle.size(16)
                          .bold
                          .withColor(AppColorToken.white),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColorToken.golden.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                8.verticalSpace,
                Text(
                  notification.message,
                  style: AppTextStyle.size(14)
                      .regular
                      .withColor(AppColorToken.white..color.withOpacity(0.7)),
                ),
                8.verticalSpace,
                Text(
                  _formatTime(notification.time),
                  style: AppTextStyle.size(12)
                      .regular
                      .withColor(AppColorToken.white..color.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.alert:
        icon = Icons.warning_outlined;
        color = Colors.red;
      case NotificationType.message:
        icon = Icons.message_outlined;
        color = Colors.blue;
      case NotificationType.update:
        icon = Icons.system_update_outlined;
        color = Colors.green;
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = AppColorToken.golden.value;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }
}
