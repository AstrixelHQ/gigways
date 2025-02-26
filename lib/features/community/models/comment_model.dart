class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime timestamp;
  final int likesCount;
  final bool isLiked;
  final String? parentId; // null for top-level comments, non-null for replies
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.timestamp,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentId,
    this.replies = const [],
  });

  // Create a copy of this comment with modified properties
  CommentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? timestamp,
    int? likesCount,
    bool? isLiked,
    String? parentId,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
    );
  }

  // Add a reply to this comment
  CommentModel addReply(CommentModel reply) {
    List<CommentModel> newReplies = List.from(replies);
    newReplies.add(reply);
    return copyWith(replies: newReplies);
  }
}
