class PostModel {
  final String id;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final int likesCount;
  final int commentsCount;
  final DateTime timestamp;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
    this.isLiked = false,
  });

  // Create a copy of this post with modified properties
  PostModel copyWith({
    String? id,
    String? userName,
    String? userAvatarUrl,
    String? content,
    int? likesCount,
    int? commentsCount,
    DateTime? timestamp,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
