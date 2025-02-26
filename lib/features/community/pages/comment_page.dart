import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/community/models/comment_model.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/community/widgets/widgets.dart';

class CommentsPage extends ConsumerStatefulWidget {
  final PostModel post;

  const CommentsPage({
    super.key,
    required this.post,
  });

  static const String path = '/comments';

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  late List<CommentModel> _comments;
  CommentModel? _replyingTo;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // In a real app, these would come from a service or provider
    _comments = _getMockComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // Sample comments for demo
  List<CommentModel> _getMockComments() {
    return [
      CommentModel(
        id: '1',
        userId: 'user1',
        userName: 'Maria Johnson',
        content:
            'I totally agree with you! Been experiencing the same downtown.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        likesCount: 5,
        replies: [
          CommentModel(
            id: '2',
            userId: 'user2',
            userName: 'Robert Smith',
            parentId: '1',
            content:
                'Same here in the eastern district. It\'s been crazy busy all week.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
            likesCount: 2,
          ),
          CommentModel(
            id: '3',
            userId: 'user3',
            userName: 'Ashley Williams',
            parentId: '1',
            content:
                'I think it\'s because of the festival happening this weekend.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
            likesCount: 1,
          ),
        ],
      ),
      CommentModel(
        id: '4',
        userId: 'user4',
        userName: 'Michael Brown',
        content:
            'Has anyone tried the new route through Central Park? It seems to be faster during rush hour.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        likesCount: 3,
      ),
    ];
  }

  void _addComment(String content) {
    if (content.trim().isEmpty) return;

    setState(() {
      if (_replyingTo != null) {
        // Add reply to a comment
        final parentIndex =
            _comments.indexWhere((c) => c.id == _replyingTo!.id);
        if (parentIndex != -1) {
          final reply = CommentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId:
                'current_user', // In a real app, get from user authentication
            userName: 'You', // In a real app, get from user profile
            parentId: _replyingTo!.id,
            content: content,
            timestamp: DateTime.now(),
          );

          _comments[parentIndex] = _comments[parentIndex].addReply(reply);
        }
        _replyingTo = null;
      } else {
        // Add a new top-level comment
        _comments.insert(
          0,
          CommentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId:
                'current_user', // In a real app, get from user authentication
            userName: 'You', // In a real app, get from user profile
            content: content,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _commentController.clear();
  }

  void _likeComment(CommentModel comment) {
    setState(() {
      final isTopLevel = comment.parentId == null;

      if (isTopLevel) {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            isLiked: !comment.isLiked,
            likesCount: comment.isLiked
                ? comment.likesCount - 1
                : comment.likesCount + 1,
          );
        }
      } else {
        // Find parent comment
        final parentIndex =
            _comments.indexWhere((c) => c.id == comment.parentId);
        if (parentIndex != -1) {
          final parent = _comments[parentIndex];
          final replyIndex =
              parent.replies.indexWhere((r) => r.id == comment.id);

          if (replyIndex != -1) {
            List<CommentModel> updatedReplies = List.from(parent.replies);
            updatedReplies[replyIndex] = updatedReplies[replyIndex].copyWith(
              isLiked: !comment.isLiked,
              likesCount: comment.isLiked
                  ? comment.likesCount - 1
                  : comment.likesCount + 1,
            );

            _comments[parentIndex] = parent.copyWith(replies: updatedReplies);
          }
        }
      }
    });
  }

  void _replyToComment(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppBackButton(),
                  16.horizontalSpace,
                  Text(
                    'Comments',
                    style: AppTextStyle.size(20)
                        .bold
                        .withColor(AppColorToken.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_getTotalCommentCount()} comments',
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(70)),
                  ),
                ],
              ),
            ),

            // Original post (simplified view)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorToken.golden.value.withAlpha(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColorToken.primary.value,
                          radius: 16,
                          child: Text(
                            _getInitials(widget.post.userName),
                            style: AppTextStyle.size(12)
                                .bold
                                .withColor(AppColorToken.white),
                          ),
                        ),
                        8.horizontalSpace,
                        Text(
                          widget.post.userName,
                          style: AppTextStyle.size(14)
                              .medium
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    Text(
                      widget.post.content,
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32, color: Colors.white12),

            // Comments list
            Expanded(
              child: _comments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentWithReplies(_comments[index]);
                      },
                    ),
            ),

            // Comment input area
            CommentInput(
              controller: _commentController,
              focusNode: _commentFocusNode,
              onSubmit: _addComment,
              replyingTo: _replyingTo,
              onCancelReply: _cancelReply,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentWithReplies(CommentModel comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        CommentCard(
          comment: comment,
          onLike: () => _likeComment(comment),
          onReply: () => _replyToComment(comment),
        ),

        // Replies (if any)
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: comment.replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CommentCard(
                    comment: reply,
                    isReply: true,
                    onLike: () => _likeComment(reply),
                    onReply: () => _replyToComment(reply),
                  ),
                );
              }).toList(),
            ),
          ),

        24.verticalSpace, // Space between comment groups
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 48,
            color: AppColorToken.white.value.withAlpha(100),
          ),
          16.verticalSpace,
          Text(
            'No comments yet',
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
          8.verticalSpace,
          Text(
            'Be the first to comment!',
            style: AppTextStyle.size(14)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(70)),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    String initials = '';

    if (parts.isNotEmpty) {
      initials += parts[0][0];
      if (parts.length > 1) {
        initials += parts[1][0];
      }
    }

    return initials.toUpperCase();
  }

  int _getTotalCommentCount() {
    int total = _comments.length;
    for (var comment in _comments) {
      total += comment.replies.length;
    }
    return total;
  }
}
