import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/back_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/community/models/comment_model.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/community/widgets/comment_card.dart';
import 'package:gigways/features/community/widgets/comment_input.dart';

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
  // Pagination variables for main comments
  static const int _commentsPerPage = 10;
  static const int _repliesPerBatch = 2; // Load 2 replies at a time
  int _currentPage = 1;
  bool _hasMoreComments = true;
  bool _isLoadingMore = false;

  // Reply visibility and pagination tracking
  final Set<String> _expandedCommentIds = {};

  // Track how many replies are loaded for each comment
  final Map<String, int> _loadedRepliesCount = {};

  // Track which comments are currently loading more replies
  final Set<String> _loadingMoreReplies = {};

  late List<CommentModel> _allComments;
  List<CommentModel> _displayedComments = [];
  CommentModel? _replyingTo;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // In a real app, these would come from a service or provider
    _allComments = _getMockComments();
    _loadInitialComments();

    // Initialize loaded replies count for each comment
    for (final comment in _allComments) {
      if (comment.replies.isNotEmpty) {
        // Start with minimum of 2 replies or all if fewer
        _loadedRepliesCount[comment.id] =
            comment.replies.length > _repliesPerBatch
                ? _repliesPerBatch
                : comment.replies.length;
      }
    }

    // Listen for scroll events to implement infinite scroll
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  void _loadInitialComments() {
    setState(() {
      if (_allComments.length <= _commentsPerPage) {
        _displayedComments = List.from(_allComments);
        _hasMoreComments = false;
      } else {
        _displayedComments = _allComments.sublist(0, _commentsPerPage);
        _hasMoreComments = true;
      }
    });
  }

  Future<void> _loadMoreComments() async {
    if (!_hasMoreComments || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final startIndex = _currentPage * _commentsPerPage;

    setState(() {
      if (startIndex >= _allComments.length) {
        _hasMoreComments = false;
      } else {
        final endIndex = (startIndex + _commentsPerPage <= _allComments.length)
            ? startIndex + _commentsPerPage
            : _allComments.length;

        _displayedComments.addAll(_allComments.sublist(startIndex, endIndex));
        _currentPage++;
        _hasMoreComments = endIndex < _allComments.length;
      }
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMoreReplies(String commentId) async {
    if (_loadingMoreReplies.contains(commentId)) return;

    final commentIndex = _allComments.indexWhere((c) => c.id == commentId);
    if (commentIndex == -1) return;

    final comment = _allComments[commentIndex];
    final currentlyLoaded = _loadedRepliesCount[commentId] ?? 0;

    // Check if there are more replies to load
    if (currentlyLoaded >= comment.replies.length) return;

    setState(() {
      _loadingMoreReplies.add(commentId);
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      // Calculate how many more to load
      final newCount =
          (currentlyLoaded + _repliesPerBatch <= comment.replies.length)
              ? currentlyLoaded + _repliesPerBatch
              : comment.replies.length;

      _loadedRepliesCount[commentId] = newCount;
      _loadingMoreReplies.remove(commentId);
    });
  }

  // Generate a larger set of mock comments for pagination testing
  List<CommentModel> _getMockComments() {
    final baseComments = [
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
            id: '1_1',
            userId: 'user2',
            userName: 'Robert Smith',
            parentId: '1',
            content:
                'Same here in the eastern district. It\'s been crazy busy all week.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
            likesCount: 2,
          ),
          CommentModel(
            id: '1_2',
            userId: 'user3',
            userName: 'Ashley Williams',
            parentId: '1',
            content:
                'I think it\'s because of the festival happening this weekend.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
            likesCount: 1,
          ),
          CommentModel(
            id: '1_3',
            userId: 'user4',
            userName: 'Jessica Chen',
            parentId: '1',
            content:
                'The downtown area gets so congested during events. I usually avoid those routes.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            likesCount: 0,
          ),
          CommentModel(
            id: '1_4',
            userId: 'user5',
            userName: 'David Kim',
            parentId: '1',
            content:
                'Have you tried the alternate route through Pine Street? It\'s usually less busy.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            likesCount: 3,
          ),
          CommentModel(
            id: '1_5',
            userId: 'user6',
            userName: 'Sarah Johnson',
            parentId: '1',
            content:
                'I\'ve been using the transit app to navigate around the busy areas. It helps a lot!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            likesCount: 7,
          ),
          CommentModel(
            id: '1_6',
            userId: 'user7',
            userName: 'Michael Wilson',
            parentId: '1',
            content:
                'Downtown traffic is always bad during festivals. Better avoid that area altogether.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            likesCount: 1,
          ),
        ],
      ),
      CommentModel(
        id: '2',
        userId: 'user4',
        userName: 'Michael Brown',
        content:
            'Has anyone tried the new route through Central Park? It seems to be faster during rush hour.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        likesCount: 3,
        replies: [
          CommentModel(
            id: '2_1',
            userId: 'user6',
            userName: 'Emma Thompson',
            parentId: '2',
            content:
                'I tried it yesterday, saved about 15 minutes on my commute!',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            likesCount: 1,
          ),
          CommentModel(
            id: '2_2',
            userId: 'user7',
            userName: 'Daniel Carter',
            parentId: '2',
            content:
                'It\'s great during weekdays, but gets crowded on weekends.',
            timestamp:
                DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            likesCount: 3,
          ),
          CommentModel(
            id: '2_3',
            userId: 'user8',
            userName: 'Olivia Martinez',
            parentId: '2',
            content:
                'Just be careful during evening hours, the lighting isn\'t great.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            likesCount: 5,
          ),
        ],
      ),
    ];

    // Generate additional comments for testing pagination
    final moreComments = List.generate(
      20, // Generate 20 more comments
      (index) => CommentModel(
        id: (index + 3).toString(),
        userId: 'user${index + 7}',
        userName: 'User ${index + 1}',
        content: 'This is comment ${index + 1}. ' +
            List.generate(index % 3 + 1, (_) => 'Lorem ipsum dolor sit amet. ')
                .join(),
        timestamp: DateTime.now().subtract(Duration(hours: index + 4)),
        likesCount: index % 5,
        replies: index % 3 == 0
            ? List.generate(
                index % 5 + 3, // Some comments have many replies
                (replyIndex) => CommentModel(
                  id: '${index + 3}_$replyIndex',
                  userId: 'user${replyIndex + 20}',
                  userName: 'Replier ${replyIndex + 1}',
                  parentId: (index + 3).toString(),
                  content: 'Reply ${replyIndex + 1} to comment ${index + 1}. ' +
                      (replyIndex % 2 == 0
                          ? 'Some additional details about this topic.'
                          : ''),
                  timestamp: DateTime.now().subtract(Duration(
                      hours: index + 3, minutes: 30 + replyIndex * 15)),
                  likesCount: replyIndex,
                ),
              )
            : [],
      ),
    );

    return [...baseComments, ...moreComments];
  }

  void _addComment(String content) {
    if (content.trim().isEmpty) return;

    setState(() {
      if (_replyingTo != null) {
        // Add reply to a comment
        final index = _allComments.indexWhere((c) => c.id == _replyingTo!.id);
        if (index != -1) {
          final reply = CommentModel(
            id: '${_replyingTo!.id}_${_allComments[index].replies.length + 1}',
            userId:
                'current_user', // In a real app, get from user authentication
            userName: 'You', // In a real app, get from user profile
            parentId: _replyingTo!.id,
            content: content,
            timestamp: DateTime.now(),
          );

          final updatedComment = _allComments[index].addReply(reply);
          _allComments[index] = updatedComment;

          // Ensure the comment with the new reply is expanded
          _expandedCommentIds.add(_replyingTo!.id);

          // Update loaded replies count
          _loadedRepliesCount[_replyingTo!.id] =
              (_loadedRepliesCount[_replyingTo!.id] ?? 0) + 1;

          // Update the displayed comments
          final displayedIndex =
              _displayedComments.indexWhere((c) => c.id == _replyingTo!.id);
          if (displayedIndex != -1) {
            _displayedComments[displayedIndex] = updatedComment;
          }
        }
        _replyingTo = null;
      } else {
        // Add a new top-level comment
        final newComment = CommentModel(
          id: (_allComments.length + 1).toString(),
          userId: 'current_user', // In a real app, get from user authentication
          userName: 'You', // In a real app, get from user profile
          content: content,
          timestamp: DateTime.now(),
        );

        _allComments.insert(0, newComment);
        _displayedComments.insert(0, newComment);
      }
    });
    _commentController.clear();
  }

  void _likeComment(CommentModel comment) {
    setState(() {
      final isTopLevel = comment.parentId == null;

      if (isTopLevel) {
        // Update in all comments list
        final allIndex = _allComments.indexWhere((c) => c.id == comment.id);
        if (allIndex != -1) {
          final updatedLikes =
              comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1;
          _allComments[allIndex] = _allComments[allIndex].copyWith(
            isLiked: !comment.isLiked,
            likesCount: updatedLikes,
          );

          // Update in displayed comments list
          final displayedIndex =
              _displayedComments.indexWhere((c) => c.id == comment.id);
          if (displayedIndex != -1) {
            _displayedComments[displayedIndex] = _allComments[allIndex];
          }
        }
      } else {
        // Find parent comment in all comments
        final parentAllIndex =
            _allComments.indexWhere((c) => c.id == comment.parentId);
        if (parentAllIndex != -1) {
          final parent = _allComments[parentAllIndex];
          final replyIndex =
              parent.replies.indexWhere((r) => r.id == comment.id);

          if (replyIndex != -1) {
            List<CommentModel> updatedReplies = List.from(parent.replies);
            final updatedLikes = comment.isLiked
                ? comment.likesCount - 1
                : comment.likesCount + 1;
            updatedReplies[replyIndex] = updatedReplies[replyIndex].copyWith(
              isLiked: !comment.isLiked,
              likesCount: updatedLikes,
            );

            _allComments[parentAllIndex] =
                parent.copyWith(replies: updatedReplies);

            // Update in displayed comments list
            final displayedIndex =
                _displayedComments.indexWhere((c) => c.id == comment.parentId);
            if (displayedIndex != -1) {
              _displayedComments[displayedIndex] = _allComments[parentAllIndex];
            }
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

  void _toggleReplies(String commentId) {
    setState(() {
      if (_expandedCommentIds.contains(commentId)) {
        _expandedCommentIds.remove(commentId);
      } else {
        _expandedCommentIds.add(commentId);
      }
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
              child: _displayedComments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _displayedComments.length +
                          (_hasMoreComments ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _displayedComments.length) {
                          return _buildLoadMoreIndicator();
                        }
                        return _buildCommentWithReplies(
                            _displayedComments[index]);
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
    final hasReplies = comment.replies.isNotEmpty;
    final isExpanded = _expandedCommentIds.contains(comment.id);
    final loadedReplies = _loadedRepliesCount[comment.id] ??
        (hasReplies ? _repliesPerBatch.clamp(0, comment.replies.length) : 0);

    final hasMoreReplies = hasReplies && loadedReplies < comment.replies.length;
    final isLoadingReplies = _loadingMoreReplies.contains(comment.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          CommentCard(
            comment: comment,
            onLike: () => _likeComment(comment),
            onReply: () => _replyToComment(comment),
          ),

          // Toggle replies button (if there are replies)
          if (hasReplies)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: GestureDetector(
                onTap: () => _toggleReplies(comment.id),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColorToken.golden.value,
                    ),
                    4.horizontalSpace,
                    Text(
                      isExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                      style: AppTextStyle.size(12)
                          .medium
                          .withColor(AppColorToken.golden),
                    ),
                  ],
                ),
              ),
            ),

          // Replies (if expanded)
          if (hasReplies && isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show loaded replies
                  ...comment.replies.sublist(0, loadedReplies).map((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CommentCard(
                        comment: reply,
                        isReply: true,
                        onLike: () => _likeComment(reply),
                        onReply: () =>
                            _replyToComment(comment), // Reply to parent comment
                      ),
                    );
                  }).toList(),

                  // Load more replies button
                  if (hasMoreReplies)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: GestureDetector(
                        onTap: isLoadingReplies
                            ? null
                            : () => _loadMoreReplies(comment.id),
                        child: Row(
                          children: [
                            if (isLoadingReplies)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColorToken.golden.value,
                                ),
                              )
                            else
                              Icon(
                                Icons.more_horiz,
                                size: 14,
                                color: AppColorToken.golden.value,
                              ),
                            8.horizontalSpace,
                            Text(
                              isLoadingReplies
                                  ? 'Loading replies...'
                                  : 'View ${comment.replies.length - loadedReplies} more ${comment.replies.length - loadedReplies == 1 ? 'reply' : 'replies'}',
                              style: AppTextStyle.size(12)
                                  .medium
                                  .withColor(AppColorToken.golden),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
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

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              )
            : TextButton(
                onPressed: _loadMoreComments,
                child: Text(
                  'Load more comments',
                  style: AppTextStyle.size(14)
                      .medium
                      .withColor(AppColorToken.golden),
                ),
              ),
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
    int total = _allComments.length;
    for (var comment in _allComments) {
      total += comment.replies.length;
    }
    return total;
  }
}
