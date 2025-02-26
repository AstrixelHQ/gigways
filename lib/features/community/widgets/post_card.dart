import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/community/widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(
                  userName: post.userName,
                  imageUrl: post.userAvatarUrl,
                  size: 40,
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: AppTextStyle.size(16)
                            .medium
                            .withColor(AppColorToken.white),
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: AppTextStyle.size(12).regular.withColor(
                            AppColorToken.white..color.withAlpha(70)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.content,
              style:
                  AppTextStyle.size(15).regular.withColor(AppColorToken.white),
            ),
          ),
          12.verticalSpace,

          // Post Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Like Button
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  count: post.likesCount,
                  color: post.isLiked ? Colors.red : AppColorToken.white.value,
                  onTap: onLike,
                ),
                24.horizontalSpace,

                // Comment Button
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  count: post.commentsCount,
                  onTap: onComment,
                ),
                24.horizontalSpace,

                // Share Button
                GestureDetector(
                  onTap: onShare,
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: AppColorToken.white.value,
                      ),
                      8.horizontalSpace,
                      Text(
                        'Share',
                        style: AppTextStyle.size(14)
                            .regular
                            .withColor(AppColorToken.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isComment = icon == Icons.comment_outlined;
    final label = isComment
        ? (count > 0 ? '$count comments' : 'Comment')
        : count.toString();

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? AppColorToken.white.value,
          ),
          8.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.size(14).regular.withColor(AppColorToken.white),
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
