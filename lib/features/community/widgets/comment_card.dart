import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/community/models/comment_model.dart';
import 'package:gigways/features/community/widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final bool isReply;
  final VoidCallback onLike;
  final VoidCallback onReply;

  const CommentCard({
    super.key,
    required this.comment,
    this.isReply = false,
    required this.onLike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isReply
            ? Colors.transparent
            : AppColorToken.black.value.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: isReply
            ? null
            : Border.all(
                color: AppColorToken.white.value.withAlpha(10),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              UserAvatar(
                userName: comment.userName,
                imageUrl: comment.userAvatarUrl,
                size: 32,
              ),
              8.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.userName,
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                  Text(
                    _formatTimestamp(comment.timestamp),
                    style: AppTextStyle.size(12)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(70)),
                  ),
                ],
              ),
            ],
          ),
          8.verticalSpace,

          // Comment content
          Text(
            comment.content,
            style: AppTextStyle.size(14).regular.withColor(AppColorToken.white),
          ),
          12.verticalSpace,

          // Action buttons
          Row(
            children: [
              // Like button
              _ActionButton(
                icon: comment.isLiked ? Icons.favorite : Icons.favorite_border,
                label: comment.likesCount > 0
                    ? comment.likesCount.toString()
                    : 'Like',
                color: comment.isLiked ? Colors.red : null,
                onTap: onLike,
              ),
              16.horizontalSpace,

              // Reply button
              _ActionButton(
                icon: Icons.reply,
                label: 'Reply',
                onTap: onReply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppColorToken.white.value.withAlpha(150),
          ),
          4.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.size(12)
                .regular
                .withColor((color ?? AppColorToken.white.value).toToken()),
          ),
        ],
      ),
    );
  }
}
