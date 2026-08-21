class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName: json['profiles']?['display_name'] ?? json['profiles']?['username'] ?? 'Anonymous',
      authorAvatarUrl: json['profiles']?['avatar_url'],
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
