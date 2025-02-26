import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/community/widgets/widgets.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:share_plus/share_plus.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  static const String path = '/community';

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  // Mock data for posts - in a real app this would come from a provider
  final List<PostModel> _posts = [
    PostModel(
      id: '1',
      userName: 'John Doe',
      userAvatarUrl: null, // null means we'll use initials
      content:
          'Just completed a 12-hour driving shift. Time for a well-deserved break! 😴',
      likesCount: 24,
      commentsCount: 5,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PostModel(
      id: '2',
      userName: 'Sarah Miller',
      userAvatarUrl: null,
      content:
          'Has anyone else noticed the surge in ride requests downtown this evening? It\'s keeping me busy!',
      likesCount: 15,
      commentsCount: 8,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PostModel(
      id: '3',
      userName: 'Carlos Rodriguez',
      userAvatarUrl: null,
      content:
          'Reminder: The driver meetup is happening this Saturday at Central Park, 2 PM. Hope to see many of you there! We\'ll be discussing the new app features and sharing experiences.',
      likesCount: 42,
      commentsCount: 12,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void _toggleLike(String postId) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        // Toggle liked state for this post
        if (post.isLiked) {
          _posts[index] =
              post.copyWith(likesCount: post.likesCount - 1, isLiked: false);
        } else {
          _posts[index] =
              post.copyWith(likesCount: post.likesCount + 1, isLiked: true);
        }
      }
    });
  }

  void _showComments(PostModel post) {
    CommentRoute($extra: post).push(context);
  }

  void _sharePost(PostModel post) async {
    await Share.share(
      'Check out this post from ${post.userName} on GigWays:\n\n${post.content}',
      subject: 'GigWays - Community Post',
    );
  }

  void _createNewPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostBottomSheet(
        onPostCreated: (content) {
          // Add the new post to the list
          setState(() {
            _posts.insert(
              0,
              PostModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userName: 'You', // In a real app, get this from user profile
                userAvatarUrl: null,
                content: content,
                likesCount: 0,
                commentsCount: 0,
                timestamp: DateTime.now(),
                isLiked: false,
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      floatingActionButton: CreatePostButton(
        onPressed: _createNewPost,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Community',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
              ),
            ),

            // Post List
            Expanded(
              child: _posts.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _posts.length,
                      separatorBuilder: (context, index) => 16.verticalSpace,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return PostCard(
                          post: post,
                          onLike: () => _toggleLike(post.id),
                          onComment: () => _showComments(post),
                          onShare: () => _sharePost(post),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppColorToken.white.value.withAlpha(100),
          ),
          16.verticalSpace,
          Text(
            'No posts yet',
            style: AppTextStyle.size(18).medium.withColor(AppColorToken.white),
          ),
          8.verticalSpace,
          Text(
            'Be the first to share with the community!',
            style: AppTextStyle.size(14)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(70)),
          ),
        ],
      ),
    );
  }
}
